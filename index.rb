class Class
  def attr_serialize(*args)
    args = args.flatten.map(&:to_sym)
    @__serialized_fields__ ||= []
    @__serialized_fields__.concat(args)
    attr_accessor *args
  end

  def __serialized_fields__
    @__serialized_fields__
  end
end

module Serializable
  def __serialize()
    self.class.__serialized_fields__.map { |field|
      self.send(field).__serialize()
    }
  end

  def serialize()
    __serialize.map { [_1].pack("m0") }
  end

  def self.included(cls)
    def cls.deserialize(strs)
      args = strs.map { |str| eval(str.unpack("m0")[0]) }
      instance = self.allocate
      raise ArgumentError.new("Number of argument strings does not equal field count") if args.length != self.__serialized_fields__.length
      self.__serialized_fields__.zip(args).each { |k, v|
        instance.send :"#{k}=", v
      }
      instance
    end
  end
end

class Object
  def __serialize()
    inspect
  end
end
