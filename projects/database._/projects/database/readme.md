# database

所有数据库实现共用的引擎抽象层：合同 + 纯 V 内存参考引擎。
`yydb` / `yyds` / 外部适配器（sqlite/mysql/redis）都建立在本层之上，并经
`database.conformance` 的同一套合同项验收。

## 分层

```text
source/
├── fault.v       DatabaseFault 硬失败通道与稳定码
├── key.v         有序键编码（memcomparable）与无符号字节比较
├── value.v       值编码（类型码 + 载荷）与类型描述
├── record.v      DatabaseRecord（表空间/键/值/revision，第一级字段）
├── engine.v      DatabaseEngine：open/close、能力面、点查/写入/删除、行存储
├── catalog.v     表空间注册（create/drop/exists/list）与 catalog revision
├── cursor.v      Cursor：有序迭代、前缀、反向、定位
├── batch.v       WriteBatch：暂存与原子提交边界
├── transaction.v Transaction：begin/commit/rollback、隔离级别、乐观冲突检测
├── snapshot.v    Snapshot：只读冻结视图
├── journal.v     WAL 语义：flush/checkpoint/simulate_crash/recover
├── index.v       索引 trait 面（有序/哈希）与内存有序索引见证
├── persistence.v 持久化后端 provider 合同面（仅声明，fail-closed）
└── stats.v       尺寸估算与统计
```

## 合同要点（不变量）

- **键序**：引擎只按无符号字节字典序；记录按（表空间, 键）排列。memcomparable
  编码（`database_encode_*`）保证同类型内编码序等于值序、跨类型按类型码排序，
  前缀扫描与范围扫描在该编码上成立。
- **值全序**：值编码带类型码（null=0 < bytes=1 < i64=2 < text=3 < f64=4 预留 < bool=5）；
  `database_compare_values` 先类型码、后同类型内载荷序（i64 载荷即 memcomparable
  字节，字典序等于数值序）。未登记类型码或形态不符即 `corrupt_encoding`，不猜测顺序。
- **表空间即命名空间**：跨表不共享键域；表未注册的任何读写即 `table_missing`。
- **revision**：引擎内单调递增，每次成功写入（含批量/事务内每项、DDL）消耗一个新值；
  空批量与缺席键删除不消耗。
- **WAL**：先记日志再发布状态；`flush` 推进刷盘边界；`checkpoint` 冻结恢复点并折叠日志；
  `simulate_crash` 回主态到检查点并丢弃未刷盘日志；`recover` 依序重放幸存日志。
  内存引擎不承诺持久（`cap_durable = false`），`flush(require_durable: true)` 必失败。
- **批量原子**：先校验全部表空间，再整体生效；不出现半提交。空批量为幂等空操作。
- **事务**：begin 冻结基线快照；commit 先做写集乐观验证（CAS/版本号），失败即
  `transaction_conflict` 且引擎分毫不动；rollback 丢弃暂存。v1 不含事务内 DDL。
- **快照**：值语义拷贝，创建即脱钩；只读。
- **游标协议**：创建即冻结迭代快照；只读。状态机：新建未定位（`valid = false`）；
  `first`/`last`/`seek` 命中进入定位态；`next`/`prev` 越界回到未定位；
  未定位时 `key`/`value`/`cursor_revision` 一律 `cursor_invalid`。
- **失败模型**：硬失败走 `Result<T, DatabaseFault>`，不产出部分结果；
  不套数据解析容许模型（DataOutcome/Validation）。分级见下节。
- **索引**：`DatabaseOrderedIndex`（范围/顺序）与 `DatabaseHashIndex`（仅点查）两个
  trait 面；引擎以 `cap_ordered_index` / `cap_hash_index` 声明能力，缺能力一律
  `capability_missing`，不以另一种索引冒充。`MemoryOrderedIndex` 为内存见证实现。
- **观测**：`estimate_size` 为下界近似（键 + 值 + 每记录 32 字节常数），不冒充精确占用。

## 错误模型（硬失败 vs 可恢复）

- **硬失败**（2001–2014）：操作未生效，调用方须修正请求或放弃，原地重试无意义。
- **可恢复失败**（2101–）：操作未生效，但调用方可原样重试（背压/快照过期等瞬时态）。
  `database_fault_is_recoverable` 是唯一判定入口；码表外新码默认硬失败。
- 合同误用（如对已关闭引擎操作）属于硬失败，不是 panic；panic 只保留给
  harness/套件在已判定 `is_fine` 后的断言式取值。

## Fault 码注册表

| 码 | 常量函数 | 含义 |
|---|---|---|
| 2001 | `database_fault_engine_closed` | 引擎已关闭或待恢复 |
| 2002 | `database_fault_table_exists` | 建表目标已存在 |
| 2003 | `database_fault_table_missing` | 引用未注册的表 |
| 2004 | `database_fault_cursor_invalid` | 游标无效位置被取用 |
| 2005 | `database_fault_transaction_conflict` | 事务乐观验证失败 |
| 2006 | `database_fault_transaction_closed` | 事务已关闭仍使用 |
| 2007 | `database_fault_backend_unavailable` | 后端无已注册 provider |
| 2008 | `database_fault_durability_unsupported` | 请求引擎未声明的持久保证 |
| 2009 | `database_fault_corrupt_encoding` | 键/值编码格式校验失败 |
| 2010 | `database_fault_capability_missing` | 操作需要未声明的能力 |
| 2011 | `database_fault_table_invalid` | 表名不合法（空名） |
| 2012 | `database_fault_batch_sealed` | 批量已封口仍使用 |
| 2013 | `database_fault_journal_corrupt` | 恢复重放与检查点不一致 |
| 2014 | `database_fault_invalid_argument` | 参数不合法（如未登记隔离级别） |
| 2101 | `database_fault_engine_busy` | 可恢复：引擎暂时繁忙（背压） |
| 2102 | `database_fault_snapshot_expired` | 可恢复：快照已过期 |

## 构造约束（当前工具链能力面）

- 合同面数值一律 `i64`；
  循环计数 i64，数组边界处 `as usize`。
- 无 `utf8` 聚合字段、无 `-> utf8` 字面量返回；
  文本一律 `[u8]`。
- 无嵌套聚合字段、无 Option 字段；`Option` 只出现在返回值。
- 无函数值聚合字段；行为经参数/方法传递。
- match 只以 `return match` 齐型分支使用；多语句分支经检查器函数展开。

## 当前已知限制

- **f64 保序编码**：需要位级访问（符号/尾数变换）——`f64` 原始位重解释原语当前不可用；
  `database_encode_f64` / `database_value_encode_f64` 合同已就位，一律 `capability_missing`
  fail-closed，不以截断/文本化伪造顺序。
- **持久化后端**：`persistence.v` 已声明文件后端所需的最小宿主能力面（打开/读/写/刷盘/
  原子替换/长度/关闭/目录同步），无任何 provider；文件引擎在 provider 就位前不参与
  `database_open`，非 memory 后端一律 `backend_unavailable`（fail-closed）。
- **外部后端**：sqlite/mysql/redis 适配器尚无 `[host_contract]` 面；`database_open` 对非 memory 后端一律 `backend_unavailable`（fail-closed），适配器落地时各带 provider。
- **OVM 函数值调度**：conformance 套件的工厂函数值参数化在 OVM 暂不可编译；wasm lane 为执行证据。
- **`[test]` 入口**：test 语义组下部分 host contract 实例缺 provider，执行证据走 `database.conformance` 的 `[export]` harness。
- **utf8 诊断投影**：fault 码的人类可读文案投影待 utf8 返回身份修复后落地。
