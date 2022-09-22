# frozen_string_literal: true

module LevisLibs
  module DataTag
    include Enum
    TT_Nil = i(0)
    TT_False = i
    TT_True = i
    TT_Int8 = i
    TT_Int16 = i
    TT_Int32 = i
    TT_Int64 = i
    TT_Float = i
    TT_String = i
    TT_Symbol = i
    TT_RangeEndExclude = i
    TT_RangeEndInclude = i
    TT_Array = i
    TT_Hash = i
    TT_Time = i
    TT_Struct = i
    TT_Object = i
    TT_ObjectByName = i
    TT_EmptyA = i
    TT_Single = i
    TT_Pair = i
    TT_Triple = i
    TT_Quad = i
    TT_LAST = i(TT_Quad)
    EOD = i(63)
  end
end
