namespace std.math.graph_theory;

# 权重合同：加权图算法只要求加法与严格小于序。
# 距离以 `Option` 表达（`None` 即不可达/无穷），零元由调用方显式传入，
# 合同本身不假设静态零元。合同不做单位/维度假设，任何满足两条运算的类型均可作权重。
trait Weight {
    micro add(self, rhs: Self): Self

    micro less(self, rhs: Self): bool
}

imply f64: Weight {
    micro add(self, rhs: Self): Self {
        return self + rhs
    }

    micro less(self, rhs: Self): bool {
        return self < rhs
    }
}

imply i32: Weight {
    micro add(self, rhs: Self): Self {
        return self + rhs
    }

    micro less(self, rhs: Self): bool {
        return self < rhs
    }
}

imply i64: Weight {
    micro add(self, rhs: Self): Self {
        return self + rhs
    }

    micro less(self, rhs: Self): bool {
        return self < rhs
    }
}

imply u64: Weight {
    micro add(self, rhs: Self): Self {
        return self + rhs
    }

    micro less(self, rhs: Self): bool {
        return self < rhs
    }
}

class WeightedEdge<N, W> {
    from: N
    to: N
    weight: W
}

# 加权图：节点表与边表均保持插入序，全部算法的输出由插入序唯一决定。
# 无向边以一对反向同权有向边表达；允许平行边（多重图语义）。
class WeightedGraph<N, W> {
    _nodes: ArrayList<N>
    _node_set: HashSet<N>
    _edges: ArrayList<WeightedEdge<N, W>>
}

imply WeightedGraph<N, W> {
    micro new(): Self
        where N: Equal & Hash
    {
        return Self {
            _nodes: ArrayList::new(0),
            _node_set: HashSet::new(),
            _edges: ArrayList::new(0),
        }
    }

    micro node_count(self): usize {
        return self._nodes.length()
    }

    micro edge_count(self): usize {
        return self._edges.length()
    }

    # 节点列表（插入序）。
    micro nodes(self): ArrayList<N> {
        return self._nodes
    }

    # 边表（插入序）；返回内部列表的引用，消费方只读。
    micro edges(self): ArrayList<WeightedEdge<N, W>> {
        return self._edges
    }

    micro has_node(self, node: N): bool
        where N: Equal & Hash
    {
        return self._node_set.contains(node)
    }

    # 添加节点；已存在则忽略（幂等）。
    micro add_node(mut self, node: N): unit
        where N: Equal & Hash
    {
        if self.has_node(node) {
            return
        }

        self._nodes.push(node)
        self._node_set.insert(node)
    }

    # 添加有向边 `from → to`；端点缺失自动补。
    micro add_edge(mut self, from: N, to: N, weight: W): unit
        where N: Equal & Hash
    {
        self.add_node(from)
        self.add_node(to)
        self._edges.push(WeightedEdge { from: from, to: to, weight: weight })
    }

    # 添加无向边：落成两条方向相反、同权重的有向边。`weight` 按值复制两次，
    # 权重须为值语义类型（数值）。
    micro add_undirected_edge(mut self, a: N, b: N, weight: W): unit
        where N: Equal & Hash
    {
        self.add_edge(a, b, weight)
        self.add_edge(b, a, weight)
    }
}

# 最短路径结果：距离表 + 前驱表。`distances` 缺键即不可达。
class WeightedPaths<N, W> {
    distances: HashMap<N, W>
    previous: HashMap<N, N>
}

imply WeightedPaths<N, W> {
    micro distance_to(self, target: N): Option<W>
        where N: Equal & Hash
    {
        return self.distances.get(target)
    }

    # 从起点到 `target` 的路径（含两端）；不可达或不在图中返回空表。
    micro path_to(self, target: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut path: ArrayList<N> = ArrayList::new(0)
        if self.distances.get(target).is_none() {
            return path
        }

        let mut cursor: N = target
        path.push(cursor)
        while self.previous.contains_key(cursor) {
            cursor = self.previous.get(cursor).unwrap()
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

# Dijkstra：非负权最短路。`zero` 是起点距离的零元，由调用方显式提供。
# 线性扫描取最小（按节点插入序，先到先得），不使用堆：输出确定，复杂度 O(V·E)。
micro dijkstra<N, W>(graph: WeightedGraph<N, W>, start: N, zero: W) -> WeightedPaths<N, W>
    where N: Equal & Hash, W: Weight
{
    let mut distances: HashMap<N, W> = HashMap::new(graph.node_count())
    let mut previous: HashMap<N, N> = HashMap::new(graph.node_count())
    if !graph.has_node(start) {
        return WeightedPaths { distances: distances, previous: previous }
    }

    distances[start] = zero

    let mut visited: HashSet<N> = HashSet::new()
    let nodes: ArrayList<N> = graph.nodes()
    let edges: ArrayList<WeightedEdge<N, W>> = graph.edges()

    let mut remaining: usize = graph.node_count()
    while remaining > 0 {
        # 取未访问且距离最小的节点；扫描按插入序，严格更小才替换，平局保序。
        let mut best: Option<N> = None
        let mut best_distance: Option<W> = None
        let mut i: usize = 0
        while i < nodes.length() {
            let node: N = nodes⁅i⁆
            if !visited.contains(node) {
                let distance: Option<W> = distances.get(node)
                if distance.is_some() {
                    if best_distance.is_none() || distance.unwrap().less(best_distance.unwrap()) {
                        best = Some(node)
                        best_distance = distance
                    }
                }
            }

            i = i + 1
        }

        if best.is_none() {
            break
        }

        let current: N = best.unwrap()
        visited.insert(current)
        remaining = remaining - 1

        let mut e: usize = 0
        while e < edges.length() {
            let edge: WeightedEdge<N, W> = edges⁅e⁆
            if edge.from == current {
                let candidate: W = distances.get(current).unwrap().add(edge.weight)
                let existing: Option<W> = distances.get(edge.to)
                if existing.is_none() || candidate.less(existing.unwrap()) {
                    distances[edge.to] = candidate
                    previous[edge.to] = current
                }
            }

            e = e + 1
        }
    }

    return WeightedPaths { distances: distances, previous: previous }
}

# Bellman-Ford：允许负权；检测到从 `start` 可达的负环返回 `None`。
# 每轮按边表插入序松弛，输出确定。
micro bellman_ford<N, W>(graph: WeightedGraph<N, W>, start: N, zero: W) -> Option<WeightedPaths<N, W>>
    where N: Equal & Hash, W: Weight
{
    if !graph.has_node(start) {
        return Some(WeightedPaths { distances: HashMap::new(0), previous: HashMap::new(0) })
    }

    let mut distances: HashMap<N, W> = HashMap::new(graph.node_count())
    let mut previous: HashMap<N, N> = HashMap::new(graph.node_count())
    distances[start] = zero

    let edges: ArrayList<WeightedEdge<N, W>> = graph.edges()
    let total: usize = graph.node_count()

    let mut round: usize = 0
    while round + 1 < total {
        let mut changed: bool = false
        let mut e: usize = 0
        while e < edges.length() {
            let edge: WeightedEdge<N, W> = edges⁅e⁆
            let base: Option<W> = distances.get(edge.from)
            if base.is_some() {
                let candidate: W = base.unwrap().add(edge.weight)
                let existing: Option<W> = distances.get(edge.to)
                if existing.is_none() || candidate.less(existing.unwrap()) {
                    distances[edge.to] = candidate
                    previous[edge.to] = edge.from
                    changed = true
                }
            }

            e = e + 1
        }

        if !changed {
            break
        }

        round = round + 1
    }

    # 第 |V| 轮仍可松弛 ⇒ 存在可达负环。
    let mut e: usize = 0
    while e < edges.length() {
        let edge: WeightedEdge<N, W> = edges⁅e⁆
        let base: Option<W> = distances.get(edge.from)
        if base.is_some() {
            let candidate: W = base.unwrap().add(edge.weight)
            let existing: Option<W> = distances.get(edge.to)
            if existing.is_none() || candidate.less(existing.unwrap()) {
                return None
            }
        }

        e = e + 1
    }

    return Some(WeightedPaths { distances: distances, previous: previous })
}

# Kruskal：稳定插入排序（权重相同保持插入序）+ 并查集，返回最小生成森林的边表。
# 结果边按权重升序、同级按插入序，输出确定。
micro kruskal_spanning<N, W>(graph: WeightedGraph<N, W>) -> ArrayList<WeightedEdge<N, W>>
    where N: Equal & Hash, W: Weight
{
    let all: ArrayList<WeightedEdge<N, W>> = graph.edges()
    let mut sorted: ArrayList<WeightedEdge<N, W>> = ArrayList::new(graph.edge_count())
    let mut i: usize = 0
    while i < all.length() {
        sorted.push(all⁅i⁆)
        i = i + 1
    }

    # 插入排序：稳定，权重相等时保持边表插入序。
    i = 1
    while i < sorted.length() {
        let mut j: usize = i
        while j > 0 {
            if sorted⁅j⁆.weight.less(sorted⁅j - 1⁆.weight) {
                let tmp: WeightedEdge<N, W> = sorted⁅j⁆
                sorted⁅j⁆ = sorted⁅j - 1⁆
                sorted⁅j - 1⁆ = tmp
                j = j - 1
            }
            else {
                break
            }
        }

        i = i + 1
    }

    let mut sets: std.collection.DisjointSet<N> = std.collection.DisjointSet::new()
    let mut forest: ArrayList<WeightedEdge<N, W>> = ArrayList::new(0)
    i = 0
    while i < sorted.length() {
        let edge: WeightedEdge<N, W> = sorted⁅i⁆
        if sets.union(edge.from, edge.to) {
            forest.push(edge)
        }

        i = i + 1
    }

    return forest
}

# Prim：从 `start` 所在连通分量长最小生成树；每轮按边表插入序扫描最小跨割边。
micro prim_spanning<N, W>(graph: WeightedGraph<N, W>, start: N) -> ArrayList<WeightedEdge<N, W>>
    where N: Equal & Hash, W: Weight
{
    let mut tree: ArrayList<WeightedEdge<N, W>> = ArrayList::new(0)
    if !graph.has_node(start) {
        return tree
    }

    let mut visited: HashSet<N> = HashSet::new()
    visited.insert(start)

    let edges: ArrayList<WeightedEdge<N, W>> = graph.edges()
    let mut remaining: usize = graph.node_count() - 1
    while remaining > 0 {
        let mut best: Option<WeightedEdge<N, W>> = None
        let mut e: usize = 0
        while e < edges.length() {
            let edge: WeightedEdge<N, W> = edges⁅e⁆
            if visited.contains(edge.from) && !visited.contains(edge.to) {
                if best.is_none() || edge.weight.less(best.unwrap().weight) {
                    best = Some(edge)
                }
            }

            e = e + 1
        }

        if best.is_none() {
            break
        }

        let chosen: WeightedEdge<N, W> = best.unwrap()
        tree.push(chosen)
        visited.insert(chosen.to)
        remaining = remaining - 1
    }

    return tree
}
