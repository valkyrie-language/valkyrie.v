# container.oci

OCI image-spec 规范化落地：spec 字段校验、schema 细节。通用概念已上提到 `container` 核心。

## 边界

- digest 文法/注册校验委托 `container` 核心；`oci_digest_*` 名保留作兼容面（algorithm agility 不变）。
- media type 分类委托核心注册表（`MediaLayer`/`MediaManifestFamily`/`MediaConfigFamily`），不硬编码字符串分支；本包只持有 OCI/Docker 规范字符串常量并注册。
- descriptor 在核心三要素（digest/media_type/size）之上补 OCI spec 的 `annotations`/`platform`。
- manifest/config/index 保留 spec 专属字段（schemaVersion、history、rootfs.diff_ids）。
- JSON 文本 → 模型归 `std.data.text.json`（未落地）；本包只消费已解析结构。
- blob 内容摘要比对可经 `container` 核心 + `std.data.digest`（sha256/sha512）。

## 诊断码表（文法层，`std.data` 容许式）

digest 诊断码统一为核心 `container.digest.*`（oci 委托核心，不另立码表）；
`oci.layout.missing_root` / `missing_layout_file` / `unsupported_layout_version` / `missing_index` / `missing_blobs_directory` / `blob_missing`。

## 当前已知限制

- `std.data.text.json` 尚无实现，JSON 文本解析不可用。
- `std.io` 仅提供 `read_file_text`，blob 字节读取不可用。
- layout 的 IO 测试在 ovm lane 因缺 fs provider 结构化失败。
- `std.data.binary.codec` 仅有接口声明，层压缩/解包不可用。

## 目录约定

- `source/`：digest / media_type / descriptor / manifest / layout（复用 container 核心）
- `test/`：23 个用例（digest 12 / media 3 / descriptor 4 / layout 4），原 `oci` 用例全部保留
- `test/fixtures`：`minimal-image` 正例、`broken-image` 反例
