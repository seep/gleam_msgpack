import gleam/list
import gleam/int
import gleam/bit_string
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedMapEntry, PackedNil, PackedString, PackedUnused, PackedValue,
}

pub fn decode(data: BitString) -> List(PackedValue) {
  case data {
    // empty
    <<>> -> []

    // positive fixint
    <<0b0:1, value:7, rest:binary>> -> [PackedInt(value), ..decode(rest)]

    // fixmap
    <<0b1000:4, count:4, rest:binary>> -> decode_map(rest, count)

    // fixarr
    <<0b1001:4, count:4, rest:binary>> -> decode_array(rest, count)

    // fixstr
    <<0b101:3, length:5, rest:binary>> -> decode_string(rest, length)

    // nil
    <<0xc0, rest:binary>> -> [PackedNil, ..decode(rest)]

    // never used
    <<0xc1, rest:binary>> -> [PackedUnused, ..decode(rest)]

    // bool
    <<0xc2, rest:binary>> -> [PackedBool(False), ..decode(rest)]
    <<0xc3, rest:binary>> -> [PackedBool(True), ..decode(rest)]

    // bin
    <<0xc4, length:8, rest:binary>> -> decode_binary(rest, length)
    <<0xc5, length:16, rest:binary>> -> decode_binary(rest, length)
    <<0xc6, length:32, rest:binary>> -> decode_binary(rest, length)

    // ext
    <<0xc7, length:8, rest:binary>> -> decode_ext(rest, length)
    <<0xc8, length:16, rest:binary>> -> decode_ext(rest, length)
    <<0xc9, length:32, rest:binary>> -> decode_ext(rest, length)

    // float
    <<0xca, _value:32, _rest:binary>> -> todo("parse single precision floats")
    <<0xcb, value:float, rest:binary>> -> [PackedFloat(value), ..decode(rest)]

    // uint
    <<0xcc, rest:binary>> -> decode_uint(rest, 8)
    <<0xcd, rest:binary>> -> decode_uint(rest, 16)
    <<0xce, rest:binary>> -> decode_uint(rest, 32)
    <<0xcf, rest:binary>> -> decode_uint(rest, 64)

    // int
    <<0xd0, rest:binary>> -> decode_int(rest, 8)
    <<0xd1, rest:binary>> -> decode_int(rest, 16)
    <<0xd2, rest:binary>> -> decode_int(rest, 32)
    <<0xd3, rest:binary>> -> decode_int(rest, 64)

    // fixext
    <<0xd4, rest:binary>> -> decode_ext(rest, 8)
    <<0xd5, rest:binary>> -> decode_ext(rest, 16)
    <<0xd6, rest:binary>> -> decode_ext(rest, 32)
    <<0xd7, rest:binary>> -> decode_ext(rest, 64)
    <<0xd8, rest:binary>> -> decode_ext(rest, 128)

    // str
    <<0xd9, length:8, rest:binary>> -> decode_string(rest, length)
    <<0xda, length:16, rest:binary>> -> decode_string(rest, length)
    <<0xdb, length:32, rest:binary>> -> decode_string(rest, length)

    // arr
    <<0xdc, count:16, rest:binary>> -> decode_array(rest, count)
    <<0xdd, count:32, rest:binary>> -> decode_array(rest, count)

    // map
    <<0xde, count:16, rest:binary>> -> decode_map(rest, count)
    <<0xdf, count:32, rest:binary>> -> decode_map(rest, count)

    // negative fixint
    <<0b111:3, value:5, rest:binary>> -> [
      PackedInt(int.negate(value)),
      ..decode(rest)
    ]
  }
}

fn decode_int(data: BitString, length: Int) -> List(PackedValue) {
  let <<value:signed-size(length), rest:binary>> = data
  [PackedInt(value), ..decode(rest)]
}

fn decode_uint(data: BitString, length: Int) -> List(PackedValue) {
  let <<value:size(length), rest:binary>> = data
  [PackedInt(value), ..decode(rest)]
}

fn decode_string(data: BitString, length: Int) -> List(PackedValue) {
  let <<value:binary-size(length), rest:binary>> = data
  assert Ok(value) = bit_string.to_string(value)

  [PackedString(value), ..decode(rest)]
}

fn decode_binary(data: BitString, length: Int) -> List(PackedValue) {
  let <<value:binary-size(length), rest:binary>> = data
  [PackedBinary(value), ..decode(rest)]
}

fn decode_array(data: BitString, count: Int) -> List(PackedValue) {
  let #(values, rest) = decode_count(data, count)
  [PackedArray(values), ..rest]
}

fn decode_map(data: BitString, count: Int) -> List(PackedValue) {
  let #(values, rest) = decode_count(data, count * count)
  let entries =
    values
    |> list.sized_chunk(into: 2)
    |> list.map(fn(e) {
      let [k, v] = e
      #(k, v)
    })
  [PackedMap(entries), ..rest]
}

fn decode_ext(data: BitString, length: Int) -> List(PackedValue) {
  let <<ext_type:signed-8, ext_data:binary-size(length), rest:binary>> = data
  [PackedExt(ext_type, ext_data), ..decode(rest)]
}

fn decode_count(
  data: BitString,
  count: Int,
) -> #(List(PackedValue), List(PackedValue)) {
  decode(data)
  |> list.split(count)
}
