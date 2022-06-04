import gleam/list
import gleam/int
import gleam/bit_string
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedMapEntry, PackedNil, PackedString, PackedUnused, PackedValue,
}

pub type DecodeError {
  BadSegmentHeader
  BadSegmentContents
}

type DecodeResult =
  Result(List(PackedValue), DecodeError)

pub fn decode(data: BitString) -> DecodeResult {
  case data {
    // empty
    <<>> -> Ok([])

    // nil
    <<0xc0, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedNil, ..rest])
    }

    // never used
    <<0xc1, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedUnused, ..rest])
    }

    // bool
    <<0xc2, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedBool(False), ..rest])
    }

    <<0xc3, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedBool(True), ..rest])
    }

    // positive fixint
    <<0b0:1, n:7, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedInt(n), ..rest])
    }

    // negative fixint
    <<0b111:3, n:5, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedInt(int.negate(n)), ..rest])
    }

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

    // float
    <<0xca, _n:32, rest:binary>> -> {
      todo("parse single precision floats")
      try rest = decode(rest)
      Ok([PackedFloat(0.0), ..rest])
    }

    <<0xcb, n:float, rest:binary>> -> {
      try rest = decode(rest)
      Ok([PackedFloat(n), ..rest])
    }

    // bin
    <<0xc4, length:8, rest:binary>> -> decode_binary(rest, length)
    <<0xc5, length:16, rest:binary>> -> decode_binary(rest, length)
    <<0xc6, length:32, rest:binary>> -> decode_binary(rest, length)

    // fixstr
    <<0b101:3, length:5, rest:binary>> -> decode_string(rest, length)

    // str
    <<0xd9, length:8, rest:binary>> -> decode_string(rest, length)
    <<0xda, length:16, rest:binary>> -> decode_string(rest, length)
    <<0xdb, length:32, rest:binary>> -> decode_string(rest, length)

    // fixarr
    <<0b1001:4, count:4, rest:binary>> -> decode_array(rest, count)

    // arr
    <<0xdc, count:16, rest:binary>> -> decode_array(rest, count)
    <<0xdd, count:32, rest:binary>> -> decode_array(rest, count)

    // fixmap
    <<0b1000:4, count:4, rest:binary>> -> decode_map(rest, count)

    // map
    <<0xde, count:16, rest:binary>> -> decode_map(rest, count)
    <<0xdf, count:32, rest:binary>> -> decode_map(rest, count)

    // fixext
    <<0xd4, rest:binary>> -> decode_ext(rest, 8)
    <<0xd5, rest:binary>> -> decode_ext(rest, 16)
    <<0xd6, rest:binary>> -> decode_ext(rest, 32)
    <<0xd7, rest:binary>> -> decode_ext(rest, 64)
    <<0xd8, rest:binary>> -> decode_ext(rest, 128)

    // ext
    <<0xc7, length:8, rest:binary>> -> decode_ext(rest, length)
    <<0xc8, length:16, rest:binary>> -> decode_ext(rest, length)
    <<0xc9, length:32, rest:binary>> -> decode_ext(rest, length)

    _ -> Error(BadSegmentHeader)
  }
}

fn decode_int(data: BitString, length: Int) -> DecodeResult {
  let <<value:signed-size(length), rest:binary>> = data
  try rest = decode(rest)
  Ok([PackedInt(value), ..rest])
}

fn decode_uint(data: BitString, length: Int) -> DecodeResult {
  let <<value:size(length), rest:binary>> = data
  try rest = decode(rest)
  Ok([PackedInt(value), ..rest])
}

fn decode_string(data: BitString, length: Int) -> DecodeResult {
  let <<value:binary-size(length), rest:binary>> = data
  try rest = decode(rest)

  case bit_string.to_string(value) {
    Ok(str) -> Ok([PackedString(str), ..rest])
    Error(e) -> Error(BadSegmentContents)
  }
}

fn decode_binary(data: BitString, length: Int) -> DecodeResult {
  let <<value:binary-size(length), rest:binary>> = data
  try rest = decode(rest)
  Ok([PackedBinary(value), ..rest])
}

fn decode_array(data: BitString, count: Int) -> DecodeResult {
  try rest = decode(data)
  let #(values, rest) = list.split(rest, count)
  Ok([PackedArray(values), ..rest])
}

fn decode_map(data: BitString, count: Int) -> DecodeResult {
  try rest = decode(data)
  let #(values, rest) = list.split(rest, count * count)
  Ok([PackedMap(chunk_map_entries(values)), ..rest])
}

fn chunk_map_entries(values: List(PackedValue)) -> List(PackedMapEntry) {
  values
  |> list.sized_chunk(into: 2)
  |> list.map(fn(e) {
    let [k, v] = e
    #(k, v)
  })
}

fn decode_ext(data: BitString, length: Int) -> DecodeResult {
  let <<ext_type:signed-8, ext_data:binary-size(length), rest:binary>> = data
  try rest = decode(rest)
  Ok([PackedExt(ext_type, ext_data), ..rest])
}
