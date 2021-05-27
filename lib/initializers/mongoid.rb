# frozen_string_literal: true

# Configuration
Mongoid.load!(File.expand_path('../../config/mongoid.yml', File.dirname(__FILE__)), :development)

# Logging
Mongoid.logger.level = Logger::DEBUG
Mongo::Logger.logger.level = Logger::DEBUG

Mongoid.raise_not_found_error = false

module BSON
  class ObjectId
    def to_json(*_args)
      to_s.to_json
    end

    def as_json(*_args)
      to_s.as_json
    end
  end
end
