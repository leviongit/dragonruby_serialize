# (c) 2022 leviongit
# This code is licensed under the BSD 3-Clause License license (see LICENSE for details)

module LevisLibs
  class EncodingError < StandardError; end

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
        # This does not create accessor methods to allow operating on C-defined classes
        def klass.attr_serialize_binary(*attrs)
          @__binary_serialized_fields ||= []
          @__binary_serialized_fields.concat(attrs.flatten).uniq!
          @__binary_serialized_fields
        end

        def klass.__binary_serialized_fields
          @__binary_serialized_fields
        end
      end
    end

    def serialize_binary(optimise = false)
      flds = self.class.__binary_serialized_fields.map { |fld|
        # v = send(fld)
        v = nil
        if fld.to_s[0] == "@"
          v = instance_variable_get(fld)
        else
          v = send(fld)
        end

        Serializable.ensure_serializability!(v, "Field #{fld}")
        v.serialize_binary(optimise)
      }.join("")

      klass = self.class.name
      raise EncodingError, "Anonymous classes cannot be serialized" unless klass

      [DataTag::TT_Object, klass.size, klass, self.class.__binary_serialized_fields.length, flds].pack("CNA*NA*")
    end
  end

  module SerializableByName
    def self.included(klass)
      # This does not create accessor methods to allow operating on C-defined classes
      def klass.attr_serialize_binary(*attrs)
        @__binary_serialized_fields ||= []
        @__binary_serialized_fields.concat(attrs.flatten).uniq!
        @__binary_serialized_fields
      end

      def klass.__binary_serialized_fields
        @__binary_serialized_fields
      end
    end

    def serialize_binary(optimise = false)
      klass = self.class.name
      raise EncodingError, "Anonymous classes cannot be serialized" unless klass

      flds = self.class.__binary_serialized_fields.map { |fld|
        v = nil
        if fld.to_s[0] == "@"
          v = instance_variable_get(fld)
        else
          v = send(fld)
        end

        Serializable.ensure_serializability!(v, "Field #{fld}")
        [fld.size, fld.to_s, v.serialize_binary(optimise)].pack("NA*A*")
      }.join("")

      [DataTag::TT_ObjectByName, klass.size, klass, self.class.__binary_serialized_fields.length, flds].pack("CNA*NA*")
    end
  end
end

class NilClass
  def serialize_binary(optimise = false)
    # these cannot be optimised anyway
    [LevisLibs::DataTag::TT_Nil].pack("C")
  end
end

class TrueClass
  def serialize_binary(optimise = false)
    [LevisLibs::DataTag::TT_True].pack("C")
  end
end

class FalseClass
  def serialize_binary(optimise = false)
    [LevisLibs::DataTag::TT_False].pack("C")
  end
end

class Integer
  def serialize_binary(optimise = false)
    return [LevisLibs::DataTag::TT_Int64, self].pack("Cq>") unless optimise

    return [LevisLibs::DataTag::TT_Int8, self].pack("Cc") if (self >= -128 && self <= 127)
    return [LevisLibs::DataTag::TT_Int16, self].pack("Cs>") if (self >= -32768 && self <= 32767)
    return [LevisLibs::DataTag::TT_Int32, self].pack("Cl>") if (self >= -2147483648 && self <= 2147483647)
    return [LevisLibs::DataTag::TT_Int64, self].pack("Cq>")
  end
end

class Float
  def serialize_binary(optimise = false)
    [LevisLibs::DataTag::TT_Float, self].pack("CG")
  end
end

class String
  def serialize_binary(optimise = false)
    [
      LevisLibs::DataTag::TT_String,
      size,
      self,
    ].pack("CNA*")
  end
end

class Symbol
  def serialize_binary(optimise = false)
    sstr = to_s
    [
      LevisLibs::DataTag::TT_Symbol,
      sstr.size,
      sstr,
    ].pack("CNA*")
  end
end

class Range
  def serialize_binary(optimise = false)
    LevisLibs::Serializable.ensure_serializability!(self.begin, "Left object is not serializable")
    LevisLibs::Serializable.ensure_serializability!(self.end, "Right object is not serializable")
    [
      self.exclude_end? ? LevisLibs::DataTag::TT_RangeEndExclude : LevisLibs::DataTag::TT_RangeEndInclude,
      self.begin.serialize_binary(optimise),
      self.end.serialize_binary(optimise),
    ].pack("CA*A*")
  end
end

class Array
  def serialize_binary(optimise = false)
    return [
      LevisLibs::DataTag::TT_Array,
      length,
      map { |obj|
        LevisLibs::Serializable.ensure_serializability!(obj)
        obj.serialize_binary(optimise)
      }.join(""),
    ].pack("CNA*") if !optimise || length > 4

    tag = case length
          when 0 then LevisLibs::DataTag::TT_EmptyA
          when 1 then LevisLibs::DataTag::TT_Single
          when 2 then LevisLibs::DataTag::TT_Pair
          when 3 then LevisLibs::DataTag::TT_Triple
          when 4 then LevisLibs::DataTag::TT_Quad
          end

    [
      tag,
      map do |obj|
        LevisLibs::Serializable.ensure_serializability!(obj)
        obj.serialize_binary(optimise)
      end.join("")
    ].pack("CA*")
  end
end

class Hash
  def serialize_binary(optimise = false)
    ary = to_a
    [
      LevisLibs::DataTag::TT_Hash,
      ary.length,
      ary.flatten.map { |obj|
        LevisLibs::Serializable.ensure_serializability!(obj)
        obj.serialize_binary(optimise)
      }.join(""),
    ].pack("CNA*")
  end
end

class Time
  def serialize_binary(optimise = false)
    [
      LevisLibs::DataTag::TT_Time,
      to_i,
    ].pack("CQ>")
  end
end

class Struct
  def serialize_binary(optimise = false)
    # idk how I would optimise this
    name = self.class.name
    raise LevisLibs::EncodingError, <<~ERR unless name
      Anonymous structs cannot be serialized
    ERR
    [
      LevisLibs::DataTag::TT_Struct,
      name.length,
      name,
      members.length,
      members.map { |fld|
        v = send fld
        LevisLibs::Serializable.ensure_serializability!(v, "Field #{fld}")
        v.serialize_binary(optimise)
      }.join(""),
    ].pack("CNA*NA*")
  end
end
