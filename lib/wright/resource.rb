require 'wright/config'
require 'wright/util'
require 'wright/logger'
require 'wright/dry_run'

module Wright
  # Public: Resource base class.
  class Resource
    # Public: Initialize a Resource.
    #
    # name - The resource's name.
    def initialize(name = nil)
      @name = name
      @resource_name = Util.class_to_resource_name(self.class).to_sym
      @provider = provider_for_resource
      @action = nil
      @on_update = nil
      @ignore_failure = false
    end

    # Public: Get/Set the name Symbol of the method to be run by run_action.
    attr_accessor :action

    # Public: Get/Set the ignore_failure attribute.
    attr_accessor :ignore_failure

    # Public: Get/Set the resource's name attribute.
    #
    # Examples
    #
    #   foo = Wright::Resource::Symlink.new('/tmp/fstab')
    #   foo.name
    #   # => "/tmp/fstab"
    #
    #   bar = Wright::Resource::Symlink.new
    #   bar.name = '/tmp/passwd'
    #   bar.name
    #   # => "/tmp/passwd"
    attr_accessor :name

    # Public: Returns a compact resource name Symbol.
    #
    # Examples
    #
    #   foo = Wright::Resource::Symlink.new
    #   foo.resource_name
    #   # => :symlink
    attr_reader :resource_name

    # Public: Set an update action for a resource.
    #
    # on_update - The block that is called if the resource is
    #             updated. Has to respond to :call.
    #
    # Returns nothing.
    # Raises ArgumentError if on_update is not callable
    def on_update=(on_update)
      if on_update.respond_to?(:call) || on_update.nil?
        @on_update = on_update
      else
        fail ArgumentError, "#{on_update} is not callable"
      end
    end

    # Public: Run the resource's current action.
    #
    # Examples
    #
    #   fstab = Wright::Resource::Symlink.new('/tmp/fstab')
    #   fstab.action = :remove!
    #   fstab.run_action
    def run_action
      if @action
        bang_action = "#{@action}!".to_sym
        action = respond_to?(bang_action) ? bang_action : @action
        send(action)
      end
    end

    private

    # Public: Mark a code block that might update a resource.
    # 
    # Usually this method is called in the definition of a new
    # resource class in order to mark those methods that should be
    # able to trigger update actions. Runs the current update action
    # if the provider was updated by the block method.
    #
    # Examples
    #
    #   class BalloonAnimal < Wright::Provider
    #     def inflate
    #       puts "It's a giraffe!"
    #       @updated = true
    #     end
    #   end
    #   
    #   class Balloon < Wright::Resource
    #     def inflate
    #       might_update_resource { @provider.inflate }
    #     end
    #   end
    #   Wright::Config[:resources] = { balloon: { provider: 'BalloonAnimal' } }
    #   
    #   balloon = Balloon.new.inflate
    #   # => true
    #
    # Returns true if the provider was updated and false otherwise.
    def might_update_resource #:doc:
      begin
        yield
      rescue => e
        log_error(e)
        raise e unless @ignore_failure
      end
      updated = @provider.updated?
      run_update_action if updated
      updated
    end

    def log_error(exception)
      resource = "#{@resource_name}"
      resource << " '#{@name}'" if @name
      Wright.log.error "#{resource}: #{exception}"
    end

    def run_update_action
      unless @on_update.nil?
        if Wright.dry_run?
          resource = "#{@resource_name} '#{@name}'"
          Wright.log.info "Would trigger update action for #{resource}"
        else
          @on_update.call
        end
      end
    end

    def resource_class
      Util::ActiveSupport.camelize(@resource_name)
    end

    def provider_name
      if Wright::Config.nested_key?(:resources, @resource_name, :provider)
        Wright::Config[:resources][@resource_name][:provider]
      else
        "Wright::Provider::#{resource_class}"
      end
    end

    def provider_for_resource
      klass = Util::ActiveSupport.safe_constantize(provider_name)
      if klass
        klass.new(self)
      else
        warning = "Could not find a provider for resource #{resource_class}"
        Wright.log.warn warning
        nil
      end
    end
  end
end
