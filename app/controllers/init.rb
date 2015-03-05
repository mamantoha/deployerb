require_relative 'resource'
require_relative 'base'
require_relative 'dashboard'

module Deployd
  module Controllers
    # keep a list of generated classes in a class variable
    class << self; attr_reader :generated_classes; end
    @generated_classes = []

    # params:
    #   resource_name - Sting
    #
    def self.new(resource_name)
      class_name = "#{resource_name.classify.pluralize}Controller"
      @generated_classes << klass = Deployd::Controllers.const_set(class_name, Class.new(Base))

      klass.module_eval do
        def mount_actions
          mount_default_actions [:index, :create, :show, :update, :destroy]
        end
      end

      instance_variable_set(:"@#{resource_name.pluralize}_controller", "Deployd::Controllers::#{resource_name.classify.pluralize}Controller".constantize.new(resource_name))
      instance_variable_get(:"@#{resource_name.pluralize}_controller").mount_actions
    end

    # params:
    #   resource_name - String
    #
    def self.remove(resource_name)
      class_name = "#{resource_name.classify.pluralize}Controller"
      klass = "Deployd::Controllers::#{class_name}".constantize
      @generated_classes.delete(klass)
      if Deployd::Controllers.constants.include?(class_name.to_sym)
        Deployd::Controllers.send(:remove_const, class_name.to_sym)
      end
    end

    def self.initialize_from_config_file!
      # read resources from config file
      resources = Deployd::Application.settings.config_file[:resources]

      # create classes for resources
      resources.each do |resource|
        Deployd::Controllers.new(resource[:name])
      end
    end
  end
end

Deployd::Controllers.initialize_from_config_file!
