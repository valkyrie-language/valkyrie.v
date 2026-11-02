namespace asgard.render;

# Asgard 渲染宿主合同：DOM 树构建的操作面。
# 本合同族是渲染宿主语义的唯一声明面；组件/widget 声明面归 `asgard.ui`，
# 两者职责分明，不混为一个模块。
#
# `HostElement` 是名义句柄：只有声明身份的类型，宿主私有表示，
# V 侧只传递、不解构，不允许用整数编号代替。

class HostElement {
}

# 创建元素节点；`tag` 为宿主标签名，合法性由交付序列化层裁决。
[host_contract]
micro dom_create_element(tag: utf8): HostElement

# 创建文本节点。
[host_contract]
micro dom_create_text(text: utf8): HostElement

# 追加子节点，保持插入顺序。
[host_contract]
micro dom_append(parent: HostElement, child: HostElement)

# 设置属性；`name` 为空串由宿主结构化拒绝。
[host_contract]
micro dom_set_attr(node: HostElement, name: utf8, value: utf8)

# 读取属性；未设置的属性返回空串。
[host_contract]
micro dom_get_attr(node: HostElement, name: utf8): utf8

# 设置元素文本内容（替换既有文本子节点）。
[host_contract]
micro dom_set_text(node: HostElement, text: utf8)
