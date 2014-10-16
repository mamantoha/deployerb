module Deployd
  module Models

    # http://mongomapper.com/documentation/documents/types.html
    AVAILABLE_TYPES = [Array, Float, Hash, Integer, NilClass, Object, String, Time, Binary, Boolean, Date, ObjectId, Set]

    # create MongoMapper::Document class
    #
    # params:
    #   resource_name - String
    #
    def self.new(resource_name)
      class_name = resource_name.singularize.classify
      klass = Object.const_set(class_name, Class.new)
      klass.class_eval do
        include MongoMapper::Document

        attr_accessor :serializable_keys

        @@serializable_keys = [:id]

        def self.serializable_keys
          @@serializable_keys
        end

        def serializable_hash(options = {})
          super({ only: @@serializable_keys }.merge(options))
        end
      end
    end

    # remove MongoMapper::Document class
    #
    # params:
    #   resource_name - String
    #
    def self.remove(resource_name)
      class_name = resource_name.singularize.classify
      if Object.constants.include?(class_name.to_sym)
        Object.send(:remove_const, class_name.to_sym)
      end
    end

    # Since MongoDB is schema-less, models specify the schema for a document.
    # Each document is made up of keys.
    # Keys are named and type-cast so you know your data is stored in the correct format.
    #
    # params:
    #   resource_name - String
    #   key_name - Symbol
    #   key_type - Class object
    #
    def self.add_key(resource_name, key_name, key_type)
      class_name = resource_name.singularize.classify
      key = class_name.constantize.key(key_name, key_type)
      class_name.constantize.serializable_keys << key_name.to_sym
    end

    def self.remove_key(resource_name, key_name)
      class_name = resource_name.singularize.classify
      class_name.constantize.remove_key(key_name)
      class_name.constantize.serializable_keys.delete(key_name.to_sym)
    end

    def self.initialize_from_config_file!
      resources = Deployd::Application.settings.config_file[:resources]

      resources.each do |res|
        Deployd::Models::new(res[:name])

        res[:keys].each do |key|
          Deployd::Models::add_key(res[:name], key[:name].to_sym, key[:type])
        end
      end

    end
  end
end
