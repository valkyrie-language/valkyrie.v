namespace std.collection;

# 环检测与环路径定位。
imply DirectedGraph<N> {
    # 存在环当且仅当拓扑排序结果短于节点数（Kahn 性质）。
    micro has_cycle(self): bool
        where N: Equal & Hash
    {
        return self.topological_sort().length() < self.node_count()
    }

    # 三色 DFS（0=未访问 / 1=在栈 / 2=已完成）找一条环路径；无环返回空表。
    micro find_cycle(self): ArrayList<N>
        where N: Equal & Hash
    {
        let mut color: HashMap<N, i32> = HashMap::new(self.node_count())
        let mut parent: HashMap<N, N> = HashMap::new(self.node_count())

        let mut i: usize = 0
        while i < self._nodes.length() {
            let node: N = self._nodes⁅i⁆
            color[node] = 0
            i = i + 1
        }

        i = 0
        while i < self._nodes.length() {
            let node: N = self._nodes⁅i⁆
            if color[node].unwrap() == 0 {
                let cycle: ArrayList<N> = self.find_cycle_dfs(color, parent, node)
                if cycle.length() > 0 {
                    return cycle
                }
            }

            i = i + 1
        }

        return ArrayList::new(0)
    }

    private micro find_cycle_dfs(self, mut color: HashMap<N, i32>, mut parent: HashMap<N, N>, node: N): ArrayList<N>
        where N: Equal & Hash
    {
        color[node] = 1

        let successors: ArrayList<N> = self.successors(node)
        let mut s: usize = 0
        while s < successors.length() {
            let next: N = successors⁅s⁆
            let next_color: i32 = color[next].unwrap()
            if next_color == 1 {
                # `next` 在当前 DFS 栈上：从 `node` 沿父链回溯到 `next` 构成环。
                let mut cycle: ArrayList<N> = ArrayList::new(2)
                cycle.push(next)
                let mut current: N = node
                while current != next {
                    cycle.push(current)
                    let parent_edge: Option<N> = parent[current]
                    if parent_edge.is_none() {
                        break
                    }

                    current = parent_edge.unwrap()
                }

                cycle.push(next)
                return cycle
            }

            if next_color == 0 {
                parent[next] = node
                let sub_cycle: ArrayList<N> = self.find_cycle_dfs(color, parent, next)
                if sub_cycle.length() > 0 {
                    return sub_cycle
                }
            }

            s = s + 1
        }

        color[node] = 2
        return ArrayList::new(0)
    }
}
