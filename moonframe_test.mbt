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
