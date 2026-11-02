# container.docker

Docker 复刻：Dockerfile 解析、层构建。核心类型复用 `container` 包。

## 边界

- 不实现自己的 content store / digest / 层链，全部复用 `container` 核心，与 `container.oci` 走同一套 conformance。
- 只注册 Docker 规范 media type（manifest v2 / config / rootfs.diff.tar.gzip）。
- Dockerfile 解析（`std.data` 三段 trait）与层构建归后续块。

## 当前状态

骨架 + 共享实现（`docker_shared_store_new` = 核心 `MemoryContentStore`）+ Docker media 注册表 + conformance 用例（digest 一致性、blob 去重、media 分类）。
