namespace notedown;

[test]
micro push_block_assigns_stable_ids() -> unit {
    let g0: DocumentGraph = graph_new(1)
    let hello: [Inline] = [inline_text("hello")]
    let g1: DocumentGraph = graph_push_block(g0, block_paragraph(hello))
    if g1.blocks.length() != 1 {
        panic("expected one block")
    }
    if g1.blocks⁅0⁆.id != 1 {
        panic("first node id should be 1")
    }
    let world: [Inline] = [inline_text("world")]
    let g2: DocumentGraph = graph_push_block(g1, block_paragraph(world))
    if g2.blocks⁅1⁆.id != 2 {
        panic("second node id should be 2")
    }
    if g2.revision != 2 {
        panic("revision should count changes")
    }
    if graph_next_id(g2) != 3 {
        panic("next id should be 3")
    }
}

[test]
micro replace_block_keeps_node_id() -> unit {
    let g0: DocumentGraph = graph_new(1)
    let a: [Inline] = [inline_text("a")]
    let b: [Inline] = [inline_text("b")]
    let g1: DocumentGraph = graph_push_block(g0, block_paragraph(a))
    let g2: DocumentGraph = graph_replace_block(g1, 1, block_paragraph(b))
    if g2.blocks⁅0⁆.id != 1 {
        panic("id must be preserved")
    }
    let node: BlockNode = graph_block(g2, 1).unwrap()
    let text: utf8 = inline_plain_all(node.block.content)
    if !text.equals("b") {
        panic("content should be replaced")
    }
    if graph_block(g2, 99).is_some() {
        panic("unknown id should be none")
    }
}

[test]
micro append_child_and_delete_cleans_refs() -> unit {
    let g0: DocumentGraph = graph_new(1)
    let title: [Inline] = [inline_text("T")]
    let body: [Inline] = [inline_text("B")]
    let g1: DocumentGraph = graph_push_block(g0, block_section(1, title))
    let g2: DocumentGraph = graph_push_block(g1, block_paragraph(body))
    let g3: DocumentGraph = graph_append_child(g2, 1, 2)
    let section: BlockNode = graph_block(g3, 1).unwrap()
    if section.block.children.length() != 1 {
        panic("section should hold one child")
    }
    let errors: [utf8] = graph_validate(g3)
    if errors.length() != 0 {
        panic("valid graph should pass validation")
    }
    let g4: DocumentGraph = graph_delete_block(g3, 2)
    if graph_block(g4, 2).is_some() {
        panic("deleted node should be gone")
    }
    let after: BlockNode = graph_block(g4, 1).unwrap()
    if after.block.children.length() != 0 {
        panic("dangling child ref should be cleaned")
    }
    let errors2: [utf8] = graph_validate(g4)
    if errors2.length() != 0 {
        panic("cleaned graph should pass validation")
    }
}

[test]
micro validate_flags_dangling_and_level() -> unit {
    let g0: DocumentGraph = graph_new(1)
    let title: [Inline] = []
    let bad_children: [u64] = [99]
    let bad: Block = block_with_children(block_section(0, title), bad_children)
    let g1: DocumentGraph = graph_push_block(g0, bad)
    let errors: [utf8] = graph_validate(g1)
    if errors.length() != 2 {
        panic("should flag level and dangling child")
    }
}

[test]
micro links_mirror_children_and_keep_old_revisions() -> unit {
    let g0: DocumentGraph = graph_new(1)
    let title: [Inline] = [inline_text("T")]
    let body: [Inline] = [inline_text("B")]
    let g1: DocumentGraph = graph_push_block(g0, block_section(1, title))
    let g2: DocumentGraph = graph_push_block(g1, block_paragraph(body))
    let g3: DocumentGraph = graph_append_child(g2, 1, 2)

    # 拓扑镜像：payload 的 child 引用同步为通用图的有向边。
    if !g3.links.has_edge(1, 2) {
        panic("links should mirror child reference")
    }

    let g4: DocumentGraph = graph_delete_block(g3, 2)
    if g4.links.has_node(2) {
        panic("deleted node should leave the link graph")
    }

    if g4.links.has_edge(1, 2) {
        panic("delete should clear the mirrored edge")
    }

    # 不可变外壳：旧版本的图不被新变更污染。
    if !g3.links.has_node(2) || !g3.links.has_edge(1, 2) {
        panic("old revision graph must stay intact")
    }
}
