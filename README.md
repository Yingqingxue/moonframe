# MoonFrame

Backend-neutral, pure-MoonBit framing primitives with bounded LEB128 lengths,
incremental fragmented/coalesced decoding, explicit resource limits, and an
optional CRC-32 protected wire format.

```bash
moon test --deny-warn
moon run cmd/main
```

See [the type-checked protocol guide](README.mbt.md) for API examples and wire
format details, and [the Chinese hackathon plan](PROJECT_PLAN.md) for milestones,
risks, and acceptance criteria.

Apache-2.0 licensed.
