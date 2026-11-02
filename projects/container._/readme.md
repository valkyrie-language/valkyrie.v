# container._

`container._` 是容器生态的顶层 workspace：`container` 核心合同 + OCI / Docker / k8s 规范化落地。

## 组成

- `container`：核心合同——内容寻址（digest + 算法族注册）、`ContentStore`、`Descriptor`、media 注册表、`Layer`/层链、`Image`/`ImageConfig`、`Reference`、`Registry` 合同、运行时模型、失败模型（硬失败）、conformance 套件
- `container.oci`：OCI image-spec 规范化落地（spec 字段校验、schema 细节），通用类型复用核心
- `docker`：Docker 复刻（Dockerfile 解析、层构建），复用核心，与 oci 走同一套 conformance
- 规划中：`registry` 客户端（host capability 单列）、k8s 适配

## 原则

- 能用 Valkyrie 写的逻辑不塞进 nyar 编译器硬编码
- 格式解析走 `std.data` 合同，不自带 JSON/tar 解析器
- 摘要计算走 `std.data.digest`（sha256/sha512），压缩/解包走 `std.data.binary.codec`
- 容器侧失败是硬失败，走语言错误通道（`ContainerFailure` 分类码表），区别于 `std.data` 容许式诊断
- 缺底层能力的操作返回结构化失败，不硬编码、不 fallback

## 当前状态

- `container`：核心合同 + 内存 content store + conformance 套件
- `container.oci`：已迁到核心类型，23 个用例保留
- `docker`：骨架 + 共享实现 + conformance

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
