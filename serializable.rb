module LevisLibs
  class EncodingError < StandardError; end

  module DataTag
    TT_Dat = 0
    TT_Int = 1
    TT_Float = 2
    TT_String = 3
    TT_Range = 4
    TT_Array = 5
    TT_Hash = 6
    TT_Time = 7
    TT_Obj = 63 # EOC
    # 00111111
    TT_Str_String = 0
    TT_Str_Symbol = 1 << 6
    TT_Rng_EE = 1 << 6
    TT_Dat_Nil = 0
    TT_Dat_True = 1 << 6
    TT_Dat_False = 1 << 7
  end

  module Serializable
    def self.included(klass)
      def klass.attr_serialize_binary(*attrs)
        attrs = attrs.flatten.map(&:to_sym)
        @__binary_serialized_fields ||= []
        attr_accessor *(attrs - @__binary_serialized_fields)
        @__binary_serialized_fields.concat(attrs).uniq!
        @__binary_serialized_fields
      end

      def klass.__binary_serialized_fields
        @__binary_serialized_fields
      end
    end

    def serialize_binary()
      flds = self.class.__binary_serialized_fields.map { |fld|
        v = send(fld)
        raise EncodingError,
              "Field #{fld} (class #{v.class}) does not implement the `serialize_binary` method" unless v.respond_to? :serialize_binary
        v.serialize_binary()
      }.join("")

      klass = self.class.name
      raise EncodingError, "Anonymous classes cannot be serialized" unless klass

      [DataTag::TT_Obj, klass.size, klass, self.class.__binary_serialized_fields.length, flds].pack("CNA*NA*")
    end
  end
end

class NilClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_Dat | LevisLibs::DataTag::TT_Dat_Nil].pack("C")
  end
end

class TrueClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_Dat | LevisLibs::DataTag::TT_Dat_True].pack("C")
  end
end

class FalseClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_Dat | LevisLibs::DataTag::TT_Dat_False].pack("C")
  end
end

class Integer
  def serialize_binary()
    [LevisLibs::DataTag::TT_Int, self].pack("CQ>")
  end
end

class Float
  def serialize_binary()
    [LevisLibs::DataTag::TT_Float, self].pack("CG")
  end
end

class String
  def serialize_binary()
    [
      (LevisLibs::DataTag::TT_String | LevisLibs::DataTag::TT_Str_String),
      size,
      self,
    ].pack("CNA*")
  end
end

class Symbol
  def serialize_binary()
    sstr = to_s
    [
      (LevisLibs::DataTag::TT_String | LevisLibs::DataTag::TT_Str_Symbol),
      sstr.size,
      sstr,
    ].pack("CNA*")
  end
end

class Range
  def serialize_binary()
    [
      (LevisLibs::DataTag::TT_Range | (self.exclude_end? ? LevisLibs::DataTag::TT_Rng_EE : 0)),
      self.begin.serialize_binary(),
      self.end.serialize_binary(),
    ].pack("CA*A*")
  end
end

class Array
  def serialize_binary()
    [
      LevisLibs::DataTag::TT_Array,
      length,
      map { |obj|
        raise EncodingError,
              "Object #{obj} (class #{obj.class}) does not implement the `serialize_binary` method" unless obj.respond_to? :serialize_binary
        obj.serialize_binary()
      }.join(""),
    ].pack("CNA*")
  end
end

class Hash
  def serialize_binary()
    ary = to_a
    [
      LevisLibs::DataTag::TT_Hash,
      ary.length,
      ary.flatten.map { |obj|
        raise EncodingError,
              "Object #{obj} (class #{obj.class}) does not implement the `serialize_binary` method" unless obj.respond_to? :serialize_binary
        obj.serialize_binary()
      }.join(""),
    ].pack("CNA*")
  end
end

class Time
  def serialize_binary()
    [
      LevisLibs::DataTag::TT_Time,
      to_i,
    ].pack("CQ>")
  end
end
