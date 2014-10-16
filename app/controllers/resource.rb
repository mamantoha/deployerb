module Deployd
  module Controllers
    module Resource
      extend ActiveSupport::Concern

      DEFAULT_ACTIONS = {
        index:   { method: :get,    type: :collection },
        show:    { method: :get,    type: :member     },
        create:  { method: :post,   type: :collection },
        update:  { method: :put,    type: :member     },
        destroy: { method: :delete, type: :member     },
      }

      included do
        class_eval do
          attr_reader :collection_route, :member_route
          class << self
          end
        end
      end

      module ClassMethods; end

      def initialize(resource_name, resource_keys = [])
        @resource_class = resource_name.classify.constantize
        raise TypeError.new("wrong argument type #{@resource_class.name} (expected MongoMapper::Document)") unless @resource_class.include?(MongoMapper::Document)

        @resource_name = resource_name
        @resource_keys = resource_keys
        @collection_route = "/#{route_key}/?"
        @member_route = "/#{route_key}/:id/?"

        set_content_type(:json)
        require_resource!(resource_name)
      end

      def resource_name
        @resource_name
      end

      def resource_class
        @resource_class
      end

      def resource_keys
        keys = []
        resource_class.keys.each do |_, key|
          if key.name != '_id' and !key.dynamic?
            keys << { name: key.name, type: key.type }
          end
        end

        return keys
      end

      def route_key
        resource_name.pluralize
      end

      def set_content_type(type)
        Deployd::Application.send :before, /^\/#{route_key}(\/)?(.)*/ do
          content_type type
        end
      end

      # return 404 if Deployd::Controlles::%ModelName%sController not found in application
      # TODO try to find better solution to remove routes in real time
      def require_resource!(resource_name)
        Deployd::Application.send :before, /^\/#{route_key}(\/)?(.)*/ do
          class_name = "#{resource_name.singularize.classify.pluralize}Controller"
          unless Deployd::Controllers.constants.include?(class_name.to_sym)
            halt(404, { status: 'error', data: 'Page not found' }.to_json)
          end
        end
      end

      # mounts our default CRUD routes
      # Parameters:
      # actions - the list of actions to expose.
      #           Acceptable actions are: :index, :show, :create, :update, :destroy
      #           Example:
      #             mount_default_actions([:index, :show, :create])
      #           Since :delete wasn't listed, a route for it will not be generated.
      #
      def mount_default_actions(actions)
        raise TypeError.new("wrong argument type #{actions.class.name} (expected Array)") unless actions.is_a?(Array)

        actions.each do |action|
          create_route_for(action)
        end
      end

      def create_route_for(action)
        opts = DEFAULT_ACTIONS[action]
        controller = self
        route = controller.instance_variable_get("@#{opts[:type].to_s}_route")

        Deployd::Application.send opts[:method], route do
          controller.send action, self
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def index(context)
        instance_variable_set(:"@#{resource_name.pluralize}", resource_name.classify.constantize.all)

        if instance_variable_get(:"@#{resource_name.pluralize}").empty?
          { status: 'error', data: "No #{resource_name.pluralize }"}.to_json
        else
          { status: 'ok', data: instance_variable_get(:"@#{resource_name.pluralize}") }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def create(context)
        permitted_params = resource_keys.map{ |k| k[:name] }
        permitted_params = context.params.select { |k, _| permitted_params.include?(k) }

        begin
          instance_variable_set(:"@#{resource_name.pluralize}", resource_name.classify.constantize.create(permitted_params))
          { status: 'ok', data: instance_variable_get(:"@#{resource_name.pluralize}") }.to_json
        rescue Exception => e
          { status: 'error', data: e.message }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def show(context)
        set_resource(context.params[:id])

        if instance_variable_get(:"@#{resource_name}")
          { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
        else
          { status: 'error', data: "No #{resource_name.singularize}" }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def update(context)
        set_resource(context.params[:id])

        begin
          if instance_variable_get(:"@#{resource_name}")
            permitted_params = resource_keys.map{ |k| k[:name] }
            permitted_params = context.params.select { |k, _| permitted_params.include?(k) }

            instance_variable_get(:"@#{resource_name}").set(permitted_params)
            instance_variable_get(:"@#{resource_name}").reload
            { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
          else
            { status: 'error', data: "No #{resource_name.singularize}" }.to_json
          end
        rescue Exception => e
          { status: 'error', data: e.message }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def destroy(context)
        set_resource(context.params[:id])

        begin
          if instance_variable_get(:"@#{resource_name}")
            instance_variable_get(:"@#{resource_name}").destroy
            { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
          else
            { status: 'error', data: "No #{resource_name.singularize}" }.to_json
          end
        rescue Exception => e
          { status: 'error', data: e.message }.to_json
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      # on [:show, :update, :destroy]
      def set_resource(id)
        instance_variable_set(:"@#{resource_name}", resource_name.classify.constantize.find(id))
      end

    end
  end
end
