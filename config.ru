# frozen_string_literal: true

require 'bundler'

Bundler.require

require './deployd'

run Deployd::Application
