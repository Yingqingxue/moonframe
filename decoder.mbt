///|
/// Stateful decoder accepting arbitrarily fragmented byte chunks.
pub struct Decoder {
  buffer : Array[Byte]
  max_frame_size : Int
}

///|
pub fn Decoder::new(max_frame_size? : Int = 1048576) -> Decoder {
  Decoder::{ buffer: [], max_frame_size, }
}

///|
/// Number of bytes retained while waiting for a complete frame.
pub fn Decoder::buffered(self : Decoder) -> Int {
  self.buffer.length()
}

///|
/// Feed any chunk size and return every complete frame now available.
pub fn Decoder::feed(
  self : Decoder,
  chunk : Bytes,
) -> Result[Array[Bytes], FrameError] {
  for byte in chunk {
    self.buffer.push(byte)
  }
  let frames : Array[Bytes] = []
  for _step = 0; self.buffer.length() > 0; _step = _step + 1 {
    let snapshot = Bytes::from_array(self.buffer)
    match decode_frame(snapshot, max_frame_size=self.max_frame_size) {
      Ok((payload, consumed)) => {
        frames.push(payload)
        self.buffer.clear()
        for byte in snapshot[consumed:] {
          self.buffer.push(byte)
        }
      }
      Err(NeedMore) => return Ok(frames)
      Err(error) => return Err(error)
    }
  }
  Ok(frames)
}

///|
/// Signal end-of-input. A partial header or payload is an explicit error.
pub fn Decoder::finish(self : Decoder) -> Result[Unit, FrameError] {
  if self.buffer.length() == 0 {
    Ok(())
  } else {
    Err(NeedMore)
  }
}
