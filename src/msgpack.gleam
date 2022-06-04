import gleam/io
import msgpack/encode.{encode}
import msgpack/decode.{decode}
import msgpack/types.{PackedValue}

pub fn pack(message: List(PackedValue)) -> Result(BitString, Nil) {
  Ok(encode(message))
}

pub fn unpack(message: BitString) -> Result(List(PackedValue), Nil) {
  Ok(decode(message))
}
