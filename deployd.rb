require 'yaml'
require 'pp'
require 'active_support/core_ext/string'
require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/flash'
require 'sinatra/subdomain'
require 'sinatra/assetpack'
require 'slim'
require 'mongoid'
require 'logger'
require 'pry'

Slim::Engine.set_options pretty: true,
  attr_list_delims: {'(' => ')', '[' => ']'} # removed '{' => '}' from default

module Deployd
  class Application < Sinatra::Base
    register Sinatra::Namespace
    register Sinatra::Flash
    register Sinatra::Subdomain

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
      set :bind, 'deployerb-dev.com'
      set :port, 9292

      register Sinatra::AssetPack

      assets {
        serve '/js', from: 'assets/js'
        serve '/css', from: 'assets/css'
        serve '/images', from: 'assets/images'
        serve '/node_modules', from: 'node_modules'

        js :app, '/js/app.js', [
          '/js/deployd.js'
        ]

        css :application, '/css/application.css', [
          '/css/deployd.css',
        ]

        css :libs, [
          '/node_modules/bootstrap/dist/css/bootstrap.css',
        ]

        js :libs, [
          '/node_modules/jquery/dist/jquery.js',
          '/node_modules/bootstrap/dist/js/bootstrap.js',
        ]

        js :angular, [
          '/node_modules/angular/angular.js',
          '/node_modules/angular-resource/angular-resource.js',
          '/node_modules/angular-ui-bootstrap/dist/ui-bootstrap-tpls.js',
          '/node_modules/checklist-model/checklist-model.js',
        ]

        js_compression :jsmin
      }

      $logger = Logger.new(STDOUT)
    end

    not_found do
      if subdomain && subdomain == 'api'
        content_type :json
        { status: 'error', data: 'The URI requested is invalid' }.to_json
      else
        content_type :html
        status 404
        slim :'404'
      end
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

  end
end

require_relative 'lib/sinatra-flash'
require_relative 'lib/initializers/mongoid'
require_relative 'app/models/init'
require_relative 'app/controllers/init'
