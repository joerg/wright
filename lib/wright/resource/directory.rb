require 'wright/resource'
require 'wright/dsl'

# Public: Directory resource, represents a directory.
#
# Examples
#
#   dir = Wright::Resource::Directory.new('/tmp/foobar')
#   dir.create!
class Wright::Resource::Directory < Wright::Resource

  # Public: Initialize a Directory.
  #
  # name - The directory's name.
  def initialize(name)
    super
    @mode = nil
    @owner = nil
    @group = nil
    @action = :create
  end

  # Public: Get/Set the directory's mode.
  attr_accessor :mode

  # Public: Get the directory's owner.
  attr_reader :owner

  # REFACTOR: move this to some kind of utility function
  # Public: Set the directory's owner.
  def owner=(owner)
    if owner.is_a?(String)
      raise ArgumentError, "Invalid owner: '#{owner}'" if owner.count(':') > 1
      owner, group = owner.split(':')
      @group = Wright::Util::User.group_to_gid(group) unless group.nil?
    end
    @owner = Wright::Util::User.user_to_uid(owner)
  end

  # Public: Get the directory's group.
  attr_reader :group

  # Public: Set the directory's group
  def group=(group)
    @group = Wright::Util::User.group_to_gid(group)
  end

  # Public: Create or update the directory.
  #
  # Returns true if the directory was updated and false otherwise.
  def create!
    might_update_resource do
      @provider.create!
    end
  end

  # Public: Remove the directory.
  #
  # Returns true if the directory was updated and false otherwise.
  def remove!
    might_update_resource do
      @provider.remove!
    end
  end
end

Wright::DSL.register_resource(Wright::Resource::Directory)
