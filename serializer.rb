module LevisLibs
  class Serializer
    def initialize(optimize = true)
      @optimize = optimize
      @pool = Pool.new()
      @data = []
    end
  end
end
