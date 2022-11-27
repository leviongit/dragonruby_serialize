module LevisLibs
  class Pool
    def initialize(values = [])
      @values = values
    end

    def has_ref?(ref)
      @values.any? { |pv| pv.equal?(ref) }
    end

    def has_value?(val)
      @values.any? { |pv| pv == ref }
    end

    def <<(value)
      @values << value if !has_value?(value)
    end
  end
end
