///|
/// Deterministic failures returned by frame parsing.
pub enum FrameError {
  NeedMore
  MalformedVarint
  FrameTooLarge(Int, Int)
}

///|
/// Prefix a payload with its unsigned LEB128 byte length.
pub fn encode_frame(payload : Bytes) -> Bytes {
  let header = encode_varint(payload.length())
  let output : Array[Byte] = []
  for byte in header {
    output.push(byte)
  }
  for byte in payload {
    output.push(byte)
  }
  Bytes::from_array(output)
}

///|
/// Decode one complete frame and report total bytes consumed.
pub fn decode_frame(
  data : Bytes,
  max_frame_size? : Int = 1048576,
) -> Result[(Bytes, Int), FrameError] {
  let (length, header_size) = match decode_varint(data) {
    Some(parsed) => parsed
    None => {
      if data.length() >= 5 && (data[4].to_int() & 0x80) != 0 {
        return Err(MalformedVarint)
      }
      return Err(NeedMore)
    }
  }
  if length > max_frame_size {
    return Err(FrameTooLarge(length, max_frame_size))
  }
  let end = header_size + length
  if data.length() < end {
    return Err(NeedMore)
  }
  Ok((data[header_size:end].to_owned(), end))
}
