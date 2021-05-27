require 'bundler'

Bundler.require

require './deployd'

run Deployd::Application
