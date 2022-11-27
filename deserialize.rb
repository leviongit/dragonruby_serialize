# (c) 2022 leviongit
# This code is licensed under the BSD 3-Clause License license (see LICENSE for details)

module LevisLibs
  class DecodeError < StandardError; end

  # module Deserialize
  #   class << self

  #     # @param [String] bytes
  #     # @param [Integer] n
  #     # @return [String]
  #     def get_n_bytes(bytes, n)
  #       b = bytes.slice!(0, n)
  #       unless b.size == n
  #         raise DecodeError, <<~ERR
  #                 Malformed data, unexpected EOS
  #               ERR
  #       end

  #       b
  #     end

  #     # @param [String] bytes
  #     # @return [Object]
  #     def load(bytes,
  #              root: true)
  #       bytes = case bytes
  #         when Array
  #           bytes.pack("C*")
  #         when String
  #           root ? bytes.dup : bytes
  #         else
  #           raise DecodeError,
  #                 "bytes must be a BINARY (ASCII-8BIT) encoded string, an array of byte integers"
  #         end

  #       val = case (tt = bytes.slice!(0).ord)
  #         when DataTag::TT_Array
  #           dat = []
  #           i = 0
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]

  #           while i < len
  #             dat << Deserialize.load(bytes, root: false)
  #             i += 1
  #           end

  #           dat
  #         when DataTag::TT_Hash
  #           dat = []
  #           i = 0
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]

  #           while i < len
  #             dat << [Deserialize.load(bytes, root: false), Deserialize.load(bytes, root: false)]
  #             i += 1
  #           end

  #           dat.to_h
  #         when DataTag::TT_Object
  #           kname_len = get_n_bytes(bytes, 4).unpack("N")[0]
  #           klass = Object.const_get(get_n_bytes(bytes, kname_len))

  #           if klass.respond_to?(:load)
  #             return klass.load(bytes, root: false)
  #           end

  #           instance = klass.allocate

  #           dat = []
  #           i = 0
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]

  #           while i < len
  #             dat << Deserialize.load(bytes, root: false)
  #             i += 1
  #           end

  #           klass.__binary_serialized_fields.zip(dat).each { |fld, val|
  #             if fld.to_s[0] == "@"
  #               instance.instance_variable_set(fld, val)
  #             else
  #               instance.send(:"#{fld}=", val)
  #             end
  #           }

  #           instance
  #         when DataTag::TT_ObjectByName
  #           kname_len = bytes.slice!(0, 4).unpack("N")[0]
  #           klass = Object.const_get(get_n_bytes(bytes, kname_len))

  #           instance = klass.allocate

  #           i = 0
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]

  #           while i < len
  #             fldlen = get_n_bytes(bytes, 4).unpack("N")[0]
  #             fldnam = get_n_bytes(bytes, fldlen)

  #             val = Deserialize.load(bytes, root: false)

  #             if fldnam[0] == "@"
  #               instance.instance_variable_set(fldnam, val)
  #             else
  #               instance.send(:"#{fldnam}=", val)
  #             end

  #             i += 1
  #           end

  #           instance
  #         when DataTag::TT_Struct
  #           sname_len = get_n_bytes(bytes, 4).unpack("N")[0]
  #           struct = Object.const_get(get_n_bytes(bytes, sname_len))

  #           instance = struct.new

  #           dat = []
  #           i = 0
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]

  #           while i < len
  #             dat << Deserialize.load(bytes, root: false)
  #             i += 1
  #           end

  #           struct.members.zip(dat).each { |fld, val|
  #             instance.send :"#{fld}=", val
  #           }

  #           instance
  #         when DataTag::TT_String
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]
  #           get_n_bytes(bytes, len)
  #         when DataTag::TT_Symbol
  #           len = get_n_bytes(bytes, 4).unpack("N")[0]
  #           get_n_bytes(bytes, len).to_sym
  #         when DataTag::TT_Int8
  #           get_n_bytes(bytes, 1).unpack("c")[0]
  #         when DataTag::TT_Int16
  #           get_n_bytes(bytes, 2).unpack("s>")[0]
  #         when DataTag::TT_Int32
  #           get_n_bytes(bytes, 4).unpack("l>")[0]
  #         when DataTag::TT_Int64
  #           get_n_bytes(bytes, 8).unpack("q>")[0]
  #         when DataTag::TT_Float
  #           get_n_bytes(bytes, 8).unpack("G")[0]
  #         when DataTag::TT_True
  #           true
  #         when DataTag::TT_False
  #           false
  #         when DataTag::TT_Nil
  #           nil
  #         when DataTag::TT_RangeEndInclude, DataTag::TT_RangeEndExclude
  #           b = Deserialize.load(bytes, root: false)
  #           e = Deserialize.load(bytes, root: false)
  #           if tt == DataTag::TT_RangeEndInclude
  #             b..e
  #           else
  #             b...e
  #           end
  #         when DataTag::TT_Time
  #           Time.at(get_n_bytes(bytes, 8).unpack("Q>")[0])
  #         when DataTag::TT_EmptyA
  #           []
  #         when DataTag::TT_Single
  #           [Deserialize.load(bytes, root: false)]
  #         when DataTag::TT_Pair
  #           [Deserialize.load(bytes, root: false), Deserialize.load(bytes, root: false)]
  #         when DataTag::TT_Triple
  #           [
  #             Deserialize.load(bytes, root: false),
  #             Deserialize.load(bytes, root: false),
  #             Deserialize.load(bytes, root: false),
  #           ]
  #         when DataTag::TT_Quad
  #           [
  #             Deserialize.load(bytes, root: false),
  #             Deserialize.load(bytes, root: false),
  #             Deserialize.load(bytes, root: false),
  #             Deserialize.load(bytes, root: false),
  #           ]
  #         else
  #           raise DecodeError, <<~ERR
  #                   Unrecognised record type, got #{tt} (chr #{tt.chr})
  #                 ERR
  #         end
  #     end
  #   end
  # end

  class Deserializer
    def initialize(data)
      @pool = Pool.new()
      @data = ByteReader.new(data)
    end
  end
end
