module LevisLibs
  class EncodingError < StandardError; end

  module DataTag
    TT_Nil = 0
    TT_False = 1
    TT_True = 2
    TT_Int = 3
    TT_Float = 4
    TT_String = 5
    TT_Symbol = 6
    TT_Range = 7
    TT_Array = 8
    TT_Hash = 9
    TT_Time = 10
    EOD = TT_Object = 63 # EOC
    TF_RangeExcludeEndFlag = 1 << 6
    TT_RangeExcludeEnd = TT_Range | TF_RangeExcludeEndFlag
    # 00111111
  end

  module Serializable
    class << self
      def serializable?(object)
        object.respond_to? :serialize_binary
      end

      def ensure_serializability!(object, errmsg = "")
        unless serializable?(object)
          raise EncodingError,
                <<~ERR.strip()
                  Object #{object} (class #{object.class}) does not implement the `serialize_binary` method
                  #{errmsg}
                ERR
        end
      end

      def included(klass)
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
    end

    def serialize_binary()
      flds = self.class.__binary_serialized_fields.map { |fld|
        v = send(fld)
        Serializable.ensure_serializability!(v, "Field #{fld}")
        v.serialize_binary()
      }.join("")

      klass = self.class.name
      raise EncodingError, "Anonymous classes cannot be serialized" unless klass

      [DataTag::TT_Object, klass.size, klass, self.class.__binary_serialized_fields.length, flds].pack("CNA*NA*")
    end
  end
end

class NilClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_Nil].pack("C")
  end
end

class TrueClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_True].pack("C")
  end
end

class FalseClass
  def serialize_binary()
    [LevisLibs::DataTag::TT_False].pack("C")
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
      LevisLibs::DataTag::TT_String,
      size,
      self,
    ].pack("CNA*")
  end
end

class Symbol
  def serialize_binary()
    sstr = to_s
    [
      LevisLibs::DataTag::TT_Symbol,
      sstr.size,
      sstr,
    ].pack("CNA*")
  end
end

class Range
  def serialize_binary()
    LevisLibs::Serializable.ensure_serializability!(self.begin, "Left object is not serializable")
    LevisLibs::Serializable.ensure_serializability!(self.end, "Right object is not serializable")
    [
      self.exclude_end? ? LevisLibs::DataTag::TT_RangeExcludeEnd : LevisLibs::DataTag::TT_Range,
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
        LevisLibs::Serializable.ensure_serializability!(obj)
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
        LevisLibs::Serializable.ensure_serializability!(obj)
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
