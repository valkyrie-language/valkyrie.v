namespace std.collection;

# 遍历与传递闭包：DFS / BFS 返回从起点可达的访问序；传递闭包返回可达集（不含自身）。
imply DirectedGraph<N> {
    # 深度优先遍历：返回从 `start` 出发的访问顺序（含 `start`）。
    micro dfs(self, start: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut visited: HashSet<N> = HashSet::new()
        let mut result: ArrayList<N> = ArrayList::new(0)
        self.dfs_visit(start, visited, result)
        return result
    }

    private micro dfs_visit(self, node: N, mut visited: HashSet<N>, mut result: ArrayList<N>): unit
        where N: Equal & Hash
    {
        if visited.contains(node) {
            return
        }

        visited.insert(node)
        result.push(node)

        let successors: ArrayList<N> = self.successors(node)
        let mut s: usize = 0
        while s < successors.length() {
            self.dfs_visit(successors⁅s⁆, visited, result)
            s = s + 1
        }
    }

    # 广度优先遍历：返回从 `start` 出发的访问顺序（含 `start`）。
    micro bfs(self, start: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut visited: HashSet<N> = HashSet::new()
        let mut result: ArrayList<N> = ArrayList::new(0)
        let mut queue: ArrayList<N> = ArrayList::new(0)

        visited.insert(start)
        queue.push(start)

        let mut head: usize = 0
        while head < queue.length() {
            let current: N = queue⁅head⁆
            head = head + 1
            result.push(current)

            let successors: ArrayList<N> = self.successors(current)
            let mut s: usize = 0
            while s < successors.length() {
                let next: N = successors⁅s⁆
                if !visited.contains(next) {
                    visited.insert(next)
                    queue.push(next)
                }

                s = s + 1
            }
        }

        return result
    }

    # 传递后继闭包：从 `start` 可达的全部节点（不含自身）。
    micro transitive_successors(self, start: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut visited: ArrayList<N> = self.bfs(start)
        let mut result: ArrayList<N> = ArrayList::new(visited.length())
        let mut i: usize = 0
        while i < visited.length() {
            if visited⁅i⁆ != start {
                result.push(visited⁅i⁆)
            }

            i = i + 1
        }

        return result
    }

    # 传递前驱闭包：可到达 `start` 的全部节点（不含自身）。
    micro transitive_predecessors(self, start: N): ArrayList<N>
        where N: Equal & Hash
    {
        let mut visited: HashSet<N> = HashSet::new()
        let mut queue: ArrayList<N> = ArrayList::new(0)

        visited.insert(start)
        queue.push(start)

        let mut head: usize = 0
        while head < queue.length() {
            let current: N = queue⁅head⁆
            head = head + 1

            let predecessors: ArrayList<N> = self.predecessors(current)
            let mut p: usize = 0
            while p < predecessors.length() {
                let previous: N = predecessors⁅p⁆
                if !visited.contains(previous) {
                    visited.insert(previous)
                    queue.push(previous)
                }

                p = p + 1
            }
        }

        let mut result: ArrayList<N> = ArrayList::new(visited.length())
        let mut i: usize = 0
        while i < queue.length() {
            if queue⁅i⁆ != start {
                result.push(queue⁅i⁆)
            }

            i = i + 1
        }

        return result
    }
}
