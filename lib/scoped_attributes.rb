require "scoped_attributes/version"
require "scoped_attributes/scopable"
require 'scoped_attributes/railtie' if defined?(Rails)
require "active_support/all"

module ScopedAttributes
  extend ActiveSupport::Concern
  class Error < StandardError; end

  def initialize(object, user)
    self.object = object
    self.user = user
  end

  included do
    class_attribute :attributes_registry, instance_accessor: false
    class_attribute :model_name, instance_accessor: true
    self.attributes_registry = {}

    attr_accessor :object, :user
  end

  class_methods do
    def roles(*role_names)
      role_names.each do |role_name|
        define_method "#{role_name}?".to_sym do
          user.public_send("#{role_name}?")
        end
      end
    end

    def attribute(name, **options)
      add_attribute_registry(name.to_sym, options)
      define_attribute_reader(name.to_sym, options)
    end

    def add_attribute_registry(name, options)
      self.attributes_registry.merge!(name => options)
    end

    def define_attribute_reader(name, options)
      only = options[:only]

      define_method name do
        object.public_send(name) if visible?(only)
      end
    end
  end

  def as_json
    attributes
  end

  def to_model
    return nil if model.nil?

    if object.try(:id).nil?
      model.new(attributes)
    else
      model.select(attributes.keys).find_by(id: object.id)
    end
  end

  def attributes(include_key: false)
    attributes = {}
    self.class.attributes_registry.each do |name, options|
      only = options[:only]

      if visible?(only)
        attributes[name] = object.public_send(name)
      elsif include_key
        attributes[name] = nil
      end
    end
    attributes
  end

  private
  def model
    (self.class.model_name || self.class.name.gsub("Scoped", "")).safe_constantize
  end

  def visible?(only)
    return true if only.nil?

    case only
    when Array
      only.any? { |role| public_send("#{role}?") }
    when Symbol
      public_send(only)
    when Proc
      instance_exec(&only)
    else
      false
    end
  end
end
