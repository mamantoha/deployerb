require 'yaml'
require 'pp'
require 'active_support/core_ext/string'
require 'sinatra/base'
require 'sinatra/namespace'
require 'slim'
require 'mongo_mapper'
require 'logger'
require 'rack/webconsole'

Slim::Engine.set_default_options :pretty => true

module Deployd
  class Application < Sinatra::Base
    configure do
      set :logging, true
      set :views, 'app/views'
      set :public_folder, 'public'
      set :root, (settings.root || File.dirname(__FILE__))
      set :config_file, YAML.load(File.read(File.expand_path('config/config.yml', File.dirname(__FILE__))))

      # enable the POST _method hack
      use Rack::MethodOverride

      use Rack::Static, :urls => ['/bootstrap-3.2.0-dist'], :root => 'public'

      $logger = Logger.new(STDOUT)
    end

    register Sinatra::Namespace
    use Rack::Webconsole
    Rack::Webconsole.inject_jquery = true
  end
end

require_relative 'lib/initializers/mongo'
require_relative 'app/models/init'
require_relative 'app/controllers/init'
