import msgpack/encode.{encode}
import msgpack/decode.{DecodeError, decode}
import msgpack/types.{PackedValue}

pub fn pack(message: List(PackedValue)) -> Result(BitString, Nil) {
  Ok(encode(message))
}

pub fn unpack(message: BitString) -> Result(List(PackedValue), DecodeError) {
  decode(message)
}
