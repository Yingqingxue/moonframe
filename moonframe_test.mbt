///|
test "varint boundary round trips" {
  for value in [0, 1, 127, 128, 16384, 1048576] {
    let encoded = @moonframe.encode_varint(value)
    match @moonframe.decode_varint(encoded) {
      Some((decoded, consumed)) => {
        inspect(decoded == value, content="true")
        inspect(consumed == encoded.length(), content="true")
      }
      None => fail("encoded varint must decode")
    }
  }
}

///|
test "single frame round trip" {
  let encoded = @moonframe.encode_frame(b"hello")
  match @moonframe.decode_frame(encoded) {
    Ok((payload, consumed)) => {
      inspect(payload == b"hello", content="true")
      inspect(consumed == encoded.length(), content="true")
    }
    Err(_) => fail("complete frame must decode")
  }
}

///|
test "frame size limit is enforced before allocation" {
  match @moonframe.decode_frame(b"\x08abcdefgh", max_frame_size=4) {
    Err(@moonframe.FrameTooLarge(actual, limit)) => {
      inspect(actual, content="8")
      inspect(limit, content="4")
    }
    _ => fail("oversized frame must be rejected")
  }
}

///|
test "incremental decoder tolerates one-byte chunks" {
  let decoder = @moonframe.Decoder::new()
  let encoded = @moonframe.encode_frame(b"fragmented")
  let output : Array[Bytes] = []
  for byte in encoded {
    match decoder.feed(Bytes::from_array([byte])) {
      Ok(frames) =>
        for frame in frames {
          output.push(frame)
        }
      Err(_) => fail("valid fragments must not fail")
    }
  }
  inspect(output.length(), content="1")
  inspect(output[0] == b"fragmented", content="true")
  inspect(decoder.buffered(), content="0")
}

///|
test "incremental decoder emits multiple coalesced frames" {
  let first = @moonframe.encode_frame(b"a")
  let second = @moonframe.encode_frame(b"bc")
  let joined : Array[Byte] = []
  for byte in first {
    joined.push(byte)
  }
  for byte in second {
    joined.push(byte)
  }
  let decoder = @moonframe.Decoder::new()
  match decoder.feed(Bytes::from_array(joined)) {
    Ok(frames) => {
      inspect(frames.length(), content="2")
      inspect(frames[0] == b"a", content="true")
      inspect(frames[1] == b"bc", content="true")
    }
    Err(_) => fail("coalesced frames must decode")
  }
}

///|
test "finite stream helper rejects trailing partial frame" {
  let stream = @moonframe.encode_frames([b"one", b"two", b"three"])
  match @moonframe.decode_all(stream) {
    Ok(frames) => inspect(frames.length(), content="3")
    Err(_) => fail("complete finite stream must decode")
  }
  match @moonframe.decode_all(b"\x05abc") {
    Err(@moonframe.NeedMore) => ()
    _ => fail("truncated payload must be explicit")
  }
}

///|
test "CRC-32 standard vector and checked frame" {
  inspect(@moonframe.crc32(b"123456789") == 0xcbf43926U, content="true")
  let encoded = @moonframe.encode_checked_frame(b"protected")
  match @moonframe.decode_checked_frame(encoded) {
    Ok((payload, _)) => inspect(payload == b"protected", content="true")
    Err(_) => fail("untampered checksum must pass")
  }
  let tampered = encoded.to_array()
  tampered[2] = (tampered[2].to_int() ^ 1).to_byte()
  match @moonframe.decode_checked_frame(Bytes::from_array(tampered)) {
    Err(@moonframe.ChecksumMismatch(_, _)) => ()
    _ => fail("tampering must be detected")
  }
}

///|
test "decoder can recover at an application-defined boundary" {
  let decoder = @moonframe.Decoder::new(max_frame_size=3)
  match decoder.feed(@moonframe.encode_frame(b"toolong")) {
    Err(@moonframe.FrameTooLarge(_, _)) => ()
    _ => fail("limit must reject oversized input")
  }
  inspect(decoder.buffered() > 0, content="true")
  decoder.reset()
  match decoder.feed(@moonframe.encode_frame(b"ok")) {
    Ok(frames) => inspect(frames[0] == b"ok", content="true")
    Err(_) => fail("decoder must be reusable after reset")
  }
}

///|
test "malformed 31-bit varints are rejected" {
  match @moonframe.decode_frame(b"\xff\xff\xff\xff\x0f") {
    Err(@moonframe.MalformedVarint) => ()
    _ => fail("overflowing fifth varint byte must be rejected")
  }
}

///|
test "incremental decoder enforces a total buffer budget" {
  let decoder = @moonframe.Decoder::new(max_frame_size=8, max_buffer_size=6)
  match decoder.feed(b"\x08abcdef") {
    Err(@moonframe.BufferLimitExceeded(actual, limit)) => {
      inspect(actual, content="7")
      inspect(limit, content="6")
      inspect(decoder.buffered(), content="0")
    }
    _ => fail("oversized buffered input must be rejected before copying")
  }
}
