module Deployd
  class Application < Sinatra::Base
    get '/' do
      redirect '/dashboard/resources'
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
        # validates :name presence
        if params[:name] && !params[:name].empty?
          resource_name = params[:name].downcase.singularize

          # validates :name uniqueness
          if Object.const_defined?(params[:name].classify)
            flash[:danger] = 'name: has already been taken.'
            redirect '/dashboard/resources'
          end

          Deployd::Models.new(resource_name)
          Deployd::Controllers.new(resource_name)

          @resources << { name: resource_name, keys: [] }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end

          flash[:info] = 'New document successfully added.'
          redirect '/dashboard/resources'
        else
          flash[:danger] = "name: can't be blank."
          redirect '/dashboard/resources'
        end
      end

      # show resource
      #
      get '/resources/:resource_name' do
        @resource_name = params[:resource_name]
        @route_key = @resource_name.pluralize

        if @resources && @resources.find { |r| r[:name] == @resource_name }
          @resource = @resource_name.classify.constantize
          slim :'/resources/show'
        else
          redirect '/dashboard/resources'
        end
      end

      # remove document
      #
      delete '/resources/:resource_name' do
        resource_name = params[:resource_name]

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
      post '/resources/:resource_name' do
        resource_name = params[:resource_name]
        key_name = params[:name].downcase
        key_type = params[:type]
        # Deployd::Models::AVAILABLE_KEYS.include?(key_type)

        # MongoMapper validations
        required = params[:required] ? true : false
        unique = params[:unique] ? true : false
        options = { required: required, unique: unique }

        if @resources && @resources.find { |r| r[:name] == resource_name }
          Deployd::Models.add_key(resource_name, key_name.to_sym, key_type.constantize, options)

          @resources.find { |r| r[:name] == resource_name }[:keys] << { name: key_name, type: key_type.constantize, options: options }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end

          @resource = resource_name.classify.constantize
          flash[:info] = 'New key successfully added.'
          redirect "/dashboard/resources/#{resource_name}"
        else
          redirect '/dashboard/resources'
        end
      end

      # remove key from document
      #
      # delete '/resource/user/name'
      #
      delete '/resources/:resource_name/:key_name' do
        resource_name = params[:resource_name]
        key_name = params[:key_name]

        if @resources && @resources.find { |r| r[:name] == resource_name }
          Deployd::Models.remove_key(resource_name, key_name.to_sym)

          @resources.map { |r| r[:keys].delete_if { |k| k[:name] == key_name } if r[:name] == resource_name }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end
          @resource = resource_name.classify.constantize

          flash[:info] = 'Key successfully removed.'
          redirect "/dashboard/resources/#{resource_name}"
        end
      end

      # show key
      #
      # get '/resource/user/name'
      #
      get '/resources/:resource_name/:key_name' do
        @resource_name = params[:resource_name]
        @key_name = params[:key_name]

        if @resources && @resources.find { |r| r[:name] == @resource_name }
          @resource = @resource_name.classify.constantize
          @key = @resource.keys.select { |k| k[@key_name] }[@key_name]
        end

        slim :'resources/keys/show'
      end

      # edit key
      #
      # put '/resource/user/nemae'
      #
      put '/resources/:resource_name/:key_name' do
        resource_name = params[:resource_name]
        key_name = params[:key_name]

        key_type = params[:type]
        required = params[:required] ? true : false
        unique = params[:unique] ? true : false
        options = { required: required, unique: unique }

        if @resources && @resources.find { |r| r[:name] == resource_name }
          # change type and/or options, remove key and add new
          Deployd::Models.remove_key(resource_name, key_name.to_sym)
          Deployd::Models.add_key(resource_name, key_name.to_sym, key_type.constantize, options)

          @resources.map { |r| r[:keys].delete_if { |k| k[:name] == key_name } if r[:name] == resource_name }
          @resources.find { |r| r[:name] == resource_name }[:keys] << { name: key_name, type: key_type.constantize, options: options }

          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end
          @resource = resource_name.classify.constantize

          flash[:info] = 'Key successfully changed.'
          redirect "/dashboard/resources/#{resource_name}"
        end
      end
    end
  end
end
