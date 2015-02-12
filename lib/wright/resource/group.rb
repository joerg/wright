require 'wright/resource'
require 'wright/dsl'

module Wright
  class Resource
    # Group resource, represents a group.
    #
    # @example
    #   admins = Wright::Resource::Group.new('admins')
    #   admins.members = ['root']
    #   admins.create
    class Group < Wright::Resource
      # @return [Array<String>] the group's intended members
      attr_accessor :members

      # @return [Integer] the group's intended group id
      attr_accessor :gid

      # Initializes a Group.
      #
      # @param name [String] the group's name
      def initialize(name)
        super
        @members = []
        @action = :create
      end

      # Creates or updates the group.
      #
      # @return [Bool] true if the group was updated and false
      #   otherwise
      def create
        might_update_resource do
          @provider.create
        end
      end

      # Removes the group.
      #
      # @return [Bool] true if the group was updated and false
      #   otherwise
      def remove
        might_update_resource do
          @provider.remove
        end
      end
    end
  end
end

Wright::DSL.register_resource(Wright::Resource::Group)
