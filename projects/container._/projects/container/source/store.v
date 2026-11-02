namespace container;

# ContentStore / BlobStore 合同（内容寻址、去重）。
#
# 语义：
# - `put` 写入字节并按内容摘要寻址；相同字节重复 put 得到相同 digest（去重）。
# - `get` 按 digest 取字节；不存在 raise `container.store.not_found`。
# - `exists` 查询是否存在，不 raise。
# - 写入前由实现校验内容摘要与 digest 一致（不一致是完整性硬失败）。
#
# 所有失败都是硬失败，走语言错误通道（`ContainerFailure`）。

trait ContentStore {
    micro put(mut self, media_type: utf8, bytes: [u8]) -> Descriptor
    micro get(self, digest: Digest) -> [u8]
    micro exists(self, digest: Digest) -> bool
    micro remove(mut self, digest: Digest) -> bool
}
