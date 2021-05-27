# frozen_string_literal: true

require_relative '../spec_helper'
require "#{Sinatra::Application.root}/../deployd"
disable :run

Capybara.app = Deployd::Application
Capybara.default_driver = :selenium

RSpec.configure do |config|
  config.include Capybara::DSL
end
