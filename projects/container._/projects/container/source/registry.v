namespace container;

# Registry 接口（只立合同，不含任何网络实现）。
#
# 语义：pull/push/manifest 获取都以 Reference 寻址；所有失败是硬失败
# （RegistryFailure）。网络访问是独立 host capability，由实现侧绑定，
# 本合同不引入 host 依赖。

trait Registry {
    # 拉取引用对应的 manifest（字节，通常 JSON）。
    micro pull_manifest(self, reference: Reference) -> [u8]
    # 拉取指定 digest 的 blob。
    micro pull_blob(self, reference: Reference, digest: Digest) -> [u8]
    # 推送 blob，返回最终 descriptor。
    micro push_blob(mut self, reference: Reference, media_type: utf8, bytes: [u8]) -> Descriptor
    # 推送 manifest，返回其 digest。
    micro push_manifest(mut self, reference: Reference, media_type: utf8, bytes: [u8]) -> Digest
    # 查询引用是否存在（不 raise）。
    micro exists(self, reference: Reference) -> bool
}
