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
