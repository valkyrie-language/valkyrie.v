namespace asgard.render.host.ovm;

# asgard.render 合同族的 OVM 宿主绑定。
# 实现归 OVM 进程内宿主（`nyar.host` 宿主导入，VM 私有接口）；
# 本文件只声明绑定，不携带任何组件语义。
#
# 能力门禁：仅当构建启用 feature `asgard.ssg.dom`（SSG 构建宿主声明的
# capability）时本组 provider 才被选择；普通 `legion run` / 其它 ovm 构建
# 不声明该 feature，引用合同族即因无 provider 而结构化失败，不静默放行。

[host_provider(asgard::render::dom_create_element)]
[ovm("dom_create_element")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_create_element(tag: utf8): asgard.render.HostElement

[host_provider(asgard::render::dom_create_text)]
[ovm("dom_create_text")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_create_text(text: utf8): asgard.render.HostElement

[host_provider(asgard::render::dom_append)]
[ovm("dom_append")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_append(parent: asgard.render.HostElement, child: asgard.render.HostElement)

[host_provider(asgard::render::dom_set_attr)]
[ovm("dom_set_attr")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_set_attr(node: asgard.render.HostElement, name: utf8, value: utf8)

[host_provider(asgard::render::dom_get_attr)]
[ovm("dom_get_attr")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_get_attr(node: asgard.render.HostElement, name: utf8): utf8

[host_provider(asgard::render::dom_set_text)]
[ovm("dom_set_text")]
[gate(feature = "asgard.ssg.dom")]
micro host_dom_set_text(node: asgard.render.HostElement, text: utf8)
