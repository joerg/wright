require_relative '../../spec_helper'

require 'wright/provider/group/gnu_passwd'
require 'fakeetc'

describe Wright::Provider::Group::GnuPasswd do
  def groupadd(group_name, gid = nil, system = false)
    options = []
    options << '--system' if system
    options += ['-g', gid.to_s] if gid
    ['groupadd', *options, group_name]
  end

  def gpasswd(group_name, members)
    ['gpasswd', '-M', "'#{members.join(',')}'", group_name]
  end

  def groupmod(group_name, gid)
    ['groupmod', '-g', gid.to_s, group_name]
  end

  def groupdel(group_name)
    ['groupdel', group_name]
  end

  def group_provider(group_name, gid = nil, members = nil, system = false)
    group_resource = OpenStruct.new(name: group_name,
                                    gid: gid,
                                    members: members,
                                    system: system)
    Wright::Provider::Group::GnuPasswd.new(group_resource)
  end

  before :each do
    gnu_passwd_dir = File.join(File.dirname(__FILE__), 'gnu_passwd')
    @fake_capture3 = FakeCapture3.new(gnu_passwd_dir)
    @create_message = ->(group) { "INFO: create group: '#{group}'\n" }
    @create_message_dry = lambda do |group|
      "INFO: (would) create group: '#{group}'\n"
    end
    @create_message_debug = lambda do |group|
      "DEBUG: group already created: '#{group}'\n"
    end
    @remove_message = ->(group) { "INFO: remove group: '#{group}'\n" }
    @remove_message_dry = lambda do |group|
      "INFO: (would) remove group: '#{group}'\n"
    end
    @remove_message_debug = lambda do |group|
      "DEBUG: group already removed: '#{group}'\n"
    end
    @groups = { 'foobar' => { gid: 42, mem: %w(foo bar) },
                'bazqux' => { gid: 43, mem: %w(baz qux) } }
    FakeEtc.add_groups(@groups)
  end

  describe '#create' do
    it 'should create new groups' do
      gid = 1234
      group_name = 'newgroup'
      group_provider = group_provider(group_name, gid)
      groupadd_cmd = groupadd(group_name, gid)

      @fake_capture3.expect(groupadd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal true
          end.must_output @create_message.call(group_name)
        end
      end
    end

    it 'should create new system groups' do
      group_name = 'newgroup'
      gid = nil
      members = nil
      system = true
      group_provider = group_provider(group_name, gid, members, system)
      groupadd_cmd = groupadd(group_name, gid, system)

      @fake_capture3.expect(groupadd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal true
          end.must_output @create_message.call(group_name)
        end
      end
    end

    it 'should not try to create existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid]
      members = @groups[group_name][:mem]
      group_provider = group_provider(group_name, gid, members)

      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal false
          end.must_output @create_message_debug.call(group_name)
        end
      end
    end

    it 'should clear member lists for existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid]
      members = []
      group_provider = group_provider(group_name, gid, members)
      gpasswd_cmd = gpasswd(group_name, members)

      @fake_capture3.expect(gpasswd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal true
          end.must_output @create_message.call(group_name)
        end
      end
    end

    it 'should update member lists for existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid]
      members = %w(user1 user2)
      group_provider = group_provider(group_name, gid, members)
      gpasswd_cmd = gpasswd(group_name, members)

      @fake_capture3.expect(gpasswd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal true
          end.must_output @create_message.call(group_name)
        end
      end
    end

    it 'should update the gid for existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid] + 10
      group_provider = group_provider(group_name, gid)
      groupmod_cmd = groupmod(group_name, gid)

      @fake_capture3.expect(groupmod_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.create
            group_provider.updated?.must_equal true
          end.must_output @create_message.call(group_name)
        end
      end
    end

    it 'should report errors by groupadd' do
      gid = 'ERROR'
      group_name = 'newgroup'
      group_provider = group_provider(group_name, gid)
      groupadd_cmd = groupadd(group_name, gid)

      @fake_capture3.expect(groupadd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          e = -> { group_provider.create }.must_raise RuntimeError
          wright_error = "cannot create group '#{group_name}'"
          groupadd_error = "groupadd: invalid group ID '#{gid}'"
          e.message.must_equal %(#{wright_error}: "#{groupadd_error}")
        end
      end
    end

    it 'should report errors by groupmod' do
      gid = 'ERROR'
      group_name = 'foobar'
      group_provider = group_provider(group_name, gid)
      groupmod_cmd = groupmod(group_name, gid)

      @fake_capture3.expect(groupmod_cmd)
      @fake_capture3.stub do
        FakeEtc do
          e = -> { group_provider.create }.must_raise RuntimeError
          wright_error = "cannot create group '#{group_name}'"
          groupmod_error = "groupmod: invalid group ID '#{gid}'"
          e.message.must_equal %(#{wright_error}: "#{groupmod_error}")
        end
      end
    end

    it 'should report errors by gpasswd' do
      user = 'not-a-user'
      members = [user]
      group_name = 'foobar'
      group_provider = group_provider(group_name, nil, members)
      gpasswd_cmd = gpasswd(group_name, members)

      @fake_capture3.expect(gpasswd_cmd)
      @fake_capture3.stub do
        FakeEtc do
          e = -> { group_provider.create }.must_raise RuntimeError
          wright_error = "cannot create group '#{group_name}'"
          gpasswd_error = "gpasswd: user '#{user}' does not exist"
          e.message.must_equal %(#{wright_error}: "#{gpasswd_error}")
        end
      end
    end
  end

  describe '#remove' do
    it 'should remove existing groups' do
      group_name = 'foobar'
      group_provider = group_provider(group_name)
      groupdel_cmd = groupdel(group_name)

      @fake_capture3.expect(groupdel_cmd)
      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.remove
            group_provider.updated?.must_equal true
          end.must_output @remove_message.call(group_name)
        end
      end
    end

    it 'should not try to remove groups that are already removed' do
      group_name = 'not-a-group'
      group_provider = group_provider(group_name)

      @fake_capture3.stub do
        FakeEtc do
          lambda do
            reset_logger
            group_provider.remove
            group_provider.updated?.must_equal false
          end.must_output @remove_message_debug.call(group_name)
        end
      end
    end

    it 'should report errors by gpasswd' do
      group_name = 'bazqux'
      group_provider = group_provider(group_name)
      groupdel_cmd = groupdel(group_name)

      @fake_capture3.expect(groupdel_cmd)
      @fake_capture3.stub do
        FakeEtc do
          e = -> { group_provider.remove }.must_raise RuntimeError
          wright_error = "cannot remove group '#{group_name}'"
          groupdel_error =
            "groupdel: cannot remove the primary group of user 'quux'"
          e.message.must_equal %(#{wright_error}: "#{groupdel_error}")
        end
      end
    end
  end

  describe 'dry_run' do
    it 'should not actually create new groups' do
      gid = 1234
      group_name = 'newgroup'
      group_provider = group_provider(group_name, gid)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.create
              group_provider.updated?.must_equal true
            end.must_output @create_message_dry.call(group_name)
          end
        end
      end
    end

    it 'should not actually update existing groups' do
      gid = 1234
      group_name = 'foobar'
      members = %w(user1 user2)
      group_provider = group_provider(group_name, gid, members)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.create
              group_provider.updated?.must_equal true
            end.must_output @create_message_dry.call(group_name)
          end
        end
      end
    end

    it 'should not try to create existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid]
      members = @groups[group_name][:mem]
      group_provider = group_provider(group_name, gid, members)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.create
              group_provider.updated?.must_equal false
            end.must_output @create_message_debug.call(group_name)
          end
        end
      end
    end

    it 'should not actually update existing groups' do
      group_name = 'foobar'
      gid = @groups[group_name][:gid] + 10
      members = %w(user1 user2)
      group_provider = group_provider(group_name, gid, members)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.create
              group_provider.updated?.must_equal true
            end.must_output @create_message_dry.call(group_name)
          end
        end
      end
    end

    it 'should not actually remove groups' do
      group_name = 'foobar'
      group_provider = group_provider(group_name)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.remove
              group_provider.updated?.must_equal true
            end.must_output @remove_message_dry.call(group_name)
          end
        end
      end
    end

    it 'should not try to remove groups that are already removed' do
      group_name = 'not-a-group'
      group_provider = group_provider(group_name)

      @fake_capture3.stub do
        Wright.dry_run do
          FakeEtc do
            lambda do
              reset_logger
              group_provider.remove
              group_provider.updated?.must_equal false
            end.must_output @remove_message_debug.call(group_name)
          end
        end
      end
    end
  end
end
