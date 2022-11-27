module LevisLibs
  module Enum
    def self.included(klass)
      def klass.i(set = nil)
        @__enumc ||= 0
        if set
          @__enumc = set + 1
          set
        else
          v = @__enumc
          @__enumc += 1
          v
        end
      end
    end
  end

  module ShiftEnum
    def self.included(klass)
      def klass.i()
        @__enumc ||= 1
        val = @__enumc
        @__enumc <<= 1
        val
      end
    end
  end
end
