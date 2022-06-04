import gleam/list
import gleam/string
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedMapEntry, PackedNil, PackedString, PackedValue, max_arr16_len, max_arr32_len,
  max_fixarr_len, max_fixstr_len, max_int16, max_int32, max_int64, max_int8, max_positive_fixint,
  max_str16_len, max_str32_len, max_str8_len, max_uint16, max_uint32, max_uint64,
  max_uint8, min_int16, min_int32, min_int64, min_int8, min_negative_fixint,
}

pub fn encode(values: List(PackedValue)) -> BitString {
  values
  |> list.map(fn(v) { encode_value(v, bit_builder.new()) })
  |> bit_builder.concat()
  |> bit_builder.to_bit_string()
}

pub fn encode_single(value: PackedValue) -> BitString {
  bit_builder.new()
  |> encode_value(value, _)
  |> bit_builder.to_bit_string()
}

fn encode_value(value: PackedValue, into: BitBuilder) -> BitBuilder {
  case value {
    PackedNil -> <<0xc0>>
    PackedBool(data) -> encode_bool(data)
    PackedInt(data) -> encode_int(data)
    PackedFloat(data) -> encode_float(data)
    PackedString(data) -> encode_string(data)
    PackedBinary(data) -> encode_binary(data)
    PackedArray(data) -> encode_array(data)
    PackedMap(data) -> encode_map(data)
    PackedExt(ext_type, ext_data) -> encode_ext(ext_type, ext_data)
  }
  |> bit_builder.append(into, _)
}

fn encode_bool(value: Bool) -> BitString {
  case value {
    False -> <<0xc2>>
    True -> <<0xc3>>
  }
}

fn encode_int(value: Int) -> BitString {
  case value {
    0 -> <<0:8>>

    // positive fixint
    n if n > 0 && n <= max_positive_fixint -> <<0:1, n:7>>

    // negative fixint
    n if n < 0 && n >= min_negative_fixint -> <<111:3, { 0 - n }:5>>

    // uints
    n if n >= 0 && n <= max_uint8 -> <<0xcc, n:8>>
    n if n >= 0 && n <= max_uint16 -> <<0xcd, n:16>>
    n if n >= 0 && n <= max_uint32 -> <<0xce, n:32>>
    n if n >= 0 && n <= max_uint64 -> <<0xcf, n:64>>

    // ints
    n if n >= min_int8 && n <= max_int8 -> <<0xd0, n:8>>
    n if n >= min_int16 && n <= max_int16 -> <<0xd1, n:16>>
    n if n >= min_int32 && n <= max_int32 -> <<0xd2, n:32>>
    n if n >= min_int64 && n <= max_int64 -> <<0xd3, n:64>>
  }
}

fn encode_float(value: Float) -> BitString {
  // <<0xca, value:float>> TODO encode single precision floats
  <<0xcb, value:float>>
}

fn encode_string(value: String) -> BitString {
  case string.length(value) {
    len if len <= max_fixstr_len -> <<0b101:3, len:5, value:utf8>>
    len if len <= max_str8_len -> <<0xd9, len:8, value:utf8>>
    len if len <= max_str16_len -> <<0xda, len:16, value:utf8>>
    len if len <= max_str32_len -> <<0xdb, len:32, value:utf8>>
  }
}

fn encode_binary(value: BitString) -> BitString {
  case bit_string.byte_size(value) {
    len if len <= max_uint8 -> <<0xd9, len:8, value:bit_string>>
    len if len <= max_uint16 -> <<0xda, len:16, value:bit_string>>
    len if len <= max_uint32 -> <<0xdb, len:32, value:bit_string>>
  }
}

fn encode_array(value: List(PackedValue)) -> BitString {
  case list.length(value) {
    len if len <= max_fixarr_len -> <<
      0b1001:4,
      len:4,
      encode(value):bit_string,
    >>
    len if len <= max_arr16_len -> <<0xd9, len:16, encode(value):bit_string>>
    len if len <= max_arr32_len -> <<0xda, len:32, encode(value):bit_string>>
  }
}

fn encode_map(value: List(PackedMapEntry)) -> BitString {
  case list.length(value) {
    len if len <= 15 -> <<
      0b1000:4,
      len:4,
      encode_map_entries(value):bit_string,
    >>
    len if len <= max_uint16 -> <<
      0xd9,
      len:16,
      encode_map_entries(value):bit_string,
    >>
    len if len <= max_uint32 -> <<
      0xda,
      len:32,
      encode_map_entries(value):bit_string,
    >>
  }
}

fn encode_map_entries(value: List(PackedMapEntry)) -> BitString {
  value
  |> list.map(fn(e) {
    <<encode_single(e.0):bit_string, encode_single(e.1):bit_string>>
  })
  |> bit_string.concat
}

fn encode_ext(ext_type: Int, ext_data: BitString) -> BitString {
  case bit_string.byte_size(ext_data) {
    1 -> <<0xd4, ext_type:8, ext_data:bit_string>>
    2 -> <<0xd5, ext_type:8, ext_data:bit_string>>
    4 -> <<0xd6, ext_type:8, ext_data:bit_string>>
    8 -> <<0xd7, ext_type:8, ext_data:bit_string>>
    16 -> <<0xd8, ext_type:8, ext_data:bit_string>>

    len if len < max_uint8 -> <<0xc7, len:8, ext_type:8, ext_data:bit_string>>
    len if len < max_uint16 -> <<0xc8, len:16, ext_type:8, ext_data:bit_string>>
    len if len < max_uint32 -> <<0xc9, len:32, ext_type:8, ext_data:bit_string>>
  }
}
