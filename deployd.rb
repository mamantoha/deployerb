require 'yaml'
require 'pp'
require 'active_support/core_ext/string'
require 'sinatra/base'
require 'sinatra/namespace'
require 'slim'
require 'mongo_mapper'
require 'logger'

Slim::Engine.set_default_options :pretty => true

module Deployd
  class Application < Sinatra::Base
    def self.load_or_initialize_config_file
      File.open(File.expand_path('config/config.yml', settings.root), 'a+') do |f|
        config = YAML.load(f)
        unless config # config file empty
          config = { resources: [] }.to_yaml
          f.write config
        end
      end
      YAML.load(File.open(File.expand_path('config/config.yml', settings.root)))
    end

    configure do
      set :logging, true
      set :views, 'app/views'
      set :public_folder, 'public'
      set :root, (settings.root || File.dirname(__FILE__))
      set :config_file, load_or_initialize_config_file

      # enable the POST _method hack
      use Rack::MethodOverride

      use Rack::Static, :urls => ['/bootstrap-3.2.0-dist'], :root => 'public'

      $logger = Logger.new(STDOUT)
    end

    not_found do
      content_type :json
      { status: 'error', data: 'Page not found' }.to_json
    end

    register Sinatra::Namespace
  end
end

require_relative 'lib/initializers/mongo'
require_relative 'app/models/init'
require_relative 'app/controllers/init'
