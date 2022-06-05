import gleam/int
import gleam/list
import gleam/string
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedMapEntry, PackedNil, PackedString, PackedValue, max_arr16_len, max_arr32_len,
  max_fixarr_len, max_fixmap_len, max_fixstr_len, max_int08, max_int16, max_int32,
  max_int64, max_map16_len, max_map32_len, max_pos_fixint, max_str08_len, max_str16_len,
  max_str32_len, max_uint08, max_uint16, max_uint32, max_uint64, min_int08, min_int16,
  min_int32, min_int64, min_neg_fixint,
}

pub fn encode(values: List(PackedValue)) -> BitString {
  bit_builder.new()
  |> list.fold(values, _, encode_value)
  |> bit_builder.to_bit_string()
}

fn encode_value(into: BitBuilder, value: PackedValue) -> BitBuilder {
  case value {
    PackedNil ->
      into
      |> bit_builder.append(<<0xc0>>)

    PackedBool(False) ->
      into
      |> bit_builder.append(<<0xc2>>)

    PackedBool(True) ->
      into
      |> bit_builder.append(<<0xc3>>)

    PackedInt(data) ->
      into
      |> bit_builder.append(encode_int(data))

    PackedFloat(data) ->
      into
      |> bit_builder.append(encode_float(data))

    PackedString(data) ->
      into
      |> bit_builder.append(encode_string_prefix(data))
      |> bit_builder.append_string(data)

    PackedBinary(data) ->
      into
      |> bit_builder.append(encode_binary_prefix(data))
      |> bit_builder.append(data)

    PackedArray(data) ->
      into
      |> bit_builder.append(encode_array_prefix(data))
      |> list.fold(data, _, encode_value)

    PackedMap(data) ->
      into
      |> bit_builder.append(encode_map_prefix(data))
      |> list.fold(data, _, encode_map_entry)

    PackedExt(ext_type, ext_data) ->
      into
      |> bit_builder.append(encode_ext_prefix(ext_type, ext_data))
      |> bit_builder.append(ext_data)
  }
}

fn encode_map_entry(into: BitBuilder, entry: PackedMapEntry) -> BitBuilder {
  into
  |> encode_value(entry.0)
  |> encode_value(entry.1)
}

fn encode_int(value: Int) -> BitString {
  case value {
    0 -> <<0:8>>

    // positive fixint
    n if n > 0 && n <= max_pos_fixint -> <<0:1, n:7>>

    // negative fixint
    n if n < 0 && n >= min_neg_fixint -> <<111:3, int.negate(n):5>>

    // uints
    n if n >= 0 && n <= max_uint08 -> <<0xcc, n:08>>
    n if n >= 0 && n <= max_uint16 -> <<0xcd, n:16>>
    n if n >= 0 && n <= max_uint32 -> <<0xce, n:32>>
    n if n >= 0 && n <= max_uint64 -> <<0xcf, n:64>>

    // ints
    n if n >= min_int08 && n <= max_int08 -> <<0xd0, n:08>>
    n if n >= min_int16 && n <= max_int16 -> <<0xd1, n:16>>
    n if n >= min_int32 && n <= max_int32 -> <<0xd2, n:32>>
    n if n >= min_int64 && n <= max_int64 -> <<0xd3, n:64>>
  }
}

fn encode_float(value: Float) -> BitString {
  // TODO encode single precision floats under 0xca
  <<0xcb, value:float>>
}

fn encode_string_prefix(value: String) -> BitString {
  case string.length(value) {
    len if len <= max_fixstr_len -> <<0b101:3, len:5>>
    len if len <= max_str08_len -> <<0xd9, len:08>>
    len if len <= max_str16_len -> <<0xda, len:16>>
    len if len <= max_str32_len -> <<0xdb, len:32>>
  }
}

fn encode_binary_prefix(value: BitString) -> BitString {
  case bit_string.byte_size(value) {
    len if len <= max_uint08 -> <<0xd9, len:08>>
    len if len <= max_uint16 -> <<0xda, len:16>>
    len if len <= max_uint32 -> <<0xdb, len:32>>
  }
}

fn encode_array_prefix(value: List(PackedValue)) -> BitString {
  case list.length(value) {
    len if len <= max_fixarr_len -> <<0b1001:4, len:4>>
    len if len <= max_arr16_len -> <<0xd9, len:16>>
    len if len <= max_arr32_len -> <<0xda, len:32>>
  }
}

fn encode_map_prefix(data: List(PackedMapEntry)) -> BitString {
  case list.length(data) {
    len if len <= max_fixmap_len -> <<0b1000:4, len:4>>
    len if len <= max_map16_len -> <<0xd9, len:16>>
    len if len <= max_map32_len -> <<0xda, len:32>>
  }
}

fn encode_ext_prefix(ext_type: Int, ext_data: BitString) -> BitString {
  case bit_string.byte_size(ext_data) {
    1 -> <<0xd4, ext_type:8>>
    2 -> <<0xd5, ext_type:8>>
    4 -> <<0xd6, ext_type:8>>
    8 -> <<0xd7, ext_type:8>>
    16 -> <<0xd8, ext_type:8>>
    len if len < max_uint08 -> <<0xc7, len:08, ext_type:8>>
    len if len < max_uint16 -> <<0xc8, len:16, ext_type:8>>
    len if len < max_uint32 -> <<0xc9, len:32, ext_type:8>>
  }
}
