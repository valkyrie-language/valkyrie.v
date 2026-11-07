namespace plotter;

# plotter — 绘图/图表方言的统一后端。
#
# 四层，层间只通过合同通信：
#
# - `semantic`（L1 语义层）：数据与图元模型。统计家族是 dataframe + aesthetic
#   mapping + 几何/统计图层；图结构家族是 nodes/edges + 属性。两族是分离的
#   结构，不共享同一个类型。
# - `layout`（L2 布局层）：统计侧是标度、坐标系、分面；图结构侧是图布局。
#   图布局的分层/力导/树/正交算法属于 `std.collection.graph` 与
#   `std.math.graph_theory`，本层只做调用与参数映射。
# - `scene`（L3 场景层）：唯一中间表示——已解析的几何、样式、文本、图层顺序、
#   裁剪。前端（含全部方言导入）只产出它，后端只消费它。
# - `backend`（L4 后端层）：SVG / TikZ / HTML / 文本降级 / 位图。后端不知道
#   任何方言概念。
#
# 方言知识只存在于 `format/` 的导入适配器里；渲染细节只在 `backend/` 里。

# 双引号字符：`utf8` 字面量不能内嵌裸引号，需要引号时统一从这里取。
micro quote_text() -> utf8 {
    return std::text::encode_char_as_utf8('"')
}
