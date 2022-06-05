import gleeunit
import gleeunit/should
import gleam/string
import gleam/list
import gleam/bit_string
import msgpack/encode.{encode}
import msgpack/decode.{decode}
import msgpack/types.{
  PackedArray, PackedBinary, PackedBool, PackedExt, PackedFloat, PackedInt, PackedMap,
  PackedNil, PackedString, PackedValue, max_arr16_len, max_bin08_len, max_bin16_len,
  max_fixarr_len, max_fixstr_len, max_int08, max_int16, max_int32, max_int64, max_str08_len,
  max_str16_len, max_uint08, max_uint16, max_uint32, max_uint64, min_arr16_len, min_arr32_len,
  min_bin08_len, min_bin16_len, min_bin32_len, min_fixarr_len, min_fixstr_len, min_int08,
  min_int16, min_int32, min_int64, min_str08_len, min_str16_len, min_str32_len, min_uint08,
  min_uint16, min_uint32, min_uint64,
}

pub fn main() {
  gleeunit.main()
}

fn decode_single(bytes: BitString) -> PackedValue {
  assert Ok(values) = decode(bytes)
  assert Ok(first) = list.first(values)
  first
}

fn encode_single(value: PackedValue) -> BitString {
  encode([value])
}

fn encode_test(value: PackedValue, bytes: BitString) {
  should.equal(encode_single(value), bytes)
}

fn decode_test(bytes: BitString, value: PackedValue) {
  should.equal(decode_single(bytes), value)
}

pub fn encode_int_test() {
  // positive fixints
  encode_test(PackedInt(0), <<0b0:1, 0:7>>)

  encode_test(PackedInt(1), <<0b0:1, 1:7>>)

  encode_test(PackedInt(127), <<0b0:1, 127:7>>)

  // negative fixints
  encode_test(PackedInt(-1), <<0b111:3, 1:5>>)

  encode_test(PackedInt(-32), <<0b111:3, 32:5>>)

  // uints
  encode_test(PackedInt(128), <<0xcc, 128:8>>)

  encode_test(PackedInt(255), <<0xcc, 255:8>>)

  encode_test(PackedInt(256), <<0xcd, 256:16>>)

  encode_test(PackedInt(65535), <<0xcd, 65535:16>>)

  encode_test(PackedInt(65536), <<0xce, 65536:32>>)

  encode_test(PackedInt(4294967295), <<0xce, 4294967295:32>>)

  encode_test(PackedInt(4294967296), <<0xcf, 4294967296:64>>)

  encode_test(
    PackedInt(18446744073709551615),
    <<0xcf, 18446744073709551615:64>>,
  )

  // ints
  encode_test(PackedInt(-33), <<0xd0, -33:8>>)

  encode_test(PackedInt(-128), <<0xd0, -128:8>>)

  encode_test(PackedInt(-129), <<0xd1, -129:16>>)

  encode_test(PackedInt(-32768), <<0xd1, -32768:16>>)

  encode_test(PackedInt(-32769), <<0xd2, -32769:32>>)

  encode_test(PackedInt(-2147483648), <<0xd2, -2147483648:32>>)

  encode_test(PackedInt(-2147483649), <<0xd3, -2147483649:64>>)

  encode_test(
    PackedInt(-9223372036854775808),
    <<0xd3, -9223372036854775808:64>>,
  )
}

pub fn encode_float_test() {
  // encode_test(types.Float(0.0),<<0xca, 0.0:float>>)
  encode_test(PackedFloat(0.0), <<0xcb, 0.0:float>>)
}

pub fn encode_string_test() {
  let fixture = fn(n) { string.repeat("a", n) }

  encode_test(
    PackedString(fixture(min_fixstr_len)),
    <<0b101:3, min_fixstr_len:5, fixture(min_fixstr_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(max_fixstr_len)),
    <<0b101:3, max_fixstr_len:5, fixture(max_fixstr_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(min_str08_len)),
    <<0xd9, min_str08_len:8, fixture(min_str08_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(max_str08_len)),
    <<0xd9, max_str08_len:8, fixture(max_str08_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(min_str16_len)),
    <<0xda, min_str16_len:16, fixture(min_str16_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(max_str16_len)),
    <<0xda, max_str16_len:16, fixture(max_str16_len):utf8>>,
  )

  encode_test(
    PackedString(fixture(min_str32_len)),
    <<0xdb, min_str32_len:32, fixture(min_str32_len):utf8>>,
  )
  // max_str32_len omitted for performance
}

pub fn encode_binary_test() {
  let fixture = fn(n) { <<0b1:size(n * 8)>> }

  encode_test(
    PackedBinary(fixture(min_bin08_len)),
    <<0xd9, min_bin08_len:08, fixture(min_bin08_len):bit_string>>,
  )

  encode_test(
    PackedBinary(fixture(max_bin08_len)),
    <<0xd9, max_bin08_len:08, fixture(max_bin08_len):bit_string>>,
  )

  encode_test(
    PackedBinary(fixture(min_bin16_len)),
    <<0xda, min_bin16_len:16, fixture(min_bin16_len):bit_string>>,
  )

  encode_test(
    PackedBinary(fixture(max_bin16_len)),
    <<0xda, max_bin16_len:16, fixture(max_bin16_len):bit_string>>,
  )

  encode_test(
    PackedBinary(fixture(min_bin32_len)),
    <<0xdb, min_bin32_len:32, fixture(min_bin32_len):bit_string>>,
  )
  // max_bin32_len omitted for performance
}

pub fn encode_message_test() {
  encode_test(
    PackedMap([
      #(PackedString("compact"), PackedBool(True)),
      #(PackedString("schema"), PackedInt(0)),
    ]),
    <<
      0x82, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3, 0xa6, 0x73, 0x63,
      0x68, 0x65, 0x6d, 0x61, 0x00,
    >>,
  )
}

pub fn decode_nil_test() {
  decode_test(<<0xc0>>, PackedNil)
}

pub fn decode_bool_test() {
  decode_test(<<0xc2>>, PackedBool(False))
  decode_test(<<0xc3>>, PackedBool(True))
}

pub fn decode_int_test() {
  // positive fixints
  decode_test(<<0b0:1, 0b0000000:7>>, PackedInt(0b0000000))
  decode_test(<<0b0:1, 0b0000001:7>>, PackedInt(0b0000001))
  decode_test(<<0b0:1, 0b1000000:7>>, PackedInt(0b1000000))
  decode_test(<<0b0:1, 0b1111111:7>>, PackedInt(0b1111111))

  // negative fixints
  decode_test(<<0b111:3, 0b00000:5>>, PackedInt(0 - 0b00000))
  decode_test(<<0b111:3, 0b00001:5>>, PackedInt(0 - 0b00001))
  decode_test(<<0b111:3, 0b10000:5>>, PackedInt(0 - 0b10000))
  decode_test(<<0b111:3, 0b11111:5>>, PackedInt(0 - 0b11111))

  // uints
  decode_test(<<0xcc, min_uint08:08>>, PackedInt(min_uint08))
  decode_test(<<0xcc, max_uint08:08>>, PackedInt(max_uint08))
  decode_test(<<0xcd, min_uint16:16>>, PackedInt(min_uint16))
  decode_test(<<0xcd, max_uint16:16>>, PackedInt(max_uint16))
  decode_test(<<0xce, min_uint32:32>>, PackedInt(min_uint32))
  decode_test(<<0xce, max_uint32:32>>, PackedInt(max_uint32))
  decode_test(<<0xcf, min_uint64:64>>, PackedInt(min_uint64))
  decode_test(<<0xcf, max_uint64:64>>, PackedInt(max_uint64))

  // ints
  decode_test(<<0xd0, min_int08:08>>, PackedInt(min_int08))
  decode_test(<<0xd0, max_int08:08>>, PackedInt(max_int08))
  decode_test(<<0xd1, min_int16:16>>, PackedInt(min_int16))
  decode_test(<<0xd1, max_int16:16>>, PackedInt(max_int16))
  decode_test(<<0xd2, min_int32:32>>, PackedInt(min_int32))
  decode_test(<<0xd2, max_int32:32>>, PackedInt(max_int32))
  decode_test(<<0xd3, min_int64:64>>, PackedInt(min_int64))
  decode_test(<<0xd3, max_int64:64>>, PackedInt(max_int64))
}

pub fn decode_float_test() {
  // decode_test(<<0xca, 0.0:float>>, PackedFloat(0.0))
  decode_test(<<0xcb, 0.0:float>>, PackedFloat(0.0))
}

pub fn decode_string_test() {
  let fixture = fn(n) { string.repeat("a", n) }

  decode_test(
    <<0b101:3, min_fixstr_len:5, fixture(min_fixstr_len):utf8>>,
    PackedString(fixture(min_fixstr_len)),
  )

  decode_test(
    <<0b101:3, max_fixstr_len:5, fixture(max_fixstr_len):utf8>>,
    PackedString(fixture(max_fixstr_len)),
  )

  decode_test(
    <<0xd9, min_str08_len:08, fixture(min_str08_len):utf8>>,
    PackedString(fixture(min_str08_len)),
  )

  decode_test(
    <<0xd9, max_str08_len:08, fixture(max_str08_len):utf8>>,
    PackedString(fixture(max_str08_len)),
  )

  decode_test(
    <<0xda, min_str16_len:16, fixture(min_str16_len):utf8>>,
    PackedString(fixture(min_str16_len)),
  )

  decode_test(
    <<0xda, max_str16_len:16, fixture(max_str16_len):utf8>>,
    PackedString(fixture(max_str16_len)),
  )

  decode_test(
    <<0xdb, min_str32_len:32, fixture(min_str32_len):utf8>>,
    PackedString(fixture(min_str32_len)),
  )
  // max_str32_len omitted for performance
}

pub fn decode_binary_test() {
  let fixture = fn(n) { <<0b1:size(n * 8)>> }

  decode_test(
    <<0xc4, min_bin08_len:08, fixture(min_bin08_len):bit_string>>,
    PackedBinary(fixture(min_bin08_len)),
  )

  decode_test(
    <<0xc4, max_bin08_len:08, fixture(max_bin08_len):bit_string>>,
    PackedBinary(fixture(max_bin08_len)),
  )

  decode_test(
    <<0xc5, min_bin16_len:16, fixture(min_bin16_len):bit_string>>,
    PackedBinary(fixture(min_bin16_len)),
  )

  decode_test(
    <<0xc5, max_bin16_len:16, fixture(max_bin16_len):bit_string>>,
    PackedBinary(fixture(max_bin16_len)),
  )

  decode_test(
    <<0xc6, min_bin32_len:32, fixture(min_bin32_len):bit_string>>,
    PackedBinary(fixture(min_bin32_len)),
  )
  // max_bin32_len omitted for performance
}

pub fn decode_array_test() {
  let encoded_fixture = fn(n) { bit_string.concat(list.repeat(<<0:8>>, n)) }
  let decoded_fixture = fn(n) { list.repeat(PackedInt(0), n) }

  decode_test(
    <<0b1001:4, min_fixarr_len:4, encoded_fixture(min_fixarr_len):bit_string>>,
    PackedArray(decoded_fixture(min_fixarr_len)),
  )

  decode_test(
    <<0b1001:4, max_fixarr_len:4, encoded_fixture(max_fixarr_len):bit_string>>,
    PackedArray(decoded_fixture(max_fixarr_len)),
  )

  decode_test(
    <<0xdc, min_arr16_len:16, encoded_fixture(min_arr16_len):bit_string>>,
    PackedArray(decoded_fixture(min_arr16_len)),
  )

  decode_test(
    <<0xdc, max_arr16_len:16, encoded_fixture(max_arr16_len):bit_string>>,
    PackedArray(decoded_fixture(max_arr16_len)),
  )

  decode_test(
    <<0xdd, min_arr32_len:32, encoded_fixture(min_arr32_len):bit_string>>,
    PackedArray(decoded_fixture(min_arr32_len)),
  )
  // max_arr32_len omitted for performance
}

pub fn decode_ext_test() {
  let ext_type = 1

  let fixture = fn(n) { bit_string.concat(list.repeat(<<0:8>>, n)) }

  decode_test(
    <<0xd4, ext_type:8, fixture(1):bit_string>>,
    PackedExt(ext_type, fixture(1)),
  )

  decode_test(
    <<0xd5, ext_type:8, fixture(2):bit_string>>,
    PackedExt(ext_type, fixture(2)),
  )

  decode_test(
    <<0xd6, ext_type:8, fixture(4):bit_string>>,
    PackedExt(ext_type, fixture(4)),
  )

  decode_test(
    <<0xd7, ext_type:8, fixture(8):bit_string>>,
    PackedExt(ext_type, fixture(8)),
  )

  decode_test(
    <<0xd8, ext_type:8, fixture(16):bit_string>>,
    PackedExt(ext_type, fixture(16)),
  )

  decode_test(
    <<0xc7, min_bin08_len:08, ext_type:8, fixture(min_bin08_len):bit_string>>,
    PackedExt(ext_type, fixture(min_bin08_len)),
  )

  decode_test(
    <<0xc7, max_bin08_len:08, ext_type:8, fixture(max_bin08_len):bit_string>>,
    PackedExt(ext_type, fixture(max_bin08_len)),
  )

  decode_test(
    <<0xc8, min_bin16_len:16, ext_type:8, fixture(min_bin16_len):bit_string>>,
    PackedExt(ext_type, fixture(min_bin16_len)),
  )

  decode_test(
    <<0xc8, max_bin16_len:16, ext_type:8, fixture(max_bin16_len):bit_string>>,
    PackedExt(ext_type, fixture(max_bin16_len)),
  )

  decode_test(
    <<0xc9, min_bin32_len:32, ext_type:8, fixture(min_bin32_len):bit_string>>,
    PackedExt(ext_type, fixture(min_bin32_len)),
  )
}

pub fn decode_message_test() {
  decode_test(
    <<
      0x82, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3, 0xa6, 0x73, 0x63,
      0x68, 0x65, 0x6d, 0x61, 0x00,
    >>,
    PackedMap([
      #(PackedString("compact"), PackedBool(True)),
      #(PackedString("schema"), PackedInt(0)),
    ]),
  )
}
