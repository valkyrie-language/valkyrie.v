namespace database.conformance;

# database.conformance — 引擎合同验收套件。
#
# 同一套合同项（C1–C15）对全部后端逐条验收，单实现自证不算数：
# 每个用例以引擎工厂为参数（`open: micro() -> Result<DatabaseEngine, DatabaseFault>`），
# 内存参考引擎经 `database_memory_open` 入场；sqlite/mysql/redis 适配器与 yyds.kv
# 后续以各自工厂过同一套。
#
# 返回口径：0 = 通过，非 0 = 失败阶段号（用例内顺序递增，便于定位）。
# 执行证据：`[main]` 聚合入口与逐用例 `[export]`；[test] 入口在 test 语义组下
# 缺 host provider，不作为执行证据。
