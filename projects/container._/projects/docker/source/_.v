namespace container.docker;

# container.docker — Docker 复刻（规范化落地之一）。
#
# 当前范围：包骨架与共享实现（复用 container 核心的 MemoryContentStore 与 media
# 注册表），跑通 container conformance 的核心用例。Dockerfile 解析与层构建
# 尚未落地。
#
# 一致性原则：docker 不实现自己的 content store / digest / 层链，全部复用
# `container` 核心，只注册 Docker 规范 media type。
