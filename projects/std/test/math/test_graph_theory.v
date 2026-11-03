namespace std.math.graph_theory;

# KAT 图为小数十进制精确权值；遍历/松弛顺序由插入序决定，所有断言为精确等值。

private micro __test_graph_theory_weighted() -> WeightedGraph<utf8, f64> {
    let mut graph: WeightedGraph<utf8, f64> = WeightedGraph::new()
    graph.add_edge("a", "b", 2.0)
    graph.add_edge("a", "c", 5.0)
    graph.add_edge("b", "c", 1.0)
    graph.add_edge("b", "d", 2.0)
    graph.add_edge("c", "d", 3.0)
    graph.add_edge("c", "e", 6.0)
    graph.add_edge("d", "e", 1.0)
    return graph
}

[test]
micro `test graph theory dijkstra known answers`() {
    let graph: WeightedGraph<utf8, f64> = __test_graph_theory_weighted()
    let paths: WeightedPaths<utf8, f64> = dijkstra(graph, "a", 0.0)

    if paths.distance_to("b").unwrap() != 2.0 {
        panic("graph theory dijkstra distance b mismatch")
    }

    if paths.distance_to("c").unwrap() != 3.0 {
        panic("graph theory dijkstra distance c mismatch")
    }

    if paths.distance_to("d").unwrap() != 4.0 {
        panic("graph theory dijkstra distance d mismatch")
    }

    if paths.distance_to("e").unwrap() != 5.0 {
        panic("graph theory dijkstra distance e mismatch")
    }

    let path: ArrayList<utf8> = paths.path_to("e")
    if path.length() != 4 || path⁅0⁆ != "a" || path⁅1⁆ != "b" || path⁅2⁆ != "d" || path⁅3⁆ != "e" {
        panic("graph theory dijkstra path mismatch")
    }
}

[test]
micro `test graph theory dijkstra is deterministic`() {
    let first: WeightedPaths<utf8, f64> = dijkstra(__test_graph_theory_weighted(), "a", 0.0)
    let second: WeightedPaths<utf8, f64> = dijkstra(__test_graph_theory_weighted(), "a", 0.0)

    if first.distance_to("e").unwrap() != second.distance_to("e").unwrap() {
        panic("graph theory dijkstra determinism mismatch")
    }

    let path_a: ArrayList<utf8> = first.path_to("e")
    let path_b: ArrayList<utf8> = second.path_to("e")
    if path_a.length() != path_b.length() {
        panic("graph theory dijkstra path determinism mismatch")
    }

    let mut i: usize = 0
    while i < path_a.length() {
        if path_a⁅i⁆ != path_b⁅i⁆ {
            panic("graph theory dijkstra path determinism mismatch")
        }

        i = i + 1
    }
}

[test]
micro `test graph theory dijkstra missing start is empty`() {
    let graph: WeightedGraph<utf8, f64> = __test_graph_theory_weighted()
    let paths: WeightedPaths<utf8, f64> = dijkstra(graph, "z", 0.0)
    if paths.distance_to("a").is_some() {
        panic("graph theory dijkstra missing start must be empty")
    }
}

[test]
micro `test graph theory bellman ford accepts negative edge`() {
    let mut graph: WeightedGraph<utf8, f64> = WeightedGraph::new()
    graph.add_edge("a", "b", 2.0)
    graph.add_edge("a", "c", 4.0)
    graph.add_edge("b", "c", -1.0)

    let result: Option<WeightedPaths<utf8, f64>> = bellman_ford(graph, "a", 0.0)
    if result.is_none() {
        panic("graph theory bellman ford rejected a negative-edge dag")
    }

    if result.unwrap().distance_to("c").unwrap() != 1.0 {
        panic("graph theory bellman ford distance mismatch")
    }
}

[test]
micro `test graph theory bellman ford rejects negative cycle`() {
    let mut graph: WeightedGraph<utf8, f64> = WeightedGraph::new()
    graph.add_edge("a", "b", 1.0)
    graph.add_edge("b", "c", -2.0)
    graph.add_edge("c", "a", 0.5)

    if bellman_ford(graph, "a", 0.0).is_some() {
        panic("graph theory bellman ford missed a negative cycle")
    }
}

private micro __test_graph_theory_undirected() -> WeightedGraph<utf8, f64> {
    let mut graph: WeightedGraph<utf8, f64> = WeightedGraph::new()
    graph.add_undirected_edge("a", "b", 2.0)
    graph.add_undirected_edge("a", "c", 5.0)
    graph.add_undirected_edge("b", "c", 1.0)
    graph.add_undirected_edge("b", "d", 2.0)
    graph.add_undirected_edge("c", "d", 3.0)
    graph.add_undirected_edge("c", "e", 6.0)
    graph.add_undirected_edge("d", "e", 1.0)
    return graph
}

[test]
micro `test graph theory kruskal spanning forest`() {
    let forest: ArrayList<WeightedEdge<utf8, f64>> = kruskal_spanning(__test_graph_theory_undirected())
    if forest.length() != 4 {
        panic("graph theory kruskal edge count mismatch")
    }

    let mut total: f64 = 0.0
    let mut i: usize = 0
    while i < forest.length() {
        total = total + forest⁅i⁆.weight
        i = i + 1
    }

    if total != 6.0 {
        panic("graph theory kruskal total weight mismatch")
    }
}

[test]
micro `test graph theory prim spanning tree`() {
    let tree: ArrayList<WeightedEdge<utf8, f64>> = prim_spanning(__test_graph_theory_undirected(), "a")
    if tree.length() != 4 {
        panic("graph theory prim edge count mismatch")
    }

    let mut total: f64 = 0.0
    let mut i: usize = 0
    while i < tree.length() {
        total = total + tree⁅i⁆.weight
        i = i + 1
    }

    if total != 6.0 {
        panic("graph theory prim total weight mismatch")
    }
}

[test]
micro `test graph theory weak components`() {
    let mut graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    graph.add_edge("a", "b")
    graph.add_edge("b", "a")
    graph.add_edge("c", "d")
    graph.add_node("e")

    let components: ArrayList<ArrayList<utf8>> = weak_components(graph)
    if components.length() != 3 {
        panic("graph theory weak components count mismatch")
    }
}

[test]
micro `test graph theory strong components`() {
    let mut graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    graph.add_edge("a", "b")
    graph.add_edge("b", "a")
    graph.add_edge("b", "c")

    let components: ArrayList<ArrayList<utf8>> = strong_components(graph)
    if components.length() != 2 {
        panic("graph theory strong components count mismatch")
    }
}

[test]
micro `test graph theory unweighted shortest paths`() {
    let mut graph: std.collection.DirectedGraph<utf8> = std.collection.DirectedGraph::new()
    graph.add_edge("a", "b")
    graph.add_edge("a", "c")
    graph.add_edge("b", "d")

    let paths: ShortestPaths<utf8> = unweighted_shortest_paths(graph, "a")
    if paths.distance_to("d").unwrap() != (2 as usize) {
        panic("graph theory unweighted distance mismatch")
    }

    if paths.distance_to("z").is_some() {
        panic("graph theory unweighted unreachable must be absent")
    }

    let path: ArrayList<utf8> = paths.path_to("d")
    if path.length() != 3 || path⁅0⁆ != "a" || path⁅1⁆ != "b" || path⁅2⁆ != "d" {
        panic("graph theory unweighted path mismatch")
    }
}

[test]
micro `test graph theory matrix add query and neighbors`() {
    let mut matrix: GraphMatrix<f64> = GraphMatrix::new(3)
    matrix.add_edge(0, 1, 7.0)
    matrix.add_undirected_edge(1, 2, 3.0)

    if matrix.edge_count() != 3 {
        panic("graph theory matrix edge count mismatch")
    }

    if matrix.edge(0, 1).unwrap() != 7.0 {
        panic("graph theory matrix edge read mismatch")
    }

    if matrix.edge(2, 1).unwrap() != 3.0 {
        panic("graph theory matrix undirected mirror mismatch")
    }

    if matrix.has_edge(0, 2) {
        panic("graph theory matrix phantom edge")
    }

    let neighbors: ArrayList<usize> = matrix.neighbors(1)
    if neighbors.length() != 2 || neighbors⁅0⁆ != (0 as usize) || neighbors⁅1⁆ != (2 as usize) {
        panic("graph theory matrix neighbor order mismatch")
    }

    # 覆盖写不重复计数
    matrix.add_edge(0, 1, 8.0)
    if matrix.edge_count() != 3 || matrix.edge(0, 1).unwrap() != 8.0 {
        panic("graph theory matrix overwrite mismatch")
    }
}
