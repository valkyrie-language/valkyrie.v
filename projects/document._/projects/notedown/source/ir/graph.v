namespace notedown;

# DocumentGraph：block 通过稳定 NodeId 寻址。
#
# 变更以不可变风格返回新图；NodeId 从 1 起，next_node 记录最后分配的 id。
# 块的引用链接（Section.children / ListItem.children 指向的 NodeId）同时镜像到
# `links: std.collection.DirectedGraph<u64>`：拓扑关系由通用图承担，payload 留在
# `blocks`；不可变语义经 `clone()` 实现，旧版本持有的图不被新变更污染。

structure BlockNode {
    id: u64
    block: Block
}

structure DocumentGraph {
    id: u64
    revision: u64
    blocks: [BlockNode]
    next_node: u64
    links: std.collection.DirectedGraph<u64>
}

micro graph_new(id: u64) -> DocumentGraph {
    return DocumentGraph {
        id: id,
        revision: 0,
        blocks: [],
        next_node: 0,
        links: std.collection.DirectedGraph::new()
    }
}

micro graph_next_id(graph: DocumentGraph) -> u64 {
    return graph.next_node + 1
}

micro graph_push_block(graph: DocumentGraph, block: Block) -> DocumentGraph {
    let node: BlockNode = BlockNode { id: graph.next_node + 1, block: block }
    let blocks: [BlockNode] = push(graph.blocks, node)
    let mut links: std.collection.DirectedGraph<u64> = graph.links.clone()
    links.add_node(node.id)
    return DocumentGraph {
        id: graph.id,
        revision: graph.revision + 1,
        blocks: blocks,
        next_node: node.id,
        links: links
    }
}

micro graph_block(graph: DocumentGraph, node_id: u64) -> Option<BlockNode> {
    let mut index: usize = 0
    while index < graph.blocks.length() {
        let node: BlockNode = graph.blocks⁅index⁆
        if node.id == node_id {
            return Some(node)
        }
        index = index + 1
    }
    return None
}

micro graph_replace_block(graph: DocumentGraph, node_id: u64, block: Block) -> DocumentGraph {
    let mut blocks: [BlockNode] = []
    let mut index: usize = 0
    while index < graph.blocks.length() {
        let node: BlockNode = graph.blocks⁅index⁆
        if node.id == node_id {
            let repl: BlockNode = BlockNode { id: node.id, block: block }
            blocks = push(blocks, repl)
        }
        else {
            blocks = push(blocks, node)
        }
        index = index + 1
    }
    return DocumentGraph {
        id: graph.id,
        revision: graph.revision + 1,
        blocks: blocks,
        next_node: graph.next_node,
        links: graph.links
    }
}

micro filter_out_id(ids: [u64], target: u64) -> [u64] {
    let mut kept: [u64] = []
    let mut index: usize = 0
    while index < ids.length() {
        if ids⁅index⁆ != target {
            kept = push(kept, ids⁅index⁆)
        }
        index = index + 1
    }
    return kept
}

micro strip_child_ref(block: Block, target: u64) -> Block {
    if block.kind == 0 {
        return block_with_children(block, filter_out_id(block.children, target))
    }
    if block.kind == 2 {
        let mut items: [ListItem] = []
        let mut index: usize = 0
        while index < block.items.length() {
            let item: ListItem = block.items⁅index⁆
            if item.children.length() == 0 {
                items = push(items, item)
            }
            else {
                let stripped: ListItem = ListItem {
                    content: item.content,
                    children: filter_out_id(item.children, target),
                    number: item.number,
                    is_task: item.is_task,
                    is_checked: item.is_checked
                }
                items = push(items, stripped)
            }
            index = index + 1
        }
        return block_with_items(block, items)
    }
    return block
}

micro graph_delete_block(graph: DocumentGraph, node_id: u64) -> DocumentGraph {
    let mut blocks: [BlockNode] = []
    let mut index: usize = 0
    while index < graph.blocks.length() {
        let node: BlockNode = graph.blocks⁅index⁆
        if node.id != node_id {
            let kept_block: Block = strip_child_ref(node.block, node_id)
            let kept: BlockNode = BlockNode { id: node.id, block: kept_block }
            blocks = push(blocks, kept)
        }
        index = index + 1
    }
    # 拓扑同步：通用图删除节点连带清理所有关联引用边。
    let mut links: std.collection.DirectedGraph<u64> = graph.links.clone()
    links.remove_node(node_id)
    return DocumentGraph {
        id: graph.id,
        revision: graph.revision + 1,
        blocks: blocks,
        next_node: graph.next_node,
        links: links
    }
}

# 仅 Section 可持有 children；追加到末尾。父节点不存在或类型不符时原样返回。
micro graph_append_child(graph: DocumentGraph, parent_id: u64, child_id: u64) -> DocumentGraph {
    let parent_option: Option<BlockNode> = graph_block(graph, parent_id)
    if parent_option.is_none() {
        return graph
    }
    let parent: BlockNode = parent_option.unwrap()
    if parent.block.kind != 0 {
        return graph
    }
    let children: [u64] = push(parent.block.children, child_id)
    let updated: Block = block_with_children(parent.block, children)
    let mut replaced: DocumentGraph = graph_replace_block(graph, parent_id, updated)
    # 拓扑同步：payload 的 child 引用同时登记为通用图的有向边。
    let mut links: std.collection.DirectedGraph<u64> = replaced.links.clone()
    links.add_edge(parent_id, child_id)
    return DocumentGraph {
        id: replaced.id,
        revision: replaced.revision,
        blocks: replaced.blocks,
        next_node: replaced.next_node,
        links: links
    }
}
