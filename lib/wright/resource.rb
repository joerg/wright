require 'wright/config'
require 'wright/util'
require 'wright/logger'
require 'wright/dry_run'

module Wright
  class Resource
    def initialize(name)
      @name = name
      @resource_name = Util.class_to_resource_name(self.class).to_sym
      @provider = provider_for_resource
      @action = nil
      @on_update = nil
    end

    attr_accessor :action
    attr_reader :name, :resource_name, :on_update

    def on_update=(on_update)
      if on_update.respond_to?(:call) || on_update.nil?
        @on_update = on_update
      else
        raise ArgumentError.new("#{on_update} is not callable")
      end
    end

    def run_action
      if @action
        bang_action = "#{@action}!".to_sym
        action = respond_to?(bang_action) ? bang_action : @action
        send(action)
      end
    end

    def maybe_destructive
      yield
      run_update_action_if_updated
    end

    private
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

    def run_update_action_if_updated
      if @provider.respond_to?(:updated?)
        run_update_action if @provider.updated?
      else
        if @on_update
          warning = "Provider #{@provider.class.name} does not support updates"
          Wright.log.warn warning
        end
      end
    end

    def resource_class
      Util::ActiveSupport.camelize(@resource_name)
    end

    def provider_name
      if Wright::Config.has_nested_key?(:resources, @resource_name, :provider)
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
