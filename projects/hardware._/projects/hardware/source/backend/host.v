namespace hardware;

# host capability 接入面：外部后端的设备枚举承诺。
#
# 当前无任何 provider：GPU/加速器枚举待 Vulkan/WebGPU/CUDA adaptor 块落地后实现。
# 本合同未被任何代码路径调用——`hardware_enumerate_devices` 只返回已注册的纯 V
# 后端，外部后端在 provider 就位前不参与枚举（fail-closed，不伪造设备）。
# 声明即坐标：provider 落地前移除或实现本合同之外的任何"伪枚举"都属违规。

[host_contract]
micro hardware_host_enumerate_devices(backend_token: i64) -> [Device]
