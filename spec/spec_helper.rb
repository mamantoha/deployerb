# frozen_string_literal: true

require 'sinatra'

Sinatra::Application.environment = :test
Bundler.require :default, Sinatra::Application.environment
require 'rspec'
require 'capybara'
require 'capybara/dsl'

RSpec.configure do |config|
  # ...
end
