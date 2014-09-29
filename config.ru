require 'bundler'

Bundler.require

require './deployd.rb'

run Deployd::Application
