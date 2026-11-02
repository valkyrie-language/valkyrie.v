# database._

`database._` 是数据库生态的顶层 workspace，不是单一产品。

## 组成

- `database`：所有实现共用的引擎抽象层（合同与内存参考引擎）
- `yyds.kv`：`yyds` 的 KV 存储内核（分片合同与内存实现）
- `yydb`：单机数据库：嵌入式、本地优先、带 KV 高速缓存能力
- `yyds`：分布式数据库

## 原则

- `yydb` 与 `yyds` 不是一个东西
- `yydb` 可以作为 `yyds` 的 sidecar 高速缓存
- `yydb` 和 `yyds` 可以升降级，但不能因此合并成一个包
- **与 Atlas 无关**：yyds 是独立数据库产品线，不是 Atlas ORM / 数据绑定平面；勿与 Atlas 的 VOS（schema 真源 + 默认 query；SQL 亦可）→ RegenBindings / 一次性升级故事交叉绑定

## 计划中的子包

- `projects/database`
- `projects/database.conformance`
- `projects/yyds.kv`
- `projects/yydb`
- `projects/yyds`
- `projects/yyds.protocol.mysql`
- `projects/yyds.protocol.pgsql`
- `projects/yyds.protocol.redis`
- `projects/yyds.tools`

## 当前状态

- `yyds.kv`：分片合同 + 纯内存实现已落地（原 `yykv`，已正名为 `yyds.kv`）
- `database`：引擎抽象层，合同与内存参考引擎落地中
- `yydb` / `yyds`：规划中，仅有定位文档

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
