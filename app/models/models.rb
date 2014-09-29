module Deployd
  module Models

    # http://mongomapper.com/documentation/documents/types.html
    AVAILABLE_TYPES = [Array, Float, Hash, Integer, NilClass, Object, String, Time, Binary, Boolean, Date, ObjectId, Set]

    # create MongoMapper::Document class
    #
    # params:
    #   class_name - UpperCamelCase string
    #
    def self.new(class_name)
      class_name = class_name.classify
      klass = Object.const_set(class_name, Class.new)
      klass.class_eval do
        include MongoMapper::Document
      end
    end

    # Since MongoDB is schema-less, models specify the schema for a document.
    # Each document is made up of keys.
    # Keys are named and type-cast so you know your data is stored in the correct format.
    #
    # params:
    #   class_name - UpperCamelCase string
    #   key_name - Symbol
    #   key_type - Class object
    #
    def self.add_key(class_name, key_name, key_type)
      class_name.constantize.send :key, key_name, key_type

      # attr_accessible allows to specify a whitelist of keys that can be set when using mass-assignment
      class_name.constantize.send :attr_accessible, key_name
    end

    def self.initialize_from_config_file!
      resources = Deployd::Application.settings.config_file[:resources]

      resources.each do |res|
        class_name = res[:name].classify
        Deployd::Models::new(class_name)

        res[:keys].each do |key|
          Deployd::Models::add_key(class_name, key[:name].to_sym, key[:type])
        end
      end

    end
  end
end
