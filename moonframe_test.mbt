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
