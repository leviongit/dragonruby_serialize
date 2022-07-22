module LevisLibs
  class DecodeError < StandardError; end

  module Deserialize
    class << self
      def load(bytes,
               root: true)
        bytes = case bytes
          when Array
            bytes.pack("C*")
          when String
            root ? bytes.dup : bytes
          else
            raise DecodeError,
                  "bytes must be a BINARY (ASCII-8BIT) encoded string, an array of byte integers"
          end

        val = case (tt = bytes.slice!(0).ord)
          when DataTag::TT_Array
            dat = []
            i = 0
            len = bytes.slice!(0, 4).unpack("N")[0]

            while i < len
              dat << Deserialize.load(bytes, root: false)
              i += 1
            end

            dat
          when DataTag::TT_Hash
            dat = []
            i = 0
            len = bytes.slice!(0, 4).unpack("N")[0]

            while i < len
              dat << [Deserialize.load(bytes, root: false), Deserialize.load(bytes, root: false)]
              i += 1
            end

            dat.to_h
          when DataTag::TT_Object
            kname_len = bytes.slice!(0, 4).unpack("N")[0]
            klass = Object.const_get(bytes.slice!(0, kname_len))

            instance = klass.allocate

            dat = []
            i = 0
            len = bytes.slice!(0, 4).unpack("N")[0]

            while i < len
              dat << Deserialize.load(bytes, root: false)
              i += 1
            end

            klass.__binary_serialized_fields.zip(dat).each { |fld, val|
              instance.send :"#{fld}=", val
            }

            instance
          when DataTag::TT_StructObject
            sname_len = bytes.slice!(0, 4).unpack("N")[0]
            struct = Object.const_get(bytes.slice!(0, sname_len))

            instance = struct.new

            dat = []
            i = 0
            len = bytes.slice!(0, 4).unpack("N")[0]

            while i < len
              dat << Deserialize.load(bytes, root: false)
              i += 1
            end

            struct.members.zip(dat).each { |fld, val|
              instance.send :"#{fld}=", val
            }

            instance
          when DataTag::TT_String
            len = bytes.slice!(0, 4).unpack("N")[0]
            bytes.slice!(0, len)
          when DataTag::TT_Symbol
            len = bytes.slice!(0, 4).unpack("N")[0]
            bytes.slice!(0, len).to_sym
          when DataTag::TT_Int
            bytes.slice!(0, 8).unpack("Q>")[0]
          when DataTag::TT_Float
            bytes.slice!(0, 8).unpack("G")[0]
          when DataTag::TT_True
            true
          when DataTag::TT_False
            false
          when DataTag::TT_Nil
            nil
          when DataTag::TT_Range, DataTag::TT_RangeExcludeEnd
            b = Deserialize.load(bytes, root: false)
            e = Deserialize.load(bytes, root: false)
            ((tt & DataTag::TF_RangeExcludeEndFlag) == 0) ?
              b..e :
              b...e
          when DataTag::TT_Time
            Time.at(bytes.slice!(0, 8).unpack("Q>")[0])
          else
            raise DecodeError, <<~ERR
                    Unrecognised record type, got #{tt} (chr #{tt.chr})
                  ERR
          end
      end
    end
  end
end
