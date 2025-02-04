# frozen_string_literal: true

module Deployd
  module Controllers
    module Resource
      extend ActiveSupport::Concern

      attr_reader :resource_name

      DEFAULT_ACTIONS = {
        index: { method: :get, type: :collection },
        show: { method: :get, type: :member },
        create: { method: :post,   type: :collection },
        update: { method: :put,    type: :member     },
        destroy: { method: :delete, type: :member }
      }.freeze

      MAX_LIMIT     = 100
      DEFAULT_LIMIT = 5

      included do
        class_eval do
          attr_reader :collection_route, :member_route

          class << self
          end
        end
      end

      module ClassMethods; end

      def initialize(resource_name)
        resource_class = resource_name.classify.constantize
        unless resource_class.include?(Mongoid::Document)
          raise TypeError, "wrong argument type #{resource_class.name} (expected Mongoid::Document)"
        end

        @resource_name = resource_name
        @collection_route = "/#{route_key}/?"
        @member_route = "/#{route_key}/:id/?"

        set_content_type(:json)
        set_access_control_header
        require_resource!(resource_name)
      end

      def resource_fields
        fields = []
        resource_name.classify.constantize.fields.each do |_, field|
          fields << { name: field.name, type: field.type } if field.name != '_id'
        end

        fields
      end

      def route_key
        resource_name.pluralize
      end

      def set_content_type(type)
        Deployd::Application.send :before, %r{/#{route_key}(/)?(.)*} do
          content_type type
        end
      end

      def set_access_control_header
        Deployd::Application.send :before, %r{/#{route_key}(/)?(.)*} do
          allow_headers = ['*', 'Content-Type', 'Accept', 'AUTHORIZATION', 'Cache-Control']
          allow_methods = %i[post get option delete put]
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
        Deployd::Application.send :before, %r{/#{route_key}(/)?(.)*} do
          class_name = "#{resource_name.singularize.classify.pluralize}Controller"

          unless Deployd::Controllers.constants.include?(class_name.to_sym)
            content_type :json
            halt(404, { status: 'error', message: 'The URI requested is invalid' }.to_json)
          end
        end
      end

      # mounts our default CRUD routes
      # Parameters:
      # actions - the list of actions to expose.
      #           Acceptable actions are: :index, :create, :show, :update, :destroy
      #           Example:
      #             mount_default_actions([:index, :create, :show, :update])
      #           Since :delete wasn't listed, a route for it will not be generated.
      #
      def mount_default_actions(actions)
        raise TypeError, "wrong argument type #{actions.class.name} (expected Array)" unless actions.is_a?(Array)

        actions.each do |action|
          create_route_for(action)
        end
      end

      def create_route_for(action)
        opts = DEFAULT_ACTIONS[action]
        controller = self
        route = controller.instance_variable_get("@#{opts[:type]}_route")

        # Deployd::Application.send :subdomain, :api do
          Deployd::Application.send opts[:method], route do
            controller.send action, self
          end
        # end
      end

      def index(context)
        instance_variable_set(:"@#{resource_name.pluralize}", resource_name.classify.constantize.all)

        page = (context.params[:page] || 1).to_i
        limit = [(context.params[:limit] || DEFAULT_LIMIT).to_i, MAX_LIMIT].min
        offset = (page - 1) * limit

        data = instance_variable_get(:"@#{resource_name.pluralize}").skip(offset).limit(limit)

        total = instance_variable_get(:"@#{resource_name.pluralize}").count
        total_pages = (total.to_f / limit).ceil

        meta = { total:, page:, limit:, total_pages: }

        { data:, meta: }.to_json
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def create(context)
        begin
          params = JSON.parse(context.request.body.read)
        rescue JSON::ParserError
          context.halt(406, { status: 'error', message: 'Not acceptable JSON payload' }.to_json)
        end

        permitted_params = resource_fields.map { |k| k[:name] }
        permitted_params = params.select { |k, _| permitted_params.include?(k) }

        begin
          instance_variable_set(:"@#{resource_name}", resource_name.classify.constantize.new(permitted_params))

          if instance_variable_get(:"@#{resource_name}").save
            data = instance_variable_get(:"@#{resource_name}")

            { data: }.to_json
          else
            errors = instance_variable_get(:"@#{resource_name}").errors.messages
            context.halt(406, { status: 'error', message: errors }.to_json)
          end
        rescue StandardError => e
          context.halt(500, { status: 'error', message: e.message }.to_json)
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def show(context)
        set_resource(context)

        data = instance_variable_get(:"@#{resource_name}")

        { data: }.to_json
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def update(context)
        begin
          params = JSON.parse(context.request.body.read)
        rescue JSON::ParserError
          context.halt(406, { status: 'error', message: 'Not acceptable JSON payload' }.to_json)
        end

        set_resource(context)

        begin
          permitted_params = resource_fields.map { |k| k[:name] }
          permitted_params = params.select { |k, _| permitted_params.include?(k) }

          if instance_variable_get(:"@#{resource_name}").update_attributes(permitted_params)
            instance_variable_get(:"@#{resource_name}").reload
            data = instance_variable_get(:"@#{resource_name}")

            { data: }.to_json
          else
            errors = instance_variable_get(:"@#{resource_name}").errors.messages
            context.halt(406, { status: 'error', message: errors }.to_json)
          end
        rescue StandardError => e
          context.halt(500, { status: 'error', message: e.message }.to_json)
        end
      end

      # params:
      #   context - the instance (not the class of Deployd::Application for this controller)
      #
      def destroy(context)
        set_resource(context)

        begin
          instance_variable_get(:"@#{resource_name}").destroy

          context.halt(204)
        rescue StandardError => e
          context.halt(500, { status: 'error', message: e.message }.to_json)
        end
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      # on [:show, :update, :destroy]
      #
      def set_resource(context)
        instance_variable_set(:"@#{resource_name}", resource_name.classify.constantize.find(context.params[:id]))

        unless instance_variable_get(:"@#{resource_name}")
          context.halt(404, { status: 'error', message: "No #{resource_name.singularize}" }.to_json)
        end
      end
    end
  end
end
