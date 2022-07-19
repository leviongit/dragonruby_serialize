module LevisLibs
  class DecodeError < StandardError; end

  module Deserialize
    class << self
      def load(bytes)
        reader = begin
            if bytes.is_a? Array
              make_reader(bytes.pack("C*"))
            elsif bytes.is_a? String
              make_reader(bytes)
            elsif bytes.is_a? IO
              bytes
            else
              raise DecodeError,
                    "bytes must be a BINARY (ASCII-8BIT) encoded string, an array of byte integers, or an IO object"
            end
          end

        val = case (tt = reader.getc.ord)
          when DataTag::TT_Ary
            dat = []
            i = 0
            len = reader.read(4).unpack("N")[0]

            while i < len
              dat << Deserialize.load(reader)
              i += 1
            end

            dat
          when DataTag::TT_Hsh
            dat = []
            i = 0
            len = reader.read(4).unpack("N")[0]

            while i < len
              dat << [Deserialize.load(reader), Deserialize.load(reader)]
              i += 1
            end

            dat.to_h
          when DataTag::TT_Obj
            kname_len = reader.read(4).unpack("N")[0]
            klass = Object.const_get(reader.read(kname_len))

            instance = klass.allocate

            dat = []
            i = 0
            len = reader.read(4).unpack("N")[0]

            while i < len
              dat << Deserialize.load(reader)
              i += 1
            end

            klass.__binary_serialized_fields.zip(dat).each { |fld, val|
              instance.send :"#{fld}=", val
            }

            instance
          when DataTag::TT_Str | DataTag::TT_Str_String
            len = reader.read(4).unpack("N")[0]
            reader.read(len)
          when DataTag::TT_Str | DataTag::TT_Str_Symbol
            len = reader.read(4).unpack("N")[0]
            reader.read(len).to_sym
          when DataTag::TT_Int
            reader.read(8).unpack("Q>")[0]
          when DataTag::TT_Flt
            reader.read(8).unpack("G")[0]
          when DataTag::TT_Dat | DataTag::TT_Dat_True
            true
          when DataTag::TT_Dat | DataTag::TT_Dat_False
            false
          when DataTag::TT_Dat | DataTag::TT_Dat_Nil
            nil
          when DataTag::TT_Rng, DataTag::TT_Rng | DataTag::TT_Rng_EE
            b = Deserialize.load(reader)
            e = Deserialize.load(reader)

            if (tt & DataTag::TT_Rng_EE == DataTag::TT_Rng_EE)
              b...e
            else
              b..e
            end
          else
            raise DecodeError, <<~ERR
                    Unrecognised record type, got #{tt} (chr #{tt.chr})
                  ERR
          end
      ensure
        val
      end

      def make_reader(str)
        read, write = IO.pipe
        read.tap {
          write << str
        }
      end
    end
  end
end
