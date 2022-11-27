module LevisLibs
  class ByteReader
    def initialize(data)
      @data = data
      @length = data.length
      @index = 0
    end

    def at_end?(skip = 0)
      @index + skip >= @length
    end

    def >>(width, unpack_format = nil, get_first_only = true, raise_at_end: false)
      raise IOError, "Tried to retrieve #{width} bytes, only #{@length - @index} left" if raise_at_end && at_end?(width - 1)
      if unpack_format
        val = @data[@index, width].unpack(unpack_format)
        @index += width
        get_first_only ? val[0] : val
      else
        val = @data[@index, width]
        @index += width
        val
      end
    end
  end
end
