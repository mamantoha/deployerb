# frozen_string_literal: true

module Deployd
  class Application < Sinatra::Base
    before(%r{/dashboard/resources/?.*}) do
      # check_mongodb_server
    end

    get '/' do
      redirect '/dashboard/resources'
    end

    get '/tableView' do
      slim :'resources/_table_view', layout: false
    end

    get '/editorView' do
      slim :'resources/_editor_view', layout: false
    end

    namespace '/dashboard' do
      before do
        @resources = settings.config_file[:resources]
      end


      # Fetch all records of a resource
      get '/resources/:resource_name/data' do
        resource_name = params[:resource_name].singularize

        # Find the resource model dynamically
        model_class = Object.const_get(resource_name.classify) rescue nil
        halt 404, { error: "Resource not found" }.to_json unless model_class

        content_type :json
        model_class.all.to_json
      end

      # Fetch a single record
      get '/resources/:resource_name/data/:id' do
        resource_name = params[:resource_name].singularize
        record_id = params[:id]

        # Find the resource model dynamically
        model_class = Object.const_get(resource_name.classify) rescue nil
        halt 404, { error: "Resource not found" }.to_json unless model_class

        record = model_class.where(id: record_id).first
        halt 404, { error: "Record not found" }.to_json unless record

        content_type :json
        record.to_json
      end

      # Create a new record
      post '/resources/:resource_name/data' do
        resource_name = params[:resource_name].singularize
        request_body = request.body.read
        data = JSON.parse(request_body) rescue {}

        # Find the resource model dynamically
        model_class = Object.const_get(resource_name.classify) rescue nil
        halt 404, { error: "Resource not found" }.to_json unless model_class

        record = model_class.create(data)

        content_type :json
        status 201
        record.to_json
      end

      # Update an existing record
      put '/resources/:resource_name/data/:id' do
        resource_name = params[:resource_name].singularize
        record_id = params[:id]
        request_body = request.body.read
        data = JSON.parse(request_body) rescue {}

        # Find the resource model dynamically
        model_class = Object.const_get(resource_name.classify) rescue nil
        halt 404, { error: "Resource not found" }.to_json unless model_class

        record = model_class.where(id: record_id).first
        halt 404, { error: "Record not found" }.to_json unless record

        record.update_attributes(data)

        content_type :json
        status 200
        record.to_json
      end

      # Delete a record
      delete '/resources/:resource_name/data/:id' do
        resource_name = params[:resource_name].singularize
        record_id = params[:id]

        # Find the resource model dynamically
        model_class = Object.const_get(resource_name.classify) rescue nil
        halt 404, { error: "Resource not found" }.to_json unless model_class

        record = model_class.where(id: record_id).first
        halt 404, { error: "Record not found" }.to_json unless record

        record.destroy

        content_type :json
        status 200
        { message: "Record deleted", id: record_id }.to_json
      end


      get '/resources/?' do
        content_type :json
        { resources: @resources }.to_json
      end

      # save new document
      #
      post '/resources' do
        request_body = request.body.read
        data = JSON.parse(request_body) rescue {}

        resource_name = data["name"]&.downcase&.singularize
        halt 400, { error: "Invalid resource name" }.to_json if resource_name.nil? || resource_name.empty?

        # Check if the resource already exists
        if settings.config_file[:resources].any? { |r| r[:name] == resource_name }
          halt 400, { error: "Resource already exists" }.to_json
        end

        # Add new resource
        settings.config_file[:resources] << { name: resource_name, keys: [] }
        File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
          f.write settings.config_file.to_yaml
        end

        status 201
        { message: "Resource created", resource: resource_name }.to_json
      end

      # show resource
      #
      get '/resources/:resource_name' do
        resource_name = params[:resource_name].singularize
        resource = settings.config_file[:resources].find { |r| r[:name] == resource_name }

        if resource
          content_type :json
          resource.to_json
        else
          content_type :json
          halt 404, { error: "Resource not found" }.to_json
        end
      end

      # remove document
      #
      delete '/resources/:resource_name' do
        resource_name = params[:resource_name].singularize

        # Find and remove the resource
        resource = settings.config_file[:resources].find { |r| r[:name] == resource_name }
        halt 404, { error: "Resource not found" }.to_json unless resource

        settings.config_file[:resources].delete(resource)
        File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
          f.write settings.config_file.to_yaml
        end

        { message: "Resource deleted", resource: resource_name }.to_json
      end

      # add new key to document
      #
      post '/resources/:resource_name' do
        resource_name = params[:resource_name].singularize

        request_body = request.body.read
        data = JSON.parse(request_body) rescue {}

        key_name = data["name"]
        key_type = data["type"]

        validations = data["validations"] || []

        errors = validates_key(resource_name, key_name, key_type)
        if errors.empty?
          options = {}

          if @resources&.find { |r| r[:name] == resource_name }
            Deployd::Models.add_key(resource_name, key_name.to_sym, key_type.constantize, options: options, validations: validations)

            @resources.find { |r| r[:name] == resource_name }[:keys] << {
              name: key_name, type: key_type.constantize, options: options, validations: validations
            }

            File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
              f.write settings.config_file.to_yaml
            end

            content_type :json
            status 201
            { message: "Key added", key: key_name }.to_json
          else
            halt 400, { error: "Resource not found" }.to_json
          end
        else
          halt 400, { error: errors.join('; ') }.to_json
        end
      end


      # update key
      #
      put '/resources/:resource_name/:key_name' do
        resource_name = params[:resource_name].singularize
        key_name = params[:key_name]

        request_body = request.body.read
        data = JSON.parse(request_body) rescue {}

        key_type = data["type"]
        validations = data["validations"] || []

        # Find the resource
        resource = @resources.find { |r| r[:name] == resource_name }
        halt 404, { error: "Resource not found" }.to_json unless resource

        # Find the key
        key = resource[:keys].find { |k| k[:name] == key_name }
        halt 404, { error: "Key not found" }.to_json unless key

        # Update key properties
        key[:type] = key_type.constantize
        key[:validations] = validations

        Deployd::Models.update_key(resource_name, key_name.to_sym, validations: validations)

        # Save updated config
        File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
          f.write settings.config_file.to_yaml
        end

        content_type :json
        status 200
        { message: "Key updated successfully", key: key_name }.to_json
      end

      # remove key from document
      #
      # delete '/resource/user/name'
      #
      delete '/resources/:resource_name/:key_name' do
        resource_name = params[:resource_name].singularize
        key_name = params[:key_name]

        # Find the resource
        resource = @resources.find { |r| r[:name] == resource_name }
        halt 404, { error: "Resource not found" }.to_json unless resource

        # Find the key
        key = resource[:keys].find { |k| k[:name] == key_name }
        halt 404, { error: "Key not found" }.to_json unless key

        # Remove the key
        Deployd::Models.remove_key(resource_name, key_name.to_sym)
        resource[:keys].delete_if { |k| k[:name] == key_name }

        # Save updated config
        File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
          f.write settings.config_file.to_yaml
        end

        content_type :json
        status 200
        { message: "Key '#{key_name}' successfully removed.", key: key_name }.to_json
      end


      # Fetch a single key from a resource
      get '/resources/:resource_name/:key_name' do
        resource_name = params[:resource_name].singularize
        key_name = params[:key_name]

        # Find the resource
        resource = @resources.find { |r| r[:name] == resource_name }
        halt 404, { error: "Resource not found" }.to_json unless resource

        # Find the key
        key = resource[:keys].find { |k| k[:name] == key_name }
        halt 404, { error: "Key not found" }.to_json unless key

        # Return key details
        content_type :json
        { name: key[:name], type: key[:type].to_s, validations: key[:validations] || [] }.to_json
      end

    end

    private

    # check if resource_name is in plural form and model exists
    #
    def check_model_availability!(resource_name)
      unless resource_name.singularize != resource_name && Object.const_defined?(resource_name.singularize.classify)
        flash[:warning] = "Resource `#{resource_name}` not found."
        redirect '/dashboard/resources'
      end
    end

    def validates_resource(name)
      errors = []
      # validates :name presence
      if name && !name.empty?
        # validates :name valid
        errors << 'name: allow only latin letters and underscore' unless name.match(/\A[a-zA-Z_]*\z/)

        # validates :name acceptable
        errors << 'name: not acceptable' if name.singularize != name.singularize.pluralize.singularize

        # validates :name uniqueness
        errors << 'name: has already been taken' if Object.const_defined?(name.downcase.singularize.classify)
      else
        errors << "name: can't be blank"
      end

      errors
    end

    def validates_key(resource_name, name, type)
      errors = []
      # validates :name presence
      if name && !name.empty?
        # validates :name valid
        errors << 'name: allow only latin letters and underscore' unless name.match(/\A[a-zA-Z_]*\z/)
        # validates :name uniqueness
        errors << 'name: has already been taken' if resource_name.classify.constantize.fields.include?(name.downcase)
      else
        errors << "name: can't be blank"
      end

      # validates :type acceptable
      errors << 'type: not acceptable' unless Deployd::AVAILABLE_TYPES.map(&:to_s).include?(type)

      errors
    end

    def check_mongodb_server
      Timeout.timeout(5) do
        Mongoid.default_client.database_names
      end
    rescue Timeout::Error
      content_type :html
      halt slim :mongodb_error
    end
  end
end
