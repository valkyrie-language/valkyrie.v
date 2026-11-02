namespace template;

using std.data.text::{TemplateDocument};

# 模板源窄接口（待 std.vfs 落地后整体替换）。
#
# 策略层（loader.v）与装配层（assemble.v）只经本文件的函数访问模板源，
# 不再直接读取 `TemplateCatalog` 字段。当前实现为内存目录；std.vfs 落地后
# 本文件替换为 vfs provider 适配，接口签名与策略层不变。
#
# 接口面：root 枚举/查找、条目探测（精确 root+path）、条目枚举/取下。
# 规范 id 形态（`root:path`）、扩展探测序、优先级排序、循环检测均为
# 策略层职责，不在本接口内。

structure TemplateRoot {
    name: utf8
    kind: utf8
    priority: i64
}

structure TemplateCatalogEntry {
    root: utf8
    path: utf8
    document: TemplateDocument
}

structure TemplateCatalog {
    roots: [TemplateRoot]
    entries: [TemplateCatalogEntry]
}

# root 枚举（裸路径搜索的策略输入；排序由策略层完成）。
micro template_source_roots(catalog: TemplateCatalog) -> [TemplateRoot] {
    return catalog.roots
}

# root 按名查找。
micro template_source_root(catalog: TemplateCatalog, name: utf8) -> TemplateRoot? {
    let mut index: usize = 0
    while index < catalog.roots.length() {
        let root: TemplateRoot = catalog.roots⁅index⁆.unwrap()
        if root.name == name {
            return root
        }
        index = index + 1
    }
    return null
}

# 条目探测：精确 root + path 命中条目下标。
micro template_source_probe(catalog: TemplateCatalog, root: utf8, path: utf8) -> usize? {
    let mut index: usize = 0
    while index < catalog.entries.length() {
        let entry: TemplateCatalogEntry = catalog.entries⁅index⁆.unwrap()
        if entry.root == root && entry.path == path {
            return index
        }
        index = index + 1
    }
    return null
}

# 条目枚举（装配镜像构建输入）。
micro template_source_entries(catalog: TemplateCatalog) -> [TemplateCatalogEntry] {
    return catalog.entries
}

# 条目取下（探测命中后取文档）。
micro template_source_entry(catalog: TemplateCatalog, index: usize) -> TemplateCatalogEntry {
    return catalog.entries⁅index⁆.unwrap()
}
