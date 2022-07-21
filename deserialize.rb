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
                  "bytes must be a BINARY (ASCII-8BIT) encoded string, an array of byte integers, or an IO object"
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
          when DataTag::TT_Obj
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
          when DataTag::TT_String | DataTag::TT_Str_String
            len = bytes.slice!(0, 4).unpack("N")[0]
            bytes.slice!(0, len)
          when DataTag::TT_String | DataTag::TT_Str_Symbol
            len = bytes.slice!(0, 4).unpack("N")[0]
            bytes.slice!(0, len).to_sym
          when DataTag::TT_Int
            bytes.slice!(0, 8).unpack("Q>")[0]
          when DataTag::TT_Float
            bytes.slice!(0, 8).unpack("G")[0]
          when DataTag::TT_Dat | DataTag::TT_Dat_True
            true
          when DataTag::TT_Dat | DataTag::TT_Dat_False
            false
          when DataTag::TT_Dat | DataTag::TT_Dat_Nil
            nil
          when DataTag::TT_Range, DataTag::TT_Range | DataTag::TT_Rng_EE
            b = Deserialize.load(bytes, root: false)
            e = Deserialize.load(bytes, root: false)

            if (tt & DataTag::TT_Rng_EE == DataTag::TT_Rng_EE)
              b...e
            else
              b..e
            end
          when DataTag::TT_Time
            Time.at(bytes.slice!(0, 8).unpack("Q>")[0])
          else
            raise DecodeError, <<~ERR
                    Unrecognised record type, got #{tt} (chr #{tt.chr})
                  ERR
          end
      ensure
        val
      end
    end
  end
end
