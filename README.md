# dragonruby_serialize

A proof-of-concept (and quite barebones) serialization library for DragonRuby

### Limitations
Current serializable objects are
- Instances of classes that include Serializable
- Integer
- String

### Usage
```ruby
class MySerializable
  include Serializable
  serialize_field :x
  serialize_field :y
  serialize_field :w
  serialize_field :h
  serialize_field :path
end

  obj = SerializableTest.new.tap do |o|
    o.x = 0
    o.y = 0
    o.w = 1280
    o.h = 720
    o.path = "sprites/foo.png"
  end
  
  serialized_obj = obj.serialize
  # U2VyaWFsaXphYmxlVGVzdA==__eA==--SW50ZWdlcg==--MA==__eQ==--SW50ZWdlcg==--MA==__dw==--SW50ZWdlcg==--MTI4MA==__aA==--SW50ZWdlcg==--NzIw__cGF0aA==--U3RyaW5n--c3ByaXRlcy9mb28ucG5n
  Serializable.deserialize(serialized_obj)
  # #<SerializableTest:0x15801ffe0 @w=1280, @path="sprites/foo.png", @y=0, @h=720, @x=0>
```
#### Note that object ids WILL NOT be the same between serialization and deserialization

### Testing
To workaround lack of requires in mruby for testing, the test is built into the class file. 
```bash
$ ruby serializable.rb test
```
