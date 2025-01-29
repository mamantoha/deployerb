# frozen_string_literal: true

require 'yaml'
require 'pp'
require 'active_support/core_ext/string'
require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/flash'
require 'sinatra/subdomain'
require 'slim'
require 'mongoid'
require 'logger'
require 'pry'

Slim::Engine.set_options pretty: true,
                         attr_list_delims: { '(' => ')', '[' => ']' } # removed '{' => '}' from default

module Deployd
  # https://www.mongodb.com/docs/mongoid/current/reference/fields/
  AVAILABLE_TYPES = [
    Array,
    BSON::Binary,
    BigDecimal,
    Mongoid::Boolean,
    Date,
    DateTime,
    Float,
    Hash,
    Integer,
    Object,
    BSON::ObjectId,
    Range,
    Set,
    Regexp,
    String,
    Mongoid::StringifiedSymbol,
    Symbol,
    Time,
    ActiveSupport::TimeWithZone,
  ].freeze

  class Application < Sinatra::Base
    register Sinatra::Namespace
    register Sinatra::Flash
    register Sinatra::Subdomain

    def self.load_or_initialize_config_file
      yaml_column_pemitted_classes = Deployd::AVAILABLE_TYPES

      File.open(File.expand_path('config/config.yml', settings.root), 'a+') do |f|
        config = YAML.load_file(
          f,
          permitted_classes: yaml_column_pemitted_classes,
          aliases: true
        )

        unless config # config file empty
          config = { resources: [] }.to_yaml
          f.write config
        end
      end
      YAML.load_file(
        File.open(File.expand_path('config/config.yml', settings.root)),
        permitted_classes: yaml_column_pemitted_classes,
        aliases: true
      )
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

      $logger = Logger.new($stdout)
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
    options '/*' do
      allow_headers = ['*', 'Content-Type', 'Accept', 'AUTHORIZATION', 'Cache-Control']
      allow_methods = %i[post get option delete put]
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
