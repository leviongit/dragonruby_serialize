class String
  def serialize
    self
  end

  def self.deserialize(str)
    str
  end
end

class Integer
  def serialize
    to_s
  end

  def self.deserialize(str)
    str.to_i
  end
end

module Base64
  def self.strict_encode64(str)
    [str].pack('m0')
  end

  def self.strict_decode64(str)
    str.unpack('m0').first
  end
end

module Serializable
  def self.included(base)
    base.class_eval do
      attr_accessor :serializable_fields
    end
    base.extend ClassMethods
  end

  def self.deserialize(serialized_obj)
    b64_klass, *fields = serialized_obj.split('__')
    klass = Object.const_get(Base64.strict_decode64(b64_klass))
    klass.deserialize(fields)
  end

  module ClassMethods
    def deserialize(serialized_fields)
      instance = self.allocate
      serialized_fields.each do |str|
        field, class_name, serialized_value = str.split('--').map { |s| Base64.strict_decode64(s) }
        klass = Object.const_get(class_name)
       instance.send(:"#{field}=", klass.deserialize(serialized_value))
      end
      instance
    end

    def serializable_fields
      @serializable_fields ||= []
    end

    def serialize_field(field)
      field = field.to_sym
      serializable_fields << field
      attr_accessor field unless instance_variable_defined?(:"@#{field}")
    end
  end

  def serialize
    serialized_fields = self.class.serializable_fields.map do |field|
      value = self.send(field)
      [field.to_s, value.class.name, value.serialize].map { |val| Base64.strict_encode64(val) }.join("--")
    end
    [Base64.strict_encode64(self.class.name)].concat(serialized_fields).join("__")
  end
end

if ARGV[0] == 'test'
  class SerializableTest
    include Serializable
    serialize_field :x
    serialize_field :y
    serialize_field :w
    serialize_field :h
    serialize_field :path
  end

  obj = SerializableTest.new.tap do |o|
    o.x = 0
    o.y = 0
    o.w = 1280
    o.h = 720
    o.path = "sprites/foo.png"
  end

  # Note: Objects will have different ids due to serialization process
  puts "Expected: #{obj.inspect}"
  puts "Actual: #{Serializable.deserialize(obj.serialize).inspect}"
end
