class EncodingError < StandardError; end

module DataTag
  TT_Dat = 0
  TT_Int = 1
  TT_Flt = 2
  TT_Str = 3
  TT_Rng = 4
  TT_Ary = 5
  TT_Hsh = 6
  TT_Pair = 62
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

class NilClass
  def serialize_binary()
    [DataTag::TT_Dat | DataTag::TT_Dat_Nil].pack("C")
  end
end

class TrueClass
  def serialize_binary()
    [DataTag::TT_Dat | DataTag::TT_Dat_True].pack("C")
  end
end

class FalseClass
  def serialize_binary()
    [DataTag::TT_Dat | DataTag::TT_Dat_False].pack("C")
  end
end

class Integer
  def serialize_binary()
    [DataTag::TT_Int, self].pack("CQ>")
  end
end

class Float
  def serialize_binary()
    [DataTag::TT_Flt, self].pack("CG")
  end
end

class String
  def serialize_binary()
    [
      (DataTag::TT_Str | DataTag::TT_Str_String),
      size,
      self,
    ].pack("CNA*")
  end
end

class Symbol
  def serialize_binary()
    sstr = to_s
    [
      (DataTag::TT_Str | DataTag::TT_Str_Symbol),
      sstr.size,
      sstr,
    ].pack("CNA*")
  end
end

class Range
  def serialize_binary()
    [
      (DataTag::TT_Rng | (self.exclude_end? ? DataTag::TT_Rng_EE : 0)),
      self.begin,
      self.end,
    ].pack("CQ>Q>")
  end
end

class Pair
  def initialize(l, r)
    @l = l
    @r = r
  end

  def serialize_binary()
    raise EncodingError,
          "Left object #{@l} (class #{@l.class}) does not implement the `serialize_binary` method" unless @l.respond_to? :serialize_binary
    raise EncodingError,
          "Right object #{@r} (class #{@r.class}) does not implement the `serialize_binary` method" unless @r.respond_to? :serialize_binary
    [
      DataTag::TT_Pair,
      @l.serialize_binary,
      @r.serialize_binary,
    ].pack("CA*A*")
  end
end

class Array
  def serialize_binary()
    [
      DataTag::TT_Ary,
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
      DataTag::TT_Hsh,
      ary.length,
      ary.map { |l, r|
        Pair.new(l, r).serialize_binary()
      }.join(""),
    ].pack("CNA*")
  end
end
