require 'fileutils'
require 'wright/provider'
require 'wright/util/file'
require 'wright/util/user'
require 'wright/util/file_permissions'

# Public: Directory provider. Used as a Provider for Resource::Directory.
class Wright::Provider::Directory < Wright::Provider

  # Public: Create or update the directory.
  #
  # Returns nothing.
  def create!
    if ::File.directory?(@resource.name) && permissions.uptodate?

      Wright.log.debug "directory already created: '#{@resource.name}'"
      return
    end

    if ::File.exist?(@resource.name) && !::File.directory?(@resource.name)
      raise Errno::EEXIST, @resource.name
    end
    create_directory
    @updated = true
  end

  # Public: Remove the directory.
  #
  # Returns nothing.
  def remove!
    if ::File.exist?(@resource.name) && !::File.directory?(@resource.name)
      raise RuntimeError, "'#{@resource.name}' exists but is not a directory"
    end

    if ::File.directory?(@resource.name)
      if Wright.dry_run?
        Wright.log.info "(would) remove directory: '#{@resource.name}'"
      else
        Wright.log.info "remove directory: '#{@resource.name}'"
        FileUtils.rmdir(@resource.name)
      end
      @updated = true
    else
      Wright.log.debug "directory already removed: '#{@resource.name}'"
    end
  end

  private

  def permissions
    # TODO: maybe add a create_from_resource class function
    permissions = Wright::Util::FilePermissions.new(@resource.name, :directory)
    permissions.owner = @resource.owner
    permissions.group = @resource.group
    permissions.mode = @resource.mode
    permissions
  end

  def create_directory
    dirname = @resource.name

    if Wright.dry_run?
      Wright.log.info "(would) create directory: '#{dirname}'"
    else
      Wright.log.info "create directory: '#{dirname}'"
      FileUtils.mkdir_p(dirname)
      permissions.update
    end
  end
end
