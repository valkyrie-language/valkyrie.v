namespace std.math.graph_theory;

# 二分图判定正例：偶环 4 点应返回交替 0/1 着色，孤立点单独取 0。
[test]
micro `test bipartition even cycle alternates colors`() {
    let mut graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    graph.add_edge("a", "b")
    graph.add_edge("b", "a")
    graph.add_edge("b", "c")
    graph.add_edge("c", "b")
    graph.add_edge("c", "d")
    graph.add_edge("d", "c")
    graph.add_edge("d", "a")
    graph.add_edge("a", "d")
    graph.add_node("e")

    let coloring: Option<HashMap<utf8, i64>> = bipartition(graph)
    if coloring.is_none() {
        panic("bipartition rejected an even cycle")
    }

    let result: HashMap<utf8, i64> = coloring.unwrap()
    if result.get("a").unwrap() != 0 || result.get("b").unwrap() != 1 {
        panic("bipartition even cycle base colors mismatch")
    }

    if result.get("c").unwrap() != 0 || result.get("d").unwrap() != 1 {
        panic("bipartition even cycle opposite colors mismatch")
    }

    if result.get("e").unwrap() != 0 {
        panic("bipartition isolated node must start from color 0")
    }
}

# 反例：奇环 3 点无二色解，必须失败闭合为 None，不能静默给任意着色。
[test]
micro `test bipartition odd cycle is rejected`() {
    let mut graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    graph.add_edge("a", "b")
    graph.add_edge("b", "a")
    graph.add_edge("b", "c")
    graph.add_edge("c", "b")
    graph.add_edge("c", "a")
    graph.add_edge("a", "c")

    if bipartition(graph).is_some() {
        panic("bipartition accepted an odd cycle")
    }
}

# 单向边按无向处理：0 → 1 → 2 的链仍是二分图。
[test]
micro `test bipartition treats directed edges as undirected`() {
    let mut graph: std.collection.DirectedGraph<i64> = std.collection.DirectedGraph::new()
    graph.add_edge(0, 1)
    graph.add_edge(1, 2)

    let coloring: Option<HashMap<i64, i64>> = bipartition(graph)
    if coloring.is_none() {
        panic("bipartition rejected a directed chain")
    }

    let result: HashMap<i64, i64> = coloring.unwrap()
    if result.get(0).unwrap() != 0 || result.get(1).unwrap() != 1 {
        panic("bipartition directed chain colors mismatch")
    }

    if result.get(2).unwrap() != 0 {
        panic("bipartition directed chain tail color mismatch")
    }
}

# 空图没有冲突：返回 Some(空着色表)，不是 None。
[test]
micro `test bipartition empty graph is trivially bipartite`() {
    let graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    let coloring: Option<HashMap<utf8, i64>> = bipartition(graph)
    if coloring.is_none() {
        panic("bipartition rejected an empty graph")
    }

    if coloring.unwrap().length() != 0 {
        panic("bipartition empty graph must have empty coloring")
    }
}
