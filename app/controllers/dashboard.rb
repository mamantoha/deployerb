module Deployd
  class Application < Sinatra::Base
    subdomain '' do
      before /^\/dashboard\/resources\/?.*/  do
        check_mongodb_server
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

        get '/resources/?' do
          slim :'resources/index'
        end

        # create new document
        #
        get '/resources/new' do
          slim :'resources/new', layout: false
        end

        # save new document
        #
        post '/resources' do
          errors = validates_resource(params[:name])
          if errors.empty?
            resource_name = params[:name].downcase.singularize

            Deployd::Models.new(resource_name)
            Deployd::Controllers.new(resource_name)

            @resources << { name: resource_name, keys: [] }
            File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
              f.write settings.config_file.to_yaml
            end

            flash[:info] = 'New document successfully added.'
            redirect "/dashboard/resources/#{resource_name.pluralize}"
          else
            flash[:danger] = errors.join('; ')
            redirect '/dashboard/resources'
          end
        end

        # show resource
        #
        get '/resources/:resource_name' do
          check_model_availability!(params[:resource_name])
          @resource_name = params[:resource_name].singularize
          @route_key = @resource_name.pluralize

          if @resources && @resources.find { |r| r[:name] == @resource_name }
            @resource = @resource_name.classify.constantize
            @defined_keys = @resource.fields.map{ |k| { name: k[1].name, type: k[1].type.to_s } }.reject { |k| k[:name] == '_id' }
            slim :'/resources/show'
          else
            redirect '/dashboard/resources'
          end
        end

        # remove document
        #
        delete '/resources/:resource_name' do
          check_model_availability!(params[:resource_name])
          resource_name = params[:resource_name].singularize

          if @resources && @resources.find { |r| r[:name] == resource_name }
            Deployd::Models.remove(resource_name)
            Deployd::Controllers.remove(resource_name)

            @resources.delete_if { |r| r[:name] == resource_name }
            File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
              f.write settings.config_file.to_yaml
            end
            flash[:info] = 'Document successfully removed.'
            redirect '/dashboard/resources'
          else
            redirect '/dashboard/resources'
          end
        end

        # add new key to document
        #
        # Example of params:
        # { "type"=>"String", "name"=>"firstname", "validations"=>{"presence"=>"on"}, "splat"=>[], "captures"=>["people"], "resource_name"=>"people" }
        #
        post '/resources/:resource_name' do
          check_model_availability!(params[:resource_name])
          resource_name = params[:resource_name].singularize
          key_name = params[:name]
          key_type = params[:type]

          validations = []
          if params[:validations]
            Deployd::Models::AVAILABLE_VALIDATIONS.each do |validation|
              validations << validation if params[:validations][validation]
            end
          end

          errors = validates_key(resource_name, key_name, key_type)
          if errors.empty?
            options = {}

            if @resources && @resources.find { |r| r[:name] == resource_name }
              Deployd::Models.add_key(resource_name, key_name.to_sym, key_type.constantize, options: options, validations: validations)

              @resources.find { |r| r[:name] == resource_name }[:keys] << { name: key_name, type: key_type.constantize, options: options, validations: validations }
              File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
                f.write settings.config_file.to_yaml
              end

              @resource = resource_name.classify.constantize
              flash[:info] = 'New key successfully added.'
              redirect "/dashboard/resources/#{resource_name.pluralize}"
            else
              redirect '/dashboard/resources'
            end
          else
            flash[:danger] = errors.join('; ')
            redirect "/dashboard/resources/#{resource_name.pluralize}"
          end
        end

        # edit key
        #
        put '/resources/:resource_name/:key_name' do
          check_model_availability!(params[:resource_name])
          resource_name = params[:resource_name].singularize
          key_name = params[:key_name]
          key_type = params[:type]

          validations = []
          if params[:validations]
            Deployd::Models::AVAILABLE_VALIDATIONS.each do |validation|
              validations << validation if params[:validations][validation]
            end
          end

          options = {}

          if @resources && @resources.find { |r| r[:name] == resource_name }
            # change type and/or options/validations, remove key and add new
            Deployd::Models.remove_key(resource_name, key_name.to_sym)
            Deployd::Models.add_key(resource_name, key_name.to_sym, key_type.constantize, options: options, validations: validations)

            @resources.map { |r| r[:keys].delete_if { |k| k[:name] == key_name } if r[:name] == resource_name }
            @resources.find { |r| r[:name] == resource_name }[:keys] << { name: key_name, type: key_type.constantize, options: options, validations: validations }

            File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
              f.write settings.config_file.to_yaml
            end
            @resource = resource_name.classify.constantize

            flash[:info] = 'Key successfully changed.'
            redirect "/dashboard/resources/#{resource_name.pluralize}"
          end
        end


        # remove key from document
        #
        # delete '/resource/user/name'
        #
        delete '/resources/:resource_name/:key_name' do
          check_model_availability!(params[:resource_name])
          resource_name = params[:resource_name].singularize
          key_name = params[:key_name]

          if @resources && @resources.find { |r| r[:name] == resource_name }
            Deployd::Models.remove_key(resource_name, key_name.to_sym)

            @resources.map { |r| r[:keys].delete_if { |k| k[:name] == key_name } if r[:name] == resource_name }
            File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
              f.write settings.config_file.to_yaml
            end
            @resource = resource_name.classify.constantize

            flash[:info] = 'Key successfully removed.'
            redirect "/dashboard/resources/#{resource_name.pluralize}"
          end
        end

        # show key
        #
        # get '/resource/user/name'
        #
        get '/resources/:resource_name/:key_name' do
          check_model_availability!(params[:resource_name])
          @resource_name = params[:resource_name].singularize
          @key_name = params[:key_name]

          if @resources && @resources.find { |r| r[:name] == @resource_name }
            @resource = @resource_name.classify.constantize
            @key = @resource.fields.select { |k| k[@key_name] }[@key_name]
          end

          if @key
            slim :'resources/keys/show'
          else
            flash[:warning] = "Key `#{@key_name}` not found."
            redirect "/dashboard/resources/#{@resource_name.pluralize}"
          end
        end

      end # namespace '/dashboard'
    end # subdomain

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
        if !name.match(/\A[a-zA-Z_]*\z/)
            errors << 'name: allow only latin letters and underscore'
        end

        # validates :name acceptable
        if name.singularize != name.singularize.pluralize.singularize
          errors << 'name: not acceptable'
        end

        # validates :name uniqueness
        if Object.const_defined?(name.downcase.singularize.classify)
          errors << 'name: has already been taken'
        end
      else
        errors << "name: can't be blank"
      end

      return errors
    end

    def validates_key(resource_name, name, type)
      errors = []
      # validates :name presence
      if name && !name.empty?
        # validates :name valid
        if !name.match(/\A[a-zA-Z_]*\z/)
          errors << 'name: allow only latin letters and underscore'
        end
        # validates :name uniqueness
        if resource_name.classify.constantize.fields.include?(name.downcase)
          errors << 'name: has already been taken'
        end
      else
        errors << "name: can't be blank"
      end

      # validates :type acceptable
      unless Deployd::Models::AVAILABLE_TYPES.map(&:to_s).include?(type)
        errors << 'type: not acceptable'
      end

      return errors
    end

    def check_mongodb_server
      Timeout.timeout(5) do
        Mongoid.default_client.database_names
      end
    rescue Timeout::Error
      content_type :html
      halt slim :mongodb_error
    end
  end # class Application < Sinatra::Base
end # module Deployd
