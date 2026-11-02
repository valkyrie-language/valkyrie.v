# container

容器生态核心合同：算法无关的通用概念，OCI / Docker / k8s 都是它之上的规范化落地。

## 组成

- `failure.v`：失败模型 `ContainerFailure`（硬失败，语言错误通道，分类码表）
- `digest.v`：`Digest` + 算法族注册表 + 文法/注册两层校验 + 内容摘要（委托 `std.data.digest`）
- `media_type.v`：`MediaTypeRegistration` 注册表（`MediaLayer`/`MediaManifestFamily`/`MediaConfigFamily`/`MediaOther`），不硬编码字符串分支
- `descriptor.v`：`Descriptor`（digest + media type + size）
- `layer.v`：`Layer` / `LayerChain`（diff_id 链与完整性校验）
- `image.v`：`ImageConfig`（env/entrypoint/cmd/ports/volumes/workdir/labels）/ `Image`
- `reference.v`：`Reference`（name:tag / digest）解析与规范化
- `image_index.v`：manifest/index 骨架（schemaVersion + mediaType + 描述符列表）
- `store.v`：`ContentStore` trait（put/get/exists/remove）
- `memory_store.v`：`MemoryContentStore` 内存实现（去重、按 digest 寻址）
- `registry.v`：`Registry` trait（pull/push/manifest，只立合同）
- `runtime.v`：`Container` 生命周期（create/start/stop/exec）、`Rootfs`/快照、`Mount`、`ResourceLimits`
- `conformance.v`：conformance 套件（digest 一致性、blob 去重、层链完整性、引用解析、sha256 已知答案、media 注册表）

## 边界

- 算法计算（sha256/sha512）与 hex 编码归 `std.data.digest`；本包只按算法名分发，绝不重写哈希。
- 文法层解析（digest/reference 字符串）错误容许，走 `std.data::DataOutcome` 诊断。
- 内容层与存储/完整性/运行时失败是硬失败，走 `ContainerFailure` 语言错误通道（区别于 `std.data` 容许式诊断）。
- registry 网络访问是独立 host capability，本包只立接口。

## 诊断码表（文法层，`std.data` 容许式）

`container.digest.empty` / `missing_separator` / `empty_algorithm` / `bad_algorithm_character` / `empty_encoded` / `bad_encoded_character` / `unsupported_algorithm` / `bad_encoded_length` / `bad_encoded_case`

## 失败码表（硬失败，`ContainerFailure`）

- 存储：`container.store.not_found` / `container.store.corrupt`
- 完整性：`container.integrity.digest_mismatch` / `container.integrity.unknown_algorithm`
- 注册表：`container.registry.unreachable` / `not_found` / `denied`
- 引用：`container.reference.invalid` / `ambiguous`
- 运行时：`container.runtime.invalid_state` / `missing_rootfs`
