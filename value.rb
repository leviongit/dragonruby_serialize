# frozen_string_literal: true

module LevisLibs
  class Value
    class ValueError < StandardError; end

    module Tag
      include Enum
      BOT = i(0)
      TT_Nil = i(BOT)
      TT_False = i
      TT_True = i
      # TT_Int8 = i
      # TT_Int16 = i
      # TT_Int32 = i
      # TT_Int64 = i
      TT_Int = i
      TT_Float = i
      TT_String = i
      TT_Symbol = i
      TT_Range = i
      TT_Array = i
      TT_Hash = i
      TT_Time = i
      TT_Struct = i
      TT_Object = i
      TT_ObjectByName = i
      # TT_ArrayEmpty = i
      # TT_ArraySingle = i
      # TT_ArrayPair = i
      # TT_ArrayTriple = i
      # TT_ArrayQuad = i
      TT_Pool = i
      TT_PoolLookup = i
      TT_LAST = i(i - 1)
      EOD = i(63)
      TI_HasFlags = i(128)
    end

    module Flags
      module ArrayFlags
        include ShiftEnum
        TF_Empty = i
        TF_Single = i
        TF_Pair = i
        TF_Triple = i
        TF_Quad = i
      end

      module IntFlags
        include ShiftEnum
        TF_8Bit = i
        TF_16Bit = i
        TF_32Bit = i
        TF_64Bit = i
        TF_Unsigned = i
      end

      module RangeFlags
        include ShiftEnum
        TF_EndExluded = i
        TF_Beginless = i
        TF_Endless = i
      end
    end

    def initialize(tag, *values, fmt: nil, optimize: true)
      @tag = tag
      @values = values
      @optimize = optimize
      @fmt = fmt
    end

    class << self
      def infer(value, optimize = true)
        case value
        when nil
          self.nil()
        when true
          self.true()
        when false
          self.false()
        when Integer
          integer(value, optimize)
        when Float
          float(value)
        when Symbol
          symbol(value, optimize)
        when String
          string(value, optimize)
        when Range
          range(value, optimize)
        when Array
          array(value, optimize)
        when Hash
          hash(value, optimize)
        when Time
          time(value)
        when Struct
          struct(value, optimize)
        else
          raise ValueError, "Unable to infer Value type"
        end
      end

      def nil()
        @nil ||= new(Tag::TT_Nil)
      end

      def true()
        @true ||= new(Tag::TT_True)
      end

      def false()
        @false ||= new(Tag::TT_False)
      end

      def integer(value, optimize = true)
        new(Tag::TT_Int, value, optimize: optimize)
      end

      def float(value)
        new(Tag::TT_Float, value)
      end

      def symbol(value, optimize = true)
        new(Tag::TT_Symbol, value, optimize: optimize)
      end

      def string(value, optimize = true)
        new(Tag::TT_String, value, optimize: optimize)
      end

      def range(value, optimize = true)
        new(Tag::TT_Range, value, optimize: optimize)
      end

      def array(value, optimize = true)
        new(Tag::TT_Array, value, optimize: optimize)
      end

      def hash(value, optimize = true)
        new(Tag::TT_Hash, value, optimize: optimize)
      end

      def time(value)
        new(Tag::TT_Time, value)
      end

      def struct(value, optimize = true)
        new(Tag::TT_Struct, value, optimize: optimize)
      end
    end
  end
end
