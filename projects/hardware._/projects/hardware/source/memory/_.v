namespace hardware;

# memory 层：堆可见性分类、缓冲 usage 旗标与对齐、显式 map/unmap 与相干性、staging 拷贝、OOM 语义。
#
# 不变量：
# - 仅 host_visible / unified 堆的缓冲可 map；device_local 只能经 staging 拷贝；
# - map 会话互斥且以 epoch 令牌为凭：map 发放 epoch，unmap 递增作废，旧令牌操作一律拒绝；
# - unmap 是写可见性边界：map_write 的内容在 unmap 后对设备操作可见；
# - 分配失败永远结构化（堆容量记账 + 对齐校验），不 panic、不部分成功；
# - 对齐档位为 2 的幂，offset 必须是对齐的倍数。
