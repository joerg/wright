require_relative 'spec_helper'

require 'wright/dsl'

describe Wright::DSL do
  before(:each) do
    # duplicate Wright::DSL for testing
    dsl_module = Wright::DSL.dup
    @recipe = Class.new do
      extend dsl_module
    end
    @dsl_module = dsl_module
  end

  it 'should register new resources at runtime' do
    resource_class = Class.new do
      def self.name; 'ResourceKlass'; end
      def initialize(name); end
    end

    @dsl_module.register_resource(resource_class)

    resource_name = Wright::Util.class_to_resource_name(resource_class)
    @recipe.must_respond_to(resource_name)
    resource = @recipe.send(resource_name)
    resource.must_be_instance_of(resource_class)
  end

  it 'should execute the default action for a resource' do
    resource_class = Class.new do
      def self.name; 'Hello'; end
      def initialize(name); @name = name; end
      def run_action; puts "Hello #{@name}"; end
    end
    @dsl_module.register_resource(resource_class)
    resource_name = Wright::Util.class_to_resource_name(resource_class)
    proc { @recipe.send(resource_name, 'world') }.must_output("Hello world\n")
  end

  it 'should call blocks passed to a resource function' do
    resource_class = Class.new do
      def self.name; 'ResourceKlass'; end
      def initialize(name); end
    end
    @dsl_module.register_resource(resource_class)

    resource_name = Wright::Util.class_to_resource_name(resource_class)
    block = proc { |resource| throw resource.class }

    proc { @recipe.send(resource_name, nil, &block) }.must_throw resource_class
  end
end
