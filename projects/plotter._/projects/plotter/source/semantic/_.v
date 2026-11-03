namespace plotter;

# L1 语义层 —— 数据与图元模型。
#
# 两个家族在此分离：
# - 统计家族：`DataFrame` + `AesMapping` + `GeomLayer` + `PlotSpec`；
#   语义是"列到视觉通道的映射 + 几何/统计声明"。
# - 图结构家族：`GraphModel`（nodes/edges/属性）；语义是"带属性的节点与边"。
#
# 两族都不含坐标：坐标属于 L2 布局，几何属于 L3 场景。本层不认识任何方言，
# 也不认识任何输出格式。
