namespace std.math.graph_theory;

# 无权图算法：消费 `std.collection.DirectedGraph` 的邻接表表示。
# BFS/DFS、拓扑排序与环检测由 `std.collection` 的 `DirectedGraph` 自带，
# 本模块不重复实现；这里只补连通分量与无权最短路。

# 无权最短路结果：距离表（边数）+ 前驱表。`distances` 缺键即不可达。
class ShortestPaths<N> {
    distances: HashMap<N, usize>
    previous: HashMap<N, N>
}

imply ShortestPaths<N> {
    micro distance_to(self, target: N): Option<usize>
        where N: Equal & Hash
    {
        return self.distances[target]
    }

    # 从起点到 `target` 的路径（含两端）；不可达或不在图中返回空表。
    micro path_to(self, target: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut path: ArrayList<N> = ArrayList::new(0)
        if self.distances[target].is_none() {
            return path
        }

        let mut cursor: N = target
        path.push(cursor)
        while self.previous.contains_key(cursor) {
            cursor = self.previous[cursor].unwrap()
            path.push(cursor)
        }

        # 前驱链是终点到起点，反转为起点到终点。
        let mut lo: usize = 0
        let mut hi: usize = path.length()
        while lo + 1 < hi {
            hi = hi - 1
            let tmp: N = path⁅lo⁆
            path⁅lo⁆ = path⁅hi⁆
            path⁅hi⁆ = tmp
            lo = lo + 1
        }

        return path
    }
}

# 弱连通分量：把有向边当作无向后的连通分量。
# 节点按插入序扫描，分量内部按 BFS 发现序，输出确定。
micro weak_components<N>(graph: std.collection.DirectedGraph<N>) -> ArrayList<ArrayList<N>>
    where N: Equal & Hash
{
    let mut seen: HashSet<N> = HashSet::new()
    let mut components: ArrayList<ArrayList<N>> = ArrayList::new(0)
    let nodes: ArrayList<N> = graph.nodes()

    let mut i: usize = 0
    while i < nodes.length() {
        let node: N = nodes⁅i⁆
        if !seen.contains(node) {
            let mut component: ArrayList<N> = ArrayList::new(0)
            let mut queue: ArrayList<N> = ArrayList::new(0)
            seen.insert(node)
            queue.push(node)

            let mut head: usize = 0
            while head < queue.length() {
                let current: N = queue⁅head⁆
                head = head + 1
                component.push(current)

                let successors: ArrayList<N> = graph.successors(current)
                let mut s: usize = 0
                while s < successors.length() {
                    let next: N = successors⁅s⁆
                    if !seen.contains(next) {
                        seen.insert(next)
                        queue.push(next)
                    }

                    s = s + 1
                }

                let predecessors: ArrayList<N> = graph.predecessors(current)
                let mut p: usize = 0
                while p < predecessors.length() {
                    let previous: N = predecessors⁅p⁆
                    if !seen.contains(previous) {
                        seen.insert(previous)
                        queue.push(previous)
                    }

                    p = p + 1
                }
            }

            components.push(component)
        }

        i = i + 1
    }

    return components
}

# 强连通分量：Kosaraju 两遍 DFS（第一遍按插入序，第二遍在转置图上按完成序逆序）。
micro strong_components<N>(graph: std.collection.DirectedGraph<N>) -> ArrayList<ArrayList<N>>
    where N: Equal & Hash
{
    let mut visited: HashSet<N> = HashSet::new()
    let mut finish: ArrayList<N> = ArrayList::new(graph.node_count())
    let nodes: ArrayList<N> = graph.nodes()

    let mut i: usize = 0
    while i < nodes.length() {
        __graph_theory_finish_dfs(graph, nodes⁅i⁆, visited, finish)
        i = i + 1
    }

    let mut assigned: HashSet<N> = HashSet::new()
    let mut components: ArrayList<ArrayList<N>> = ArrayList::new(0)
    i = finish.length()
    while i > 0 {
        i = i - 1
        let node: N = finish⁅i⁆
        if !assigned.contains(node) {
            let mut component: ArrayList<N> = ArrayList::new(0)
            let mut stack: ArrayList<N> = ArrayList::new(0)
            assigned.insert(node)
            stack.push(node)

            while stack.length() > 0 {
                let current: N = stack.pop().unwrap()
                component.push(current)

                let predecessors: ArrayList<N> = graph.predecessors(current)
                let mut p: usize = 0
                while p < predecessors.length() {
                    let previous: N = predecessors⁅p⁆
                    if !assigned.contains(previous) {
                        assigned.insert(previous)
                        stack.push(previous)
                    }

                    p = p + 1
                }
            }

            components.push(component)
        }
    }

    return components
}

# 无权最短路：BFS 分层，距离为边数；起点不在图中返回空结果。
micro unweighted_shortest_paths<N>(graph: std.collection.DirectedGraph<N>, start: N) -> ShortestPaths<N>
    where N: Equal & Hash
{
    let mut distances: HashMap<N, usize> = HashMap::new(graph.node_count())
    let mut previous: HashMap<N, N> = HashMap::new(graph.node_count())
    if !graph.has_node(start) {
        return ShortestPaths { distances: distances, previous: previous }
    }

    distances[start] = 0
    let mut queue: ArrayList<N> = ArrayList::new(0)
    queue.push(start)

    let mut head: usize = 0
    while head < queue.length() {
        let current: N = queue⁅head⁆
        head = head + 1
        let base: usize = distances[current].unwrap()

        let successors: ArrayList<N> = graph.successors(current)
        let mut s: usize = 0
        while s < successors.length() {
            let next: N = successors⁅s⁆
            if distances[next].is_none() {
                distances[next] = base + 1
                previous[next] = current
                queue.push(next)
            }

            s = s + 1
        }
    }

    return ShortestPaths { distances: distances, previous: previous }
}

private micro __graph_theory_finish_dfs<N>(graph: std.collection.DirectedGraph<N>, node: N, mut visited: HashSet<N>, mut finish: ArrayList<N>): unit
    where N: Equal & Hash
{
    if visited.contains(node) {
        return
    }

    visited.insert(node)
    let successors: ArrayList<N> = graph.successors(node)
    let mut s: usize = 0
    while s < successors.length() {
        __graph_theory_finish_dfs(graph, successors⁅s⁆, visited, finish)
        s = s + 1
    }

    finish.push(node)
}
