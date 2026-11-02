namespace database;

# database — 所有数据库实现共用的引擎抽象层。
#
# 合同面：Engine / Catalog / 键值编码 / Cursor / WriteBatch / Transaction /
# Snapshot / Journal（WAL 语义）/ 失败模型 / 观测。
#
# 原则：
# - 引擎语义不进 nyar 编译器；host 能力经 [host_contract]/[host_provider] 唯一路径接入。
# - 失败是硬失败：走 `Result<T, DatabaseFault>` 结构化失败通道，不产出部分结果，
#   不套数据解析的容许模型（DataOutcome/Validation 语义不同，不混用）。
# - 内存参考引擎（`backend/memory.v`）是纯 V 实现，始终可用；
#   外部后端缺 provider 时结构化失败（`backend_unavailable`），不伪造。
# - 键在引擎层是不透明字节序列；类型化编码（memcomparable）服务 schema/记录层，
#   同层提供但不渗入引擎比较语义——引擎只按无符号字节字典序。
# - 当前工具链洪泛期的构造约束（数值一律 i64、无 utf8 聚合字段、无嵌套聚合、
#   无函数值聚合字段、`return match` 齐型分支）与当前限制见包 readme。
