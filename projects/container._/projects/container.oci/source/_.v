namespace container.oci;

# container.oci — OCI image-spec 规范化落地。
#
# 通用概念（digest 文法、media type 分类、descriptor 三要素、image index 骨架）
# 已上提到 `container` 核心；本包只保留 spec 专属：media type 字符串常量、
# descriptor 的 annotations/platform、manifest/config/index 的 spec 字段、
# oci-layout 目录结构校验。
#
# 分层纪律：
# - digest 文法/注册校验委托 `container` 核心（`oci_digest_*` 名保留作兼容面）。
# - media type 分类委托核心注册表，不硬编码字符串分支。
# - JSON 文本 → 模型归 `std.data.text.json`（未落地）；本包只消费已解析结构。
# - blob 内容摘要比对可用 `container` 核心 + `std.data.digest`（sha256/sha512）。
