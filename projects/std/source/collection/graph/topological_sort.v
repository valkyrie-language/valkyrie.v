namespace std.collection;

# Kahn 拓扑排序：有向无环图（DAG）返回拓扑序节点列表；存在环时返回空表。
# 队列与节点扫描均按插入序推进，同一图的排序结果确定（构建顺序等消费方依赖此性质）。
imply DirectedGraph<N> {
    micro topological_sort(self): ArrayList<N>
        where N: Equal & Hash
    {
        let mut result: ArrayList<N> = ArrayList::new(self.node_count())
        let total: usize = self.node_count()
        if total == 0 {
            return result
        }

        # 初始入度表；入度为 0 的节点按插入序入队。
        let mut in_degree: HashMap<N, usize> = HashMap::new(total)
        let mut queue: ArrayList<N> = ArrayList::new(total)
        let mut i: usize = 0
        while i < self._nodes.length() {
            let node: N = self._nodes⁅i⁆
            let degree: usize = self.in_degree(node)
            in_degree[node] = degree
            if degree == 0 {
                queue.push(node)
            }

            i = i + 1
        }

        # `head` 游标代替出队移除，避免队首删除的整表搬移。
        let mut head: usize = 0
        while head < queue.length() {
            let current: N = queue⁅head⁆
            head = head + 1
            result.push(current)

            let successors: ArrayList<N> = self.successors(current)
            let mut s: usize = 0
            while s < successors.length() {
                let next: N = successors⁅s⁆
                let degree: usize = in_degree[next].unwrap() - 1
                in_degree[next] = degree
                if degree == 0 {
                    queue.push(next)
                }

                s = s + 1
            }
        }

        # 有环：排序结果短于节点数。
        if result.length() < total {
            return ArrayList::new(0)
        }

        return result
    }
}
