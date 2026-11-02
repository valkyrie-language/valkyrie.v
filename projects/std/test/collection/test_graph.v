namespace std.collection.test;

[test]
micro `test graph add and query`() {
    let mut g: DirectedGraph<utf8> = DirectedGraph::new()
    g.add_edge("a", "b")
    g.add_edge("a", "c")
    g.add_edge("b", "c")

    # 幂等：重复边不重复插入、不重复计数；重复节点同理。
    g.add_edge("a", "b")
    g.add_node("d")
    g.add_node("d")

    if g.node_count() != 4 || g.edge_count() != 3 {
        panic("graph add counts failed")
    }

    if !g.has_node("a") || g.has_node("z") {
        panic("graph has_node failed")
    }

    if !g.has_edge("a", "b") || g.has_edge("b", "a") {
        panic("graph has_edge direction failed")
    }

    if g.out_degree("a") != 2 || g.in_degree("c") != 2 {
        panic("graph degree failed")
    }

    let successors: ArrayList<utf8> = g.successors("a")
    if successors.length() != 2 || !successors.contains("b") || !successors.contains("c") {
        panic("graph successors failed")
    }

    let predecessors: ArrayList<utf8> = g.predecessors("c")
    if predecessors.length() != 2 || !predecessors.contains("a") || !predecessors.contains("b") {
        panic("graph predecessors failed")
    }

    # 缺失节点查询返回空表，不panic。
    if g.successors("z").length() != 0 || g.predecessors("z").length() != 0 {
        panic("graph missing node query failed")
    }
}

[test]
micro `test graph remove edge and node`() {
    let mut g: DirectedGraph<utf8> = DirectedGraph::new()
    g.add_edge("a", "b")
    g.add_edge("b", "c")
    g.add_edge("a", "c")

    g.remove_edge("a", "c")
    if g.edge_count() != 2 || g.has_edge("a", "c") {
        panic("graph remove_edge failed")
    }

    if g.in_degree("c") != 1 {
        panic("graph remove_edge backward index failed")
    }

    # 幂等：删不存在的边。
    g.remove_edge("a", "c")
    if g.edge_count() != 2 {
        panic("graph remove_edge idempotence failed")
    }

    # 删节点连带清理出边与入边。
    g.remove_node("b")
    if g.node_count() != 2 || g.edge_count() != 0 {
        panic("graph remove_node counts failed")
    }

    if g.has_node("b") {
        panic("graph remove_node membership failed")
    }

    if g.successors("a").length() != 0 || g.predecessors("c").length() != 0 {
        panic("graph remove_node adjacency cleanup failed")
    }

    # 幂等：删不存在的节点。
    g.remove_node("b")
    if g.node_count() != 2 {
        panic("graph remove_node idempotence failed")
    }
}

[test]
micro `test graph topological sort dag`() {
    let mut g: DirectedGraph<utf8> = DirectedGraph::new()
    g.add_edge("cook", "serve")
    g.add_edge("shop", "cook")
    g.add_edge("shop", "serve")

    let order: ArrayList<utf8> = g.topological_sort()
    if order.length() != 3 {
        panic("graph topological length failed")
    }

    # 确定性：队列按插入序推进。
    if order⁅0⁆ != "shop" || order⁅1⁆ != "cook" || order⁅2⁆ != "serve" {
        panic("graph topological order failed")
    }

    if g.has_cycle() {
        panic("graph dag has_cycle failed")
    }

    # 空图拓扑为空表。
    let empty: DirectedGraph<utf8> = DirectedGraph::new()
    if empty.topological_sort().length() != 0 {
        panic("graph empty topological failed")
    }
}

[test]
micro `test graph cycle detection`() {
    let mut g: DirectedGraph<utf8> = DirectedGraph::new()
    g.add_edge("a", "b")
    g.add_edge("b", "c")
    g.add_edge("c", "a")

    if !g.has_cycle() {
        panic("graph cycle has_cycle failed")
    }

    if g.topological_sort().length() != 0 {
        panic("graph cycle topological failed")
    }

    let cycle: ArrayList<utf8> = g.find_cycle()
    if cycle.length() == 0 {
        panic("graph find_cycle failed")
    }

    # 自环也是环。
    let mut self_loop: DirectedGraph<i32> = DirectedGraph::new()
    self_loop.add_edge(1, 1)
    if !self_loop.has_cycle() {
        panic("graph self loop failed")
    }

    # 无环图找不到环。
    let mut dag: DirectedGraph<i32> = DirectedGraph::new()
    dag.add_edge(1, 2)
    if dag.find_cycle().length() != 0 {
        panic("graph dag find_cycle failed")
    }
}

[test]
micro `test graph traversal`() {
    let mut g: DirectedGraph<i32> = DirectedGraph::new()
    g.add_edge(1, 2)
    g.add_edge(1, 3)
    g.add_edge(2, 4)
    g.add_edge(3, 4)
    g.add_node(9)

    let dfs_order: ArrayList<i32> = g.dfs(1)
    if dfs_order.length() != 4 || dfs_order⁅0⁆ != 1 {
        panic("graph dfs failed")
    }

    if !dfs_order.contains(4) {
        panic("graph dfs reachability failed")
    }

    let bfs_order: ArrayList<i32> = g.bfs(1)
    if bfs_order.length() != 4 || bfs_order⁅0⁆ != 1 || bfs_order⁅3⁆ != 4 {
        panic("graph bfs order failed")
    }

    # 不可达节点不在遍历结果中。
    if dfs_order.contains(9) || bfs_order.contains(9) {
        panic("graph unreachable node failed")
    }
}

[test]
micro `test graph transitive closure`() {
    let mut g: DirectedGraph<i32> = DirectedGraph::new()
    g.add_edge(1, 2)
    g.add_edge(2, 3)

    let successors: ArrayList<i32> = g.transitive_successors(1)
    if successors.length() != 2 || successors.contains(1) {
        panic("graph transitive successors failed")
    }

    let predecessors: ArrayList<i32> = g.transitive_predecessors(3)
    if predecessors.length() != 2 || predecessors.contains(3) {
        panic("graph transitive predecessors failed")
    }

    if !predecessors.contains(1) || !predecessors.contains(2) {
        panic("graph transitive predecessors content failed")
    }
}
