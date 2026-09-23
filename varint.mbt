///|
/// Encode a non-negative length as unsigned LEB128 (maximum 31 bits).
pub fn encode_varint(value : Int) -> Bytes {
  if value < 0 {
    abort("varint value must be non-negative")
  }
  let output : Array[Byte] = []
  let mut remaining = value
  for _i = 0; remaining > 0x7f; _i = _i + 1 {
    let low = remaining & 0x7f
    remaining = remaining >> 7
    output.push((low | 0x80).to_byte())
  }
  output.push((remaining & 0x7f).to_byte())
  Bytes::from_array(output)
}

///|
/// Decode one unsigned LEB128 value, returning value and bytes consumed.
pub fn decode_varint(data : Bytes, offset? : Int = 0) -> (Int, Int)? {
  let mut value = 0
  for i = 0; i < 5; i = i + 1 {
    let index = offset + i
    if index >= data.length() {
      return None
    }
    let byte = data[index].to_int()
    value = value | ((byte & 0x7f) << (i * 7))
    if (byte & 0x80) == 0 {
      return Some((value, i + 1))
    }
  }
  None
}
