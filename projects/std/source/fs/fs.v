namespace std.fs;

# std.fs: 宿主文件系统字节合同。
#
# 本层是 `std.vfs` 的宿主后端：只暴露字节级原语（存在性 / 整读 / 整写），
# 路径语义到此为止；文本编码解释归消费方（`std.text` 桥接），
# 流式语义归 `std.io` 的 Reader/Writer 与 `std.vfs` 的桥接。
#
# 合同经 [host_provider] 绑定到各 lane 宿主：
# 缺绑定的目标在计划/编译期按未绑定合同收敛（fail-closed），
# 不提供内建兜底实现。

[host_contract]
micro exists(path: utf8) -> bool

[host_contract]
micro read_bytes(path: utf8) -> [u8]

[host_contract]
micro write_bytes(path: utf8, bytes: [u8]) -> bool
