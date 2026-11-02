namespace hardware;

# backend 层：后端实现与 host capability 接入面。
#
# - `cpu.v`：纯 V 参考后端 —— CPU 设备描述、传输拷贝、map 执行体。
# - `host.v`：外部后端的 host capability 合同登记面（当前无 provider）。
#
# 后端接入纪律：contract 层（device/buffer/queue）按 backend_token 路由到后端实现；
# 外部后端只经 [host_contract]/[host_provider] 唯一路径接入，不做编译器特判，
# provider 缺位即结构化失败。
