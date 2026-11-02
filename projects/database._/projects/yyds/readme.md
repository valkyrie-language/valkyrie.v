# yyds

`yyds` 是分布式数据库产品线，隶属 `database._` workspace。

## 定位

- 存储内核复用 `yykv` 的分片合同
- 可消费作为 sidecar 高速缓存的 `yydb`，但二者物理拆包
- **与 Atlas 无关**：yyds 是独立数据库产品线，不是 Atlas ORM / 数据绑定平面；勿与 Atlas 的 VOS（schema 真源 + 默认 query；SQL 亦可）→ RegenBindings / 一次性升级故事交叉绑定

## 计划中的子包

- `yyds` 本体
- `yyds.protocol.mysql`
- `yyds.protocol.pgsql`
- `yyds.protocol.redis`
- `yyds.tools`

## 当前状态

规划中，待 `yykv` 内核稳定后开工。

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
