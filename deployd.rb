require 'yaml'
require 'pp'
require 'active_support/core_ext/string'
require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/flash'
require 'sinatra/assetpack'
require 'slim'
require 'mongo_mapper'
require 'logger'

Slim::Engine.set_options pretty: true,
  attr_list_delims: {'(' => ')', '[' => ']'} # removed '{' => '}' from default

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
      set :method_override, true
      set :config_file, load_or_initialize_config_file

      register Sinatra::AssetPack

      assets {
        serve '/js', from: 'assets/js'
        serve '/css', from: 'assets/css'
        serve '/images', from: 'assets/images'
        serve '/bower_components', from: 'bower_components'

        js :app, '/js/app.js', [
          '/js/deployd.js'
        ]

        css :application, '/css/application.css', [
          '/css/deployd.css',
        ]

        css :libs, [
          '/bower_components/bootstrap/dist/css/bootstrap.css',
        ]

        js :libs, [
          '/bower_components/jquery/dist/jquery.js',
          '/bower_components/bootstrap/dist/js/bootstrap.js',
        ]

        js :angular, [
          '/bower_components/angular/angular.js',
          '/bower_components/angular-resource/angular-resource.js',
          '/bower_components/angular-bootstrap/ui-bootstrap-tpls.js',
        ]

        js_compression :jsmin
      }

      $logger = Logger.new(STDOUT)
    end

    not_found do
      content_type :json
      { status: 'error', data: 'The URI requested is invalid' }.to_json
    end

    # AngularJS sends option request before any other request.
    # These lines properly manage that.
    #
    options "/*" do
      allow_headers = ["*", "Content-Type", "Accept", "AUTHORIZATION", "Cache-Control"]
      allow_methods = [:post, :get, :option, :delete, :put]
      headers_list = {
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => allow_methods.map { |m| m.to_s.upcase! }.join(', '),
        'Access-Control-Allow-Headers' => allow_headers.map(&:to_s).join(', ')
      }
      headers headers_list
    end

    enable :sessions

    register Sinatra::Namespace
    register Sinatra::Flash
  end
end

require_relative 'lib/sinatra-flash'
require_relative 'lib/initializers/mongo'
require_relative 'app/models/init'
require_relative 'app/controllers/init'
