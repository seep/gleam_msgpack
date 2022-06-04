import gleam/map

// fixint

pub const min_positive_fixint = 0

pub const max_positive_fixint = 127

pub const min_negative_fixint = -32

pub const max_negative_fixint = -1

// uint

pub const min_uint8 = 0

pub const max_uint8 = 255

pub const min_uint16 = 256

pub const max_uint16 = 65535

pub const min_uint32 = 65536

pub const max_uint32 = 4294967295

pub const min_uint64 = 4294967296

pub const max_uint64 = 18446744073709551615

// int

pub const min_int8 = -128

pub const max_int8 = 127

pub const min_int16 = -32768

pub const max_int16 = 32767

pub const min_int32 = -2147483648

pub const max_int32 = 2147483647

pub const min_int64 = -9223372036854775808

pub const max_int64 = 9223372036854775807

// str

pub const min_fixstr_len = 0

pub const max_fixstr_len = 31

pub const min_str8_len = 32

pub const max_str8_len = 255

pub const min_str16_len = 256

pub const max_str16_len = 65535

pub const min_str32_len = 65536

pub const max_str32_len = 4294967295

// bin

pub const min_bin8_len = 0

pub const max_bin8_len = 255

pub const min_bin16_len = 256

pub const max_bin16_len = 65535

pub const min_bin32_len = 65536

pub const max_bin32_len = 4294967295

// arr

pub const min_fixarr_len = 0

pub const max_fixarr_len = 15

pub const min_arr16_len = 16

pub const max_arr16_len = 65535

pub const min_arr32_len = 65536

pub const max_arr32_len = 4294967295

pub type PackedValue {
  PackedNil
  PackedInt(Int)
  PackedBool(Bool)
  PackedFloat(Float)
  PackedString(String)
  PackedBinary(BitString)
  PackedArray(List(PackedValue))
  PackedMap(List(PackedMapEntry))
  PackedExt(ext_type: Int, ext_data: BitString)
}

pub type PackedMapEntry =
  #(PackedValue, PackedValue)
