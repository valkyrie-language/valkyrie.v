namespace plotter;

# L2 布局层 —— 从语义到坐标。
#
# - 统计侧：`scale`（标度训练与域映射）、`coord`（坐标系与分面）、
#   `stat`（统计家族 L1 → L3 的解析管线）。
# - 图结构侧：`graph_layout`，把节点/边映射到坐标。
#
# 图布局的分层、力导向、树、正交算法属于 `std.collection.graph` 与
# `std.math.graph_theory`。本层只负责把 L1 图语义翻译成对 std 布局能力的调用，
# 并在能力缺席时结构化失败——不在本层另写一套图算法。
