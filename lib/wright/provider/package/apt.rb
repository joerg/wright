require 'open3'

require 'wright/dry_run'
require 'wright/provider'
require 'wright/provider/package'

module Wright
  class Provider
    class Package
      # Apt package provider. Used as a provider for
      # {Resource::Package} on Debian-based systems.
      class Apt < Wright::Provider::Package
        # @return [Array<String>] the installed package versions
        def installed_versions
          cmd = "dpkg-query -s #{@resource.name}"
          cmd_stdout, _, cmd_status = Open3.capture3(env, cmd)
          installed_re = /^Status: install ok installed$/

          if cmd_status.success? && installed_re =~ cmd_stdout
            /^Version: (?<version>.*)$/ =~ cmd_stdout
            [version]
          else
            []
          end
        end

        # Installs the package.
        #
        # @return [void]
        def install
          if uptodate?(:install)
            Wright.log.debug "package already installed: '#{@resource.name}'"
            return
          end

          install_package
          @updated = true
        end

        # Removes the package.
        #
        # @return [void]
        def remove
          if uptodate?(:remove)
            Wright.log.debug "package already removed: '#{@resource.name}'"
            return
          end

          remove_package
          @updated = true
        end

        private

        def install_package
          package = @resource.name
          if Wright.dry_run?
            Wright.log.info "(would) install package: '#{package}'"
          else
            Wright.log.info "install package: '#{package}'"
            apt_get(:install, package, @resource.version)
          end
        end

        def remove_package
          package = @resource.name
          if Wright.dry_run?
            Wright.log.info "(would) remove package: '#{package}'"
          else
            Wright.log.info "remove package: '#{package}'"
            apt_get(:remove, package)
          end
        end

        def apt_get(action, package, version = nil)
          package_version = version.nil? ? '' : "=#{version}"
          apt_cmd = "apt-get #{action} -qy #{package}#{package_version}"
          _, cmd_stderr, cmd_status = Open3.capture3(env, apt_cmd)
          return if cmd_status.success?

          apt_error = cmd_stderr.chomp
          fail %(cannot #{action} package '#{package}': "#{apt_error}")
        end

        def env
          { 'DEBIAN_FRONTEND' => 'noninteractive' }
        end
      end
    end
  end
end
