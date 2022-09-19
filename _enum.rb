module Enum
  def self.included(klass)
    def klass.i(set = nil)
      @__enumc ||= 0
      if set
        @__enumc = set
      else
        v = @__enumc
        @__enumc += 1
        v
      end
    end
  end
end
