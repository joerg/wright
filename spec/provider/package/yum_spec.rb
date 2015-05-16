require_relative '../../spec_helper'

require 'wright/provider/package/yum'

describe Wright::Provider::Package::Yum do
  def rpm_q(pkg_name)
    %W(rpm -q #{pkg_name} --qf %{VERSION}-%{RELEASE})
  end

  def package_provider(pkg_name, pkg_version = nil)
    pkg_resource = OpenStruct.new(name: pkg_name, version: pkg_version)
    Wright::Provider::Package::Yum.new(pkg_resource)
  end

  def yum(action, pkg_name, pkg_version = nil)
    options = action == :install ? ['-y'] : []
    version = pkg_version.nil? ? '' : "-#{pkg_version}"
    ['yum', action.to_s, *options, pkg_name + version]
  end

  before :each do
    yum_dir = File.join(File.dirname(__FILE__), 'yum')
    @fake_capture3 = FakeCapture3.new(yum_dir)
  end

  describe '#installed_versions' do
    it 'should return the installed package version via brew info' do
      pkg_name = 'zsh'
      pkg_versions = ['5.0.2-7.el7_1.1']
      pkg_provider = package_provider(pkg_name)
      rpm_q_cmd = rpm_q(pkg_name)

      @fake_capture3.expect(rpm_q_cmd, 'rpm_-q_zsh')
      @fake_capture3.stub do
        pkg_provider.installed_versions.must_equal pkg_versions
      end
    end

    it 'should return an empty array for uninstalled packages' do
      pkg_name = 'httpd'
      pkg_versions = []
      pkg_provider = package_provider(pkg_name)
      rpm_q_cmd = rpm_q(pkg_name)

      @fake_capture3.expect(rpm_q_cmd, 'rpm_-q_httpd')
      @fake_capture3.stub do
        pkg_provider.installed_versions.must_equal pkg_versions
      end
    end
  end

  describe '#install_package' do
    it 'should install packages' do
      pkg_name = 'nano'
      pkg_provider = package_provider(pkg_name)
      yum_install_cmd = yum(:install, pkg_name)

      @fake_capture3.expect(yum_install_cmd)
      @fake_capture3.stub do
        pkg_provider.send(:install_package)
      end
    end

    it 'should install packages with version' do
      pkg_name = 'mc'
      pkg_version = '4.8.7-8.el7'
      pkg_provider = package_provider(pkg_name, pkg_version)
      yum_install_cmd = yum(:install, pkg_name, pkg_version)

      @fake_capture3.expect(yum_install_cmd)
      @fake_capture3.stub do
        pkg_provider.send(:install_package)
      end
    end
  end
end
