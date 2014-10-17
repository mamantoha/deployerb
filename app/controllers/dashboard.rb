module Deployd
  class Application < Sinatra::Base
    namespace '/dashboard' do
      before do
        @resources = settings.config_file[:resources]
      end

      get '/resources/?' do
        slim :index
      end

      # create new document
      #
      post '/resources' do
        resource_name = params[:name].singularize

        Deployd::Models::new(resource_name)
        Deployd::Controllers::new(resource_name)

        @resources << { name: resource_name, keys: [] }
        File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
          f.write settings.config_file.to_yaml
        end

        redirect '/dashboard/resources'
      end

      # remove document
      #
      delete '/resources/:resource_name' do
        resource_name = params[:resource_name]

        if @resources && @resources.detect { |r| r[:name] == resource_name }
          Deployd::Models::remove(resource_name)
          Deployd::Controllers::remove(resource_name)

          @resources.delete_if{ |r| r[:name] == resource_name }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end
          redirect '/dashboard/resources'
        else
          redirect '/dashboard/resources'
        end
      end

      # add new key to document
      #
      post '/resources/:resource_name' do
        resource_name = params[:resource_name]
        key_name = params[:name]
        key_type = params[:type]

        # Validations
        required = params[:required] ? true : false
        unique = params[:unique] ? true : false
        options = { required: required, unique: unique }

        if @resources && @resources.detect { |r| r[:name] == resource_name }
          Deployd::Models::add_key(resource_name, key_name.to_sym, key_type.constantize, options)

          @resources.detect { |r| r[:name] == resource_name }[:keys] << { name: key_name, type: key_type.constantize, options: options }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end

          @resource = resource_name.classify.constantize
          slim :show
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

        if @resources && @resources.detect { |r| r[:name] == resource_name }
          Deployd::Models::remove_key(resource_name, key_name.to_sym)

          @resources.map { |r| r[:keys].delete_if { |k| k[:name] == key_name } if r[:name] == resource_name }
          File.open(File.expand_path('config/config.yml', settings.root), 'w') do |f|
            f.write settings.config_file.to_yaml
          end
          @resource = resource_name.classify.constantize

          redirect "/dashboard/resources/#{resource_name}"
        end
      end

      get '/resources/:resource_name' do
        resource_name = params[:resource_name]

        if @resources && @resources.detect { |r| r[:name] == resource_name }
          @resource = resource_name.classify.constantize
          slim :show
        else
          redirect '/dashboard/resources'
        end
      end

    end
  end
end
