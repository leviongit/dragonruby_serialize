# dragonruby_serialize

A proof-of-concept (and quite barebones) binary serialization library for DragonRuby.
Currently supports serializing:
- `Integer`s;
- `Float`s;
- `String`s;
- `Symbol`s;
- `nil`s, `true`, and `false`;
- `Range`s;
- `Array`s;
- `Hash`es; and
- arbitrary objects including the `Serializable` module

Currently supports deserializing:
- `Integer`s;
- `Float`s;
- `String`s;
- `Symbol`s;
- `nil`s, `true`, and `false`;
- `Range`s;
- `Array`s;
- `Hash`es; and
- arbitrary objects including the `Serializable` module

Currently it is impossible to serialize recursive structures. This may change in the future.
