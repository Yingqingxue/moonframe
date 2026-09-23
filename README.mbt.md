# MoonFrame

MoonFrame is a pure-MoonBit framing toolkit for protocols that run over
arbitrary byte streams. It separates message boundaries from transport I/O,
handles fragmented and coalesced input, enforces resource limits before
payload allocation, and can attach CRC-32 corruption detection.

## Highlights

- Unsigned LEB128 length prefixes with a five-byte bound
- One-shot and incremental decoders
- Correct handling of one-byte fragments and multiple frames per chunk
- Configurable maximum frame and buffered-input sizes
- Explicit truncated, malformed, oversized, and checksum failures
- Optional IEEE CRC-32 protected frames
- Decoder reset at application-defined resynchronization boundaries
- Cross-backend CI for Wasm, Wasm-GC, and JavaScript

## Run

```bash
moon test --deny-warn
moon run cmd/main
```

## Library example

```mbt check
///|
test {
  let decoder = @moonframe.Decoder::new(max_frame_size=4096)
  let wire = @moonframe.encode_frame(b"hello")
  match decoder.feed(wire) {
    Ok(frames) => assert_true(frames[0] == b"hello")
    Err(_) => fail("valid frame")
  }
}
```

## Protocol

The base wire format is `uLEB128(payload_length) || payload`. A checked frame
uses `uLEB128(payload_length + 4) || payload || crc32_be`. The length prefix is
limited to five bytes and the decoder checks the configured payload limit as
soon as the prefix is complete.

MoonFrame is not a socket or filesystem library. It is designed to compose
with MoonBit async readers, files, WebSockets, RPC transports, and parsers
without forcing any particular I/O runtime.

Licensed under Apache-2.0.
