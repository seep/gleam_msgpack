import gleeunit
import gleeunit/should
import gleam/string
import gleam/list
import gleam/bit_string
import msgpack/encode.{encode_single}
import msgpack/decode.{decode_single}
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedMapEntry, PackedNil, PackedString, PackedValue, max_arr16_len, max_bin16_len,
  max_bin8_len, max_fixarr_len, max_fixstr_len, max_int16, max_int32, max_int64,
  max_int8, max_str16_len, max_str8_len, max_uint16, max_uint32, max_uint64, max_uint8,
  min_arr16_len, min_arr32_len, min_bin16_len, min_bin32_len, min_bin8_len, min_fixarr_len,
  min_fixstr_len, min_int16, min_int32, min_int64, min_int8, min_str16_len, min_str32_len,
  min_str8_len, min_uint16, min_uint32, min_uint64, min_uint8,
}

pub fn main() {
  gleeunit.main()
}

pub fn encode_int_test() {
  // positive fixints
  encode_single(PackedInt(0))
  |> should.equal(<<0b0:1, 0:7>>)

  encode_single(PackedInt(1))
  |> should.equal(<<0b0:1, 1:7>>)

  encode_single(PackedInt(127))
  |> should.equal(<<0b0:1, 127:7>>)

  // negative fixints
  encode_single(PackedInt(-1))
  |> should.equal(<<0b111:3, 1:5>>)

  encode_single(PackedInt(-32))
  |> should.equal(<<0b111:3, 32:5>>)

  // uints
  encode_single(PackedInt(128))
  |> should.equal(<<0xcc, 128:8>>)

  encode_single(PackedInt(255))
  |> should.equal(<<0xcc, 255:8>>)

  encode_single(PackedInt(256))
  |> should.equal(<<0xcd, 256:16>>)

  encode_single(PackedInt(65535))
  |> should.equal(<<0xcd, 65535:16>>)

  encode_single(PackedInt(65536))
  |> should.equal(<<0xce, 65536:32>>)

  encode_single(PackedInt(4294967295))
  |> should.equal(<<0xce, 4294967295:32>>)

  encode_single(PackedInt(4294967296))
  |> should.equal(<<0xcf, 4294967296:64>>)

  encode_single(PackedInt(18446744073709551615))
  |> should.equal(<<0xcf, 18446744073709551615:64>>)

  // ints
  encode_single(PackedInt(-33))
  |> should.equal(<<0xd0, -33:8>>)

  encode_single(PackedInt(-128))
  |> should.equal(<<0xd0, -128:8>>)

  encode_single(PackedInt(-129))
  |> should.equal(<<0xd1, -129:16>>)

  encode_single(PackedInt(-32768))
  |> should.equal(<<0xd1, -32768:16>>)

  encode_single(PackedInt(-32769))
  |> should.equal(<<0xd2, -32769:32>>)

  encode_single(PackedInt(-2147483648))
  |> should.equal(<<0xd2, -2147483648:32>>)

  encode_single(PackedInt(-2147483649))
  |> should.equal(<<0xd3, -2147483649:64>>)

  encode_single(PackedInt(-9223372036854775808))
  |> should.equal(<<0xd3, -9223372036854775808:64>>)
}

pub fn encode_float_test() {
  // encode_single(types.Float(0.0))
  // |> should.equal(<<0xca, 0.0:float>>)
  encode_single(PackedFloat(0.0))
  |> should.equal(<<0xcb, 0.0:float>>)
}

pub fn encode_string_test() {
  encode_single(PackedString(""))
  |> should.equal(<<0b101:3, 0:5>>)

  encode_single(PackedString("a"))
  |> should.equal(<<0b101:3, 1:5, "a":utf8>>)

  encode_single(PackedString(string.repeat("a", min_fixstr_len)))
  |> should.equal(<<
    0b101:3,
    min_fixstr_len:5,
    string.repeat("a", min_fixstr_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", max_fixstr_len)))
  |> should.equal(<<
    0b101:3,
    max_fixstr_len:5,
    string.repeat("a", max_fixstr_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", min_str8_len)))
  |> should.equal(<<
    0xd9,
    min_str8_len:8,
    string.repeat("a", min_str8_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", max_str8_len)))
  |> should.equal(<<
    0xd9,
    max_str8_len:8,
    string.repeat("a", max_str8_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", min_str16_len)))
  |> should.equal(<<
    0xda,
    min_str16_len:16,
    string.repeat("a", min_str16_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", max_str16_len)))
  |> should.equal(<<
    0xda,
    max_str16_len:16,
    string.repeat("a", max_str16_len):utf8,
  >>)

  encode_single(PackedString(string.repeat("a", min_str32_len)))
  |> should.equal(<<
    0xdb,
    min_str32_len:32,
    string.repeat("a", min_str32_len):utf8,
  >>)
  // max_str32_len omitted for performance
}

pub fn encode_binary_test() {
  let encoded_fixture = fn(n) { <<0b1:size(n * 8)>> }
  let decoded_fixture = fn(n) { PackedBinary(<<0b1:size(n * 8)>>) }

  encode_single(decoded_fixture(min_bin8_len))
  |> should.equal(<<
    0xd9,
    min_bin8_len:8,
    encoded_fixture(min_bin8_len):bit_string,
  >>)

  encode_single(decoded_fixture(max_bin8_len))
  |> should.equal(<<
    0xd9,
    max_bin8_len:8,
    encoded_fixture(max_bin8_len):bit_string,
  >>)

  encode_single(decoded_fixture(min_bin16_len))
  |> should.equal(<<
    0xda,
    min_bin16_len:16,
    encoded_fixture(min_bin16_len):bit_string,
  >>)

  encode_single(decoded_fixture(max_bin16_len))
  |> should.equal(<<
    0xda,
    max_bin16_len:16,
    encoded_fixture(max_bin16_len):bit_string,
  >>)

  encode_single(decoded_fixture(min_bin32_len))
  |> should.equal(<<
    0xdb,
    min_bin32_len:32,
    encoded_fixture(min_bin32_len):bit_string,
  >>)
  // max_bin32_len omitted for performance
}

pub fn decode_int_test() {
  // positive fixints
  decode_single(<<0b0:1, 0b0000000:7>>)
  |> should.equal(PackedInt(0b0000000))

  decode_single(<<0b0:1, 0b0000001:7>>)
  |> should.equal(PackedInt(0b0000001))

  decode_single(<<0b0:1, 0b1000000:7>>)
  |> should.equal(PackedInt(0b1000000))

  decode_single(<<0b0:1, 0b1111111:7>>)
  |> should.equal(PackedInt(0b1111111))

  // negative fixints
  decode_single(<<0b111:3, 0b00000:5>>)
  |> should.equal(PackedInt(0 - 0b00000))

  decode_single(<<0b111:3, 0b00001:5>>)
  |> should.equal(PackedInt(0 - 0b00001))

  decode_single(<<0b111:3, 0b10000:5>>)
  |> should.equal(PackedInt(0 - 0b10000))

  decode_single(<<0b111:3, 0b11111:5>>)
  |> should.equal(PackedInt(0 - 0b11111))

  // uints
  decode_single(<<0xcc, min_uint8:8>>)
  |> should.equal(PackedInt(min_uint8))

  decode_single(<<0xcc, max_uint8:8>>)
  |> should.equal(PackedInt(max_uint8))

  decode_single(<<0xcd, min_uint16:16>>)
  |> should.equal(PackedInt(min_uint16))

  decode_single(<<0xcd, max_uint16:16>>)
  |> should.equal(PackedInt(max_uint16))

  decode_single(<<0xce, min_uint32:32>>)
  |> should.equal(PackedInt(min_uint32))

  decode_single(<<0xce, max_uint32:32>>)
  |> should.equal(PackedInt(max_uint32))

  decode_single(<<0xcf, min_uint64:64>>)
  |> should.equal(PackedInt(min_uint64))

  decode_single(<<0xcf, max_uint64:64>>)
  |> should.equal(PackedInt(max_uint64))

  // ints
  decode_single(<<0xd0, min_int8:8>>)
  |> should.equal(PackedInt(min_int8))

  decode_single(<<0xd0, max_int8:8>>)
  |> should.equal(PackedInt(max_int8))

  decode_single(<<0xd1, min_int16:16>>)
  |> should.equal(PackedInt(min_int16))

  decode_single(<<0xd1, max_int16:16>>)
  |> should.equal(PackedInt(max_int16))

  decode_single(<<0xd2, min_int32:32>>)
  |> should.equal(PackedInt(min_int32))

  decode_single(<<0xd2, max_int32:32>>)
  |> should.equal(PackedInt(max_int32))

  decode_single(<<0xd3, min_int64:64>>)
  |> should.equal(PackedInt(min_int64))

  decode_single(<<0xd3, max_int64:64>>)
  |> should.equal(PackedInt(max_int64))
}

pub fn decode_float_test() {
  // decode_single(<<0xca, 0.0:float>>)
  // |> should.equal(PackedFloat(0.0))
  decode_single(<<0xcb, 0.0:float>>)
  |> should.equal(PackedFloat(0.0))
}

pub fn decode_string_test() {
  let encoded_fixture = fn(n) { string.repeat("a", n) }
  let decoded_fixture = fn(n) { PackedString(encoded_fixture(n)) }

  decode_single(<<
    0b101:3,
    min_fixstr_len:5,
    encoded_fixture(min_fixstr_len):utf8,
  >>)
  |> should.equal(decoded_fixture(min_fixstr_len))

  decode_single(<<
    0b101:3,
    max_fixstr_len:5,
    encoded_fixture(max_fixstr_len):utf8,
  >>)
  |> should.equal(decoded_fixture(max_fixstr_len))

  decode_single(<<0xd9, min_str8_len:8, encoded_fixture(min_str8_len):utf8>>)
  |> should.equal(decoded_fixture(min_str8_len))

  decode_single(<<0xd9, max_str8_len:8, encoded_fixture(max_str8_len):utf8>>)
  |> should.equal(decoded_fixture(max_str8_len))

  decode_single(<<0xda, min_str16_len:16, encoded_fixture(min_str16_len):utf8>>)
  |> should.equal(decoded_fixture(min_str16_len))

  decode_single(<<0xda, max_str16_len:16, encoded_fixture(max_str16_len):utf8>>)
  |> should.equal(decoded_fixture(max_str16_len))

  decode_single(<<0xdb, min_str32_len:32, encoded_fixture(min_str32_len):utf8>>)
  |> should.equal(decoded_fixture(min_str32_len))
  // max_str32_len omitted for performance
}

pub fn decode_binary_test() {
  let encoded_fixture = fn(n) { <<0b1:size(n * 8)>> }
  let decoded_fixture = fn(n) { PackedBinary(<<0b1:size(n * 8)>>) }

  decode_single(<<
    0xc4,
    min_bin8_len:8,
    encoded_fixture(min_bin8_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_bin8_len))

  decode_single(<<
    0xc4,
    max_bin8_len:8,
    encoded_fixture(max_bin8_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(max_bin8_len))

  decode_single(<<
    0xc5,
    min_bin16_len:16,
    encoded_fixture(min_bin16_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_bin16_len))

  decode_single(<<
    0xc5,
    max_bin16_len:16,
    encoded_fixture(max_bin16_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(max_bin16_len))

  decode_single(<<
    0xc6,
    min_bin32_len:32,
    encoded_fixture(min_bin32_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_bin32_len))
  // max_bin32_len omitted for performance
}

pub fn decode_array_test() {
  let encoded_fixture = fn(n) { bit_string.concat(list.repeat(<<0:8>>, n)) }
  let decoded_fixture = fn(n) { PackedArray(list.repeat(PackedInt(0), n)) }

  decode_single(<<
    0b1001:4,
    min_fixarr_len:4,
    encoded_fixture(min_fixarr_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_fixarr_len))

  decode_single(<<
    0b1001:4,
    max_fixarr_len:4,
    encoded_fixture(max_fixarr_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(max_fixarr_len))

  decode_single(<<
    0xdc,
    min_arr16_len:16,
    encoded_fixture(min_arr16_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_arr16_len))

  decode_single(<<
    0xdc,
    max_arr16_len:16,
    encoded_fixture(max_arr16_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(max_arr16_len))

  decode_single(<<
    0xdd,
    min_arr32_len:32,
    encoded_fixture(min_arr32_len):bit_string,
  >>)
  |> should.equal(decoded_fixture(min_arr32_len))
  // max_arr32_len omitted for performance
}

pub fn decode_message_test() {
  decode_single(<<
    0x82, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3, 0xa6, 0x73, 0x63,
    0x68, 0x65, 0x6d, 0x61, 0x00,
  >>)
  |> should.equal(PackedMap([
    #(PackedString("compact"), PackedBool(True)),
    #(PackedString("schema"), PackedInt(0)),
  ]))
}
