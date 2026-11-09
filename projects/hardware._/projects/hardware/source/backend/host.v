namespace hardware;

# host capability 接入面（当前无 provider）：外部后端的物理设备枚举承诺。
#
# 当前无任何 provider：Vulkan/DX12/WebGPU/CUDA 枚举待对应 adaptor 块落地后实现。
# 本合同未被任何代码路径调用——枚举只返回已注册的纯 V 后端，
# 外部后端在 provider 就位前不参与枚举（fail-closed，不伪造设备）。

[host_contract]
micro hardware_host_enumerate_adapters(backend_token: i64) -> [Adapter]
