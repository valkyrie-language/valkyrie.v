namespace document;

# document — `document.*` 核心：文档树、元数据、引用系统、资源与失败模型（纯模型，无 IO）。
#
# 本包不拥有格式解析（归 `std.data.*` 与产品包）、不拥有渲染目标与布局
# （归 `document.render` / `document.layout`）。产品级解析器只把结果映射进本模型。
