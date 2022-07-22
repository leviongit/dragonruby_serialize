# basic class to show the usage of the `Serializable` module
class Player
  include LevisLibs::Serializable # we include the base module that provides object serialization

  # here we specify which fields
  # (instance variables (`@name`)) of the object should be serialized
  attr_serialize_binary :hp, :gold, %i[x y]

  def initialize(hp, gold, x, y)
    @hp = hp
    @gold = gold
    @x = x
    @y = y
  end

  # this is defined just to pretty-print the object
  def to_s
    "<#{self.class.name} [#{self.instance_variables.map { |vname|
      "#{vname}=#{self.instance_variable_get(vname)}"
    }.join(" ")}]>"
  end

  # to override the default serialization behaviour
  # just override the `serialize_binary` method
  # this is for more advanced users that want fine control
  # over their objects
  def serialize_binary()
    # here, I will make the serialize function log
    puts "Before serialization"
    serialized = super
    puts "Serialized object"
    # the string contains many non-printable characters,
    # so I `inspect` it
    puts "Result #{serialized.inspect}"
    # and we return the result
    serialized
  end
end
