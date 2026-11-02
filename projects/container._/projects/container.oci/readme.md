# container.oci

OCI image-spec 规范化落地：spec 字段校验、schema 细节。通用概念已上提到 `container` 核心。

## 边界

- digest 文法/注册校验委托 `container` 核心；`oci_digest_*` 名保留作兼容面（algorithm agility 不变）。
- media type 分类委托核心注册表（`MediaLayer`/`MediaManifestFamily`/`MediaConfigFamily`），不硬编码字符串分支；本包只持有 OCI/Docker 规范字符串常量并注册。
- descriptor 在核心三要素（digest/media_type/size）之上补 OCI spec 的 `annotations`/`platform`。
- manifest/config/index 保留 spec 专属字段（schemaVersion、history、rootfs.diff_ids）。
- JSON 文本 → 模型归 `std.data.text.json`（当前未落地）；本包只消费已解析结构。
- blob 内容摘要比对可经 `container` 核心 + `std.data.digest`（已具备，sha256/sha512）。

## 诊断码表（文法层，`std.data` 容许式）

`oci.digest.*` 与 `container.digest.*` 同表（oci 委托核心，码随核心登记）；
`oci.layout.missing_root` / `missing_layout_file` / `unsupported_layout_version` / `missing_index` / `missing_blobs_directory` / `blob_missing`。

## 当前已知缺口

- JSON 解析：`std.data.text.json` 尚无 `source/` 实现，manifest/config 的 JSON 解析因此未落地（所属面：`projects/std.data._/std.data.text.json/`）。
- blob 字节读取：`std.io` 目前只有 `read_file_text`，无二进制读取（所属面：`projects/std/source/io/fs.v`）。
- ovm lane 缺 fs provider：layout 的 IO 测试在该 lane 结构化失败（所属面：`projects/std.adaptors._/std.adaptor.ovm/source/`）。
- 层压缩/解包：`std.data.binary.codec` 目前仅声明接口（所属面：`projects/std.data._/std.data.binary.codec/source/_.v`）。
- 编译器缺口：HIR 跨文件调用解析出现 `unresolved_call` 泛洪，测试验证因此停点，等待修复。

## 目录约定

- `source/`：digest / media_type / descriptor / manifest / layout（复用 container 核心）
- `test/`：23 个用例（digest 12 / media 3 / descriptor 4 / layout 4），原 `oci` 用例全部保留
- `test/fixtures`：`minimal-image` 正例、`broken-image` 反例
