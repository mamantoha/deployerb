module Deployd
  module Controllers
    module Resource
      extend ActiveSupport::Concern

      attr_reader :resource_name, :resource_class

      DEFAULT_ACTIONS = {
        index:   { method: :get,    type: :collection },
        show:    { method: :get,    type: :member     },
        create:  { method: :post,   type: :collection },
        update:  { method: :put,    type: :member     },
        destroy: { method: :delete, type: :member     }
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
        fail TypeError, "wrong argument type #{@resource_class.name} (expected MongoMapper::Document)" unless @resource_class.include?(MongoMapper::Document)

        @resource_name = resource_name
        @resource_keys = resource_keys
        @collection_route = "/#{route_key}/?"
        @member_route = "/#{route_key}/:id/?"

        set_content_type(:json)
        set_access_control_header
        require_resource!(resource_name)
      end

      def resource_keys
        keys = []
        resource_class.keys.each do |_, key|
          if key.name != '_id' && !key.dynamic?
            keys << { name: key.name, type: key.type }
          end
        end

        return keys
      end

      def route_key
        resource_name.pluralize
      end

      def set_content_type(type)
        Deployd::Application.send :before, %r{^/#{route_key}(/)?(.)*} do
          content_type type
        end
      end

      def set_access_control_header
        Deployd::Application.send :before, %r{^/#{route_key}(/)?(.)*} do
          allow_headers = ["*", "Content-Type", "Accept", "AUTHORIZATION", "Cache-Control"]
          allow_methods = [:post, :get, :option, :delete, :put]
          headers_list = {
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => allow_methods.map { |m| m.to_s.upcase! }.join(', '),
            'Access-Control-Allow-Headers' => allow_headers.map(&:to_s).join(', ')
          }
          headers headers_list
        end
      end

      # return 404 if Deployd::Controlles::%ModelName%sController not found in application
      # TODO try to find better solution to remove routes in real time
      #
      def require_resource!(resource_name)
        Deployd::Application.send :before, %r{^/#{route_key}(/)?(.)*} do
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
        fail TypeError, "wrong argument type #{actions.class.name} (expected Array)" unless actions.is_a?(Array)

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
      def index(_context)
        instance_variable_set(:"@#{resource_name.pluralize}", resource_name.classify.constantize.all)

        if instance_variable_get(:"@#{resource_name.pluralize}").empty?
          { status: 'error', data: "No #{resource_name.pluralize }" }.to_json
        else
          # { status: 'ok', data: instance_variable_get(:"@#{resource_name.pluralize}") }.to_json
          # FIXME Expected response should contain an array except an object ?
          instance_variable_get(:"@#{resource_name.pluralize}").to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def show(context)
        set_resource(context.params[:id])

        if instance_variable_get(:"@#{resource_name}")
          # { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
          instance_variable_get(:"@#{resource_name}").to_json
        else
          { status: 'error', data: "No #{resource_name.singularize}" }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def create(context)
        # TODO parse JSON request body
        context.request.body.rewind  # in case someone already read it
        data = JSON.parse context.request.body.read

        permitted_params = resource_keys.map { |k| k[:name] }
        # permitted_params = context.params.select { |k, _| permitted_params.include?(k) }
        permitted_params = data.select { |k, _| permitted_params.include?(k) }

        begin
          instance_variable_set(:"@#{resource_name}", resource_name.classify.constantize.new(permitted_params))
          if instance_variable_get(:"@#{resource_name}").save
            # { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
            instance_variable_get(:"@#{resource_name}").to_json
          else
            errors = instance_variable_get(:"@#{resource_name}").errors.map { |k, v| "#{k}: #{v}" }.join('; ')
            { status: 'error', data: errors }.to_json
          end
        rescue StandardError => e
          { status: 'error', data: e.message }.to_json
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def update(context)
        # TODO parse JSON request body
        context.request.body.rewind  # in case someone already read it
        data = JSON.parse context.request.body.read

        set_resource(context.params[:id])

        begin
          if instance_variable_get(:"@#{resource_name}")
            permitted_params = resource_keys.map { |k| k[:name] }
            # permitted_params = context.params.select { |k, _| permitted_params.include?(k) }
            permitted_params = data.select { |k, _| permitted_params.include?(k) }

            if instance_variable_get(:"@#{resource_name}").update_attributes(permitted_params)
              instance_variable_get(:"@#{resource_name}").reload
              # { status: 'ok', data: instance_variable_get(:"@#{resource_name}") }.to_json
              instance_variable_get(:"@#{resource_name}").to_json
            else
              errors = instance_variable_get(:"@#{resource_name}").errors.map { |k, v| "#{k}: #{v}" }.join('; ')
              { status: 'error', data: errors }.to_json
            end
          else
            { status: 'error', data: "No #{resource_name.singularize}" }.to_json
          end
        rescue StandardError => e
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
        rescue StandardError => e
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
