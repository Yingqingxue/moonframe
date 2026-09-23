# MoonFrame 项目计划书（方向 5：Streaming / Framing 基础库）

## 一、项目概述

MoonFrame 是与具体 I/O 后端解耦的 MoonBit 增量分帧库。它把任意字节流可靠地还原为消息边界，正确处理网络与文件读取中的拆包、粘包、截断、恶意长度和数据损坏，供 RPC、数据库协议、消息队列、文件格式和自定义网络协议复用。

## 二、真实需求与差异化

TCP、文件和异步 Reader 只提供字节，不保留消息边界；每个协议自行重写长度前缀和缓冲状态机会产生边界错误与内存风险。MoonBit 已有成熟的 async Reader/Writer，因此 MoonFrame 不再造 I/O 层，而是补充可独立测试的 framing 状态机：有界长度头、增量消费、多帧输出、明确结束语义、资源上限和可选校验。

## 三、已完成 MVP（可验收）

- 非负整数的有界 unsigned LEB128 编解码；
- `uLEB128(length) || payload` 单帧与批量流格式；
- 支持任意拆分输入的 `Decoder::feed`，一次返回零到多帧；
- `finish` 明确报告截断，不静默丢弃半帧；
- 头部完成后立即执行最大帧长度检查；
- 区分 `NeedMore`、畸形 Varint、超限、缺少校验和、校验失败；
- IEEE CRC-32 标准向量及可选受保护帧；
- 错误后在应用确认边界时显式 `reset`；
- CLI 示例、README、Apache-2.0 许可证与跨后端 CI。

## 四、技术方案

基础协议使用最多五字节的 unsigned LEB128 表示负载长度。增量解码器保留未消费字节；每次输入后循环解析完整帧，遇到半帧即保留状态，遇到非法头或超限立即返回结构化错误。受保护变体在负载后附加大端 CRC-32。核心只依赖 `Bytes`/`Array`，上层可接 async Reader、socket、WebSocket、文件或内存数据。

## 五、9 月 23—30 日计划

1. 9 月 23 日：公开 MVP、测试、README、计划书和连续提交记录；
2. 9 月 24 日：减少缓冲区复制，增加环形缓冲/游标实现；
3. 9 月 25 日：增加固定 32 位长度、定界符和 magic-header 策略；
4. 9 月 26 日：增加属性测试、随机分片测试与模糊测试种子；
5. 9 月 27—28 日：对接 `moonbitlang/async` Reader/Writer 适配层；
6. 9 月 29 日：基准、演示、Mooncakes 发布准备和文档校对；
7. 9 月 30 日：验收提交并冻结 `v0.1.0`。

## 六、验收指标

- 同一帧按任意字节位置拆分，输出均与一次性解码一致；
- 同一输入包含多帧时按顺序完整输出；
- 超限长度在完整负载到达前被拒绝；
- 截断、畸形头、CRC 篡改均产生确定错误；
- `moon test --deny-warn` 通过，README 示例可直接运行；
- 公开仓库保留 commits、Issue/里程碑与变更记录。

## 七、风险与控制

最大风险是范围过宽、与 async I/O 职责重叠，以及首版缓冲复制影响吞吐。控制方式是把核心边界限定为“字节到帧”，I/O 适配放独立包；首版优先语义正确和跨后端一致，基准后再替换内部缓冲；CRC-32 只用于意外损坏检测，文档明确它不提供认证与抗篡改安全。

## 八、长期路线

`v0.2` 增加零拷贝视图和环形缓冲，`v0.3` 增加多种 framing 策略与 async 适配，`v0.4` 增加背压/预算接口、模糊测试语料和协议组合器，最终作为 MoonBit RPC、数据库和文件格式实现的共享底层组件。

## 九、信息来源

- [2026 MoonBit 黑客松官方页面](https://moonbitlang.github.io/Hackathon2026/)：公开仓库、持续开发、README、测试和可运行成果要求；
- [MoonBit 官方包管理文档](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html)：项目、测试与发布结构；
- [MoonBit async I/O 文档](https://skills.mooncakes.io/docs/moonbitlang/async%400.22.0/io)：用于划清 Reader/Writer 与 framing 状态机职责；
- 用户提供的《推荐(1).txt》：方向 5 的初始选题、适用场景与路线建议。
