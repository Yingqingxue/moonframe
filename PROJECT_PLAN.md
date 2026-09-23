# MoonFrame 项目申报书

## 基本信息

- **项目名称：** MoonFrame：MoonBit 增量分帧基础库
- **参赛者：** Yingqingxue（GitHub ID）
- **项目方向：** 新生态项目建设 / 通用协议与数据流基础库
- **GitHub：** https://github.com/Yingqingxue/moonframe
- **项目性质：** 原创项目

## 项目简介与生态定位

MoonFrame 把没有消息边界的字节流还原成独立消息，统一处理拆包、粘包、截断、恶意长度和意外损坏。MoonBit 已有 async Reader/Writer 和若干 Varint 实现，但应用仍需重复编写 framing 缓冲状态机。MoonFrame 位于 I/O 与上层协议之间：不绑定 socket 或文件，不与 `moonvar` 竞争整数编码，而是提供有资源上限、可独立测试的消息边界语义。

## 预期使用场景

1. **RPC 传输：** TCP 一次读取可能只含半条请求或多条请求；解码器按长度前缀逐条输出完整 payload，并保留尾部半帧。
2. **数据库协议：** 客户端限制单条响应及累计缓冲大小，在负载到齐前拒绝畸形或超限长度，避免无界内存增长。
3. **日志和文件记录：** 顺序读取长度分帧记录；文件尾部截断必须返回确定错误，可选 CRC-32 检测传输或落盘损坏。

## 核心功能范围

- 最多五字节、31 位有界 unsigned LEB128；
- 单帧、批量流与任意分片输入的增量解码；
- `NeedMore`、畸形 Varint、帧超限、缓冲超限等结构化错误；
- 可配置帧/缓冲预算、显式 `finish/reset`；
- 可选 IEEE CRC-32 受保护帧；
- CLI 示例、Wasm/Wasm-GC/JavaScript 测试和 CI。

## 技术路线、边界与验收产物

协议为 `uLEB128(payload_length) || payload`；受保护变体追加大端 CRC-32。解码器持有未消费字节，在完整头部后立即检查长度，并在复制输入前检查总缓冲预算。首版交付 MoonBit 库、README、协议说明、示例、边界测试、CI、Apache-2.0 许可证及 Mooncakes 包。首版不做 socket、TLS、压缩或认证；CRC-32 只检测意外损坏，不提供安全认证。

## 原创与参考说明

本项目未移植或复制其他仓库代码；LEB128 和 IEEE CRC-32 按公开格式实现。与已有 Varint 库相比，本项目的核心交付是增量 framing 状态机、资源边界、结束语义和错误模型。
