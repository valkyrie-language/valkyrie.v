namespace hardware;

# backend 层：后端实现与 host capability 接入面。
#
# - CPU 参考后端（规划中）：全合同纯 V 实现，确定性数值基准（correctness oracle）。
# - `host.v`：外部后端的 host capability 合同登记面（Vulkan/DX12/WebGPU/CUDA
#   经各自 adaptor 的 [host_provider] 接入，当前无 provider）。
#
# 后端接入纪律：合同层按后端身份路由；外部后端只经 [host_contract]/[host_provider]
# 唯一路径，不做编译器特判，provider 缺位即结构化失败。
