module Deployd
  module Models
    # Mongoid 7.3
    # https://docs.mongodb.com/ecosystem/tutorial/mongoid-documents/#fields
    AVAILABLE_TYPES = [Array, BigDecimal, Mongoid::Boolean, Date, DateTime, Float, Hash, Integer, BSON::ObjectId, BSON::Binary, Range, Regexp, String, Symbol, Time].freeze

    # http://mongoid.org/en/mongoid/v3/validation.html
    AVAILABLE_VALIDATIONS = %i[uniqueness presence].freeze

    # keep a list of available models in a class variable
    class << self; attr_reader :available_models; end
    @available_models = []

    # create Mongoid::Document class
    #
    # @params [ String ] resource_name Resource name.
    #
    def self.new(resource_name)
      class_name = resource_name.singularize.classify
      klass = Object.const_set(class_name, Class.new)
      @available_models << klass
      klass.class_eval do
        include Mongoid::Document
        include Mongoid::Suicide

        class << self; attr_accessor :serializable_keys end

        @serializable_keys = [:_id]

        def serializable_hash(options = {})
          serializable_keys = self.class.serializable_keys
          super({ only: serializable_keys }.merge(options))
        end
      end
    end

    # remove Mongoid::Document class
    #
    # @param [ String ] resource_name Resource name.
    #
    def self.remove(resource_name)
      class_name = resource_name.singularize.classify
      klass = class_name.constantize
      @available_models.delete(klass)
      Object.send(:remove_const, class_name.to_sym) if Object.constants.include?(class_name.to_sym)
    end

    # Add key and validations to Mongoid::Document
    #
    # Since MongoDB is schema-less, models specify the schema for a document.
    # Each document is made up of keys(fields).
    # Keys are named and type-cast so you know your data is stored in the correct format.
    #
    # @param [ String ] resource_name Resource name.
    # @param [ Symbol ] key_name Key name.
    # @param [ Object ] key_type Key type.
    # @param [ Hash ] options Options.
    # @param [ Array ] validations Validations.
    #
    def self.add_key(resource_name, key_name, key_type, options: {}, validations: [])
      class_name = resource_name.singularize.classify
      class_name.constantize.field(key_name.downcase, options.merge({ type: key_type }))
      class_name.constantize.serializable_keys << key_name.downcase.to_sym

      # add validations for model
      validations.each do |validation|
        if AVAILABLE_VALIDATIONS.include?(validation)
          class_name.constantize.validates key_name, validation => true
        end
      end
    end

    # Remove key and validations from Mongoid::Document.
    #
    # @params [ String ] resource_name Resource name.
    # @params [ Symbol ] key_name Key name.
    #
    def self.remove_key(resource_name, key_name)
      class_name = resource_name.singularize.classify
      class_name.constantize.remove_field(key_name.downcase) # from patched Mongoid
      class_name.constantize.serializable_keys.delete(key_name.downcase.to_sym)
    end

    def self.initialize_from_config_file!
      resources = Deployd::Application.settings.config_file[:resources]

      resources.each do |res|
        Deployd::Models.new(res[:name])

        res[:keys].each do |key|
          options = key[:options] || {}
          validations = key[:validations] || []
          Deployd::Models.add_key(res[:name], key[:name].to_sym, key[:type], options: options, validations: validations)
        end
      end
    end

    # Check if key is required
    #
    # @params [ String ] resource_name Resource name.
    # @params [ String ] key_name Key name.
    #
    def self.key_required?(resource_name, key_name)
      class_name = resource_name.singularize.classify
      class_name.constantize.validators.detect { |v| v.is_a?(Mongoid::Validatable::PresenceValidator) and v.attributes.include?(key_name.to_sym) }
    end

    # Check if key is uniqueness
    #
    # @params [ String ] resource_name Resource name.
    # @params [ String ] key_name Key name.
    #
    def self.key_uniqueness?(resource_name, key_name)
      class_name = resource_name.singularize.classify
      class_name.constantize.validators.detect { |v| v.is_a?(Mongoid::Validatable::UniquenessValidator) and v.attributes.include?(key_name.to_sym) }
    end
  end # Models
end # Deployd
