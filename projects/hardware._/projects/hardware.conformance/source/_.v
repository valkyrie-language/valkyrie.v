namespace hardware.conformance;

# hardware.conformance — 七层合同的 conformance 套件。
#
# 组织：用例按合同项编号（C<层><序>），正反成对；同一套对每个注册后端运行。
# 执行载体：[test] 套件为长期交付物；[test] 入口断链修复前，
# 真实执行经消费方 [export] harness 逐项断言。

# 后端注册表：当前仅 CPU 参考后端；真后端（Vulkan/DX12/WebGPU/CUDA）经各自
# adaptor 块接入后在此登记，全部用例自动对新后端复跑。
micro conformance_backends() -> [i64] {
    return [hardware::hardware_backend_cpu()]
}
