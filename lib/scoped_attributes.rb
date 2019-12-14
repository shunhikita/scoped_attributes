require "scoped_attributes/version"
require "active_support/concern"

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
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{role_name}?
              raise NotImplementedError.new("You must implement #{self.class}##{__method__}") 
            end
        RUBY
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
      only = options.fetch(:only, nil)

      define_method name do
        object.public_send(name) if visible?(only)
      end
    end
  end

  def model
    (self.class.model_name || self.class.name.gsub("Scoped", "")).safe_constantize
  end

  def as_json
    attributes
  end

  def to_model
    return nil if model.nil?

    if object&.id.nil?
      model.new(attributes)
    else
      model.select(attributes.keys).find_by(id: object.id)
    end
  end

  def attributes(include_key: false)
    attributes = {}
    self.class.attributes_registry.each do |name, options|
      only = options.fetch(:only, nil)

      if visible?(only)
        attributes[name] = object.public_send(name)
      elsif include_key
        attributes[name] = nil
      end
    end
    attributes
  end

  private

  def visible?(only)
    return true if only.nil?

    case only
    when Array
      only.any? { |role| public_send("#{role}?") }
    when String
      only.public_send(string)
    when Proc
      unbound_method = generate_method(:only_call, &only)
      !!unbound_method.bind(self).call
    else
      false
    end
  end

  def generate_method(method_name, &block)
    method = nil
    Module.new do
      define_method method_name, &block
      method = instance_method method_name
      remove_method method_name
    end
    method
  end
end
