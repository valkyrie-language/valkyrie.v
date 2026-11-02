namespace document.layout;

# document.layout — `document.*` 核心布局：盒模型度量、断行断页、页面规格。
#
# 分层：
# - 盒模型（本包 `box_*`）：水平/垂直盒、基线、度量、断行与拍平，
#   不知道"页面"存在，也不知道任何输出语法；消费方是 vutex 数学排版、
#   document.plot 图布局与文本渲染测量。
# - 页面层（`paginate`）：知道"页面"存在，对已发射文本行分页。
#
# 测量 v0 是字符单元（1 码点 = 1 宽、等宽假设）；真实字体测量经 provider
# 接入后替换，不进本包硬编码。
