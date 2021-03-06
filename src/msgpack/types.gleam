pub const min_pos_fixint = 0

pub const max_pos_fixint = 127

pub const min_neg_fixint = -32

pub const max_neg_fixint = -1

pub const min_uint08 = 0

pub const max_uint08 = 255

pub const min_uint16 = 256

pub const max_uint16 = 65535

pub const min_uint32 = 65536

pub const max_uint32 = 4294967295

pub const min_uint64 = 4294967296

pub const max_uint64 = 18446744073709551615

pub const min_int08 = -128

pub const max_int08 = 127

pub const min_int16 = -32768

pub const max_int16 = 32767

pub const min_int32 = -2147483648

pub const max_int32 = 2147483647

pub const min_int64 = -9223372036854775808

pub const max_int64 = 9223372036854775807

pub const min_fixstr_len = 0

pub const max_fixstr_len = 31

pub const min_str08_len = 32

pub const max_str08_len = 255

pub const min_str16_len = 256

pub const max_str16_len = 65535

pub const min_str32_len = 65536

pub const max_str32_len = 4294967295

pub const min_bin08_len = 0

pub const max_bin08_len = 255

pub const min_bin16_len = 256

pub const max_bin16_len = 65535

pub const min_bin32_len = 65536

pub const max_bin32_len = 4294967295

pub const min_fixarr_len = 0

pub const max_fixarr_len = 15

pub const min_arr16_len = 16

pub const max_arr16_len = 65535

pub const min_arr32_len = 65536

pub const max_arr32_len = 4294967295

pub const max_fixmap_len = 15

pub const max_map16_len = 65535

pub const max_map32_len = 4294967295

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
