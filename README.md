# MoonFrame

MoonFrame 是纯 MoonBit 的增量分帧基础库。它把任意字节流恢复为消息边界，正确处理拆包、粘包、截断、畸形长度、资源超限和意外损坏，可用于 RPC、数据库协议、消息系统和文件记录格式。

## 当前能力

- 最多五字节、31 位有界 unsigned LEB128
- 单帧、批量流及任意分片输入的增量解码
- 帧大小与累计缓冲双重预算
- 明确的截断、畸形、超限及校验错误
- 可选 IEEE CRC-32 受保护帧
- Wasm、Wasm-GC、JavaScript 三后端 CI

## 安装与运行

当前可从源码运行；发布 Mooncakes 后可使用 `moon add Yingqingxue/moonframe`。

```bash
git clone https://github.com/Yingqingxue/moonframe.git
cd moonframe
moon check --deny-warn
moon build --deny-warn
moon test --deny-warn
moon run cmd/main
```

## 最小使用示例

```moonbit
let decoder = @moonframe.Decoder::new(max_frame_size=4096)
let wire = @moonframe.encode_frame(b"hello")
match decoder.feed(wire) {
  Ok(frames) => assert_true(frames[0] == b"hello")
  Err(_) => fail("valid frame")
}
```

## 协议与边界

基础格式为 `uLEB128(payload_length) || payload`；校验格式在 payload 后追加大端 CRC-32。CRC-32 只能检测意外损坏，不能替代认证或加密。项目不实现 socket、TLS、压缩和具体异步运行时。

更多可类型检查的示例见 [README.mbt.md](README.mbt.md)，报名材料见 [PROJECT_PLAN.md](PROJECT_PLAN.md)，版本记录见 [CHANGELOG.md](CHANGELOG.md)。

Apache-2.0 licensed.
