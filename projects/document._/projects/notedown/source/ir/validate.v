namespace notedown;

# 结构不变式检查：dangling 引用与 Section level 范围。

micro node_exists(graph: DocumentGraph, node_id: u64) -> bool {
    # 存在性以通用图为唯一事实源（`blocks` 的线性扫描不再承担拓扑判定）。
    return graph.links.has_node(node_id)
}

micro graph_validate(graph: DocumentGraph) -> [utf8] {
    let mut errors: [utf8] = []
    let mut index: usize = 0
    while index < graph.blocks.length() {
        let node: BlockNode = graph.blocks⁅index⁆
        if node.block.kind == 0 {
            if node.block.level < 1 || node.block.level > 6 {
                errors = push(errors, "section level out of range")
            }
            let mut child_index: usize = 0
            while child_index < node.block.children.length() {
                let child_id: u64 = node.block.children⁅child_index⁆
                if !node_exists(graph, child_id) {
                    errors = push(errors, "section has dangling child reference")
                }
                child_index = child_index + 1
            }
        }
        if node.block.kind == 2 {
            let mut item_index: usize = 0
            while item_index < node.block.items.length() {
                let item: ListItem = node.block.items⁅item_index⁆
                let mut child_index: usize = 0
                while child_index < item.children.length() {
                    let child_id: u64 = item.children⁅child_index⁆
                    if !node_exists(graph, child_id) {
                        errors = push(errors, "list item has dangling child reference")
                    }
                    child_index = child_index + 1
                }
                item_index = item_index + 1
            }
        }
        index = index + 1
    }
    return errors
}
