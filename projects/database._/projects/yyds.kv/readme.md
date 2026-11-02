# yyds.kv

`yyds.kv` 是 `yyds` 的 KV 存储内核，定义分片（shard）级 KV 合同；`yydb` 作为 sidecar 高速缓存时同样消费本内核。

## 定位

- 内核只拥有：键、记录值、记录、扫描、提交边界与比较语义
- 查询、schema、事务编排、协议与网络归 `yyds` / `yydb` 上层产品，不进内核
- 纯计算、无 host 依赖：文件、网络、并发不属于本包
- 引擎层抽象（Engine/Cursor/WriteBatch/Transaction 等）归 `database` 包，本包是分片级语义载体，后续迁移到该合同之上

## 当前能力

- `KvKey` / `KvStoredValue` / `KvRecord`：分片数据模型
- `KvMemoryShard`：纯内存分片，记录按键序保存在有序数组中
- `get` / `put` / `delete` / `scan`：单分片读写与前缀扫描
- `KvShardCursor`：命名空间/前缀/范围游标（有序迭代、定位、反向），创建即冻结快照
- `KvShardSnapshot`：只读冻结视图（快照读）
- `KvWriteBatch`：批量暂存与结构性原子提交（折叠完成才发布）
- `commit_changes` / `durable_atomic_commit`：持久提交边界合同——内存分片按合同明确拒绝
- `compare_and_put`：基于记录 revision 的比较并写入（CAS）

## Fault 码注册表

拒绝路径一律 `Result<T, KvFault>` 结构化失败，不产出部分结果：

| 码 | 常量函数 | 含义 |
|---|---|---|
| 3001 | `kv_fault_batch_sealed` | 批量已封口仍使用 |
| 3002 | `kv_fault_cursor_invalid` | 游标无效位置被取用 |
| 3003 | `kv_fault_non_atomic_boundary` | 请求内存分片不提供的持久原子提交边界 |

## 语义约定

- 函数式不可变：所有写操作返回新分片，不原地修改
- 键序：先命名空间（按 UTF-8 字节序），再键字节（无符号字典序）
- 扫描游标：`after` 为排他下界，`before` 为排他上界，`limit` 为 0 表示不设上限
- 命名空间字段名为 `space`，避免与语言关键字冲突
