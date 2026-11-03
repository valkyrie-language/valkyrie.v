namespace animator;

# animator — Valkyrie 2D 角色动画运行时（格式中立，宿主绘制）
#
# 分层：
#   scene/     节点与变换层级
#   timeline/  时间轴、轨道、关键帧、插值、事件标记
#   model/     骨骼、网格、权重、变形目标（格式中立）
#   format/    Live2D / Spine / Flash 解析合同 → 统一模型的适配器
#   render/    绘制列表与宿主绘制合同抽象（不绑定渲染后端）
#   blend/     混合模式与遮罩
#   state/     状态机与过渡
#
# 语义版本一律 /v0；不支持的能力加载期或编译期失败闭合，不静默降级。
