# frozen_string_literal: true

require 'bundler'

Bundler.require

require './application'

run Deployd::Application
