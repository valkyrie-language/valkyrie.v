namespace std.math.graph_theory;

# 邻接矩阵表示：节点为 `0 .. size` 的序数区间，边权存于行主序矩阵。
# 遍历顺序恒为下标升序，输出确定。适合稠密小图；稀疏大图用 `WeightedGraph`。
class GraphMatrix<W> {
    _size: usize
    _cells: ArrayList<Option<W>>
    _edge_count: usize
}

imply GraphMatrix<W> {
    micro new(size: usize): Self {
        let mut cells: ArrayList<Option<W>> = ArrayList::new(size * size)
        let mut i: usize = 0
        while i < size * size {
            cells.push(None)
            i = i + 1
        }

        return Self {
            _size: size,
            _cells: cells,
            _edge_count: 0,
        }
    }

    micro node_count(self): usize {
        return self._size
    }

    micro edge_count(self): usize {
        return self._edge_count
    }

    # 有向边 `from → to`；重复写入覆盖旧权重，只在首次写入时计数。
    micro add_edge(mut self, from: usize, to: usize, weight: W): unit {
        if from >= self._size || to >= self._size {
            std::types::panic("std.math.graph_theory: matrix edge endpoint out of bounds")
        }

        if self._cells⁅from * self._size + to⁆.is_none() {
            self._edge_count = self._edge_count + 1
        }

        self._cells⁅from * self._size + to⁆ = Some(weight)
    }

    # 无向边：对称写入两个矩阵元。`weight` 按值复制两次，权重须为值语义类型。
    micro add_undirected_edge(mut self, a: usize, b: usize, weight: W): unit {
        self.add_edge(a, b, weight)
        self.add_edge(b, a, weight)
    }

    micro edge(self, from: usize, to: usize): Option<W> {
        if from >= self._size || to >= self._size {
            std::types::panic("std.math.graph_theory: matrix edge query out of bounds")
        }

        return self._cells⁅from * self._size + to⁆
    }

    micro has_edge(self, from: usize, to: usize): bool {
        return self.edge(from, to).is_some()
    }

    # 邻居列表：列下标升序，输出确定。
    micro neighbors(self, node: usize): ArrayList<usize> {
        if node >= self._size {
            std::types::panic("std.math.graph_theory: matrix neighbor query out of bounds")
        }

        let mut result: ArrayList<usize> = ArrayList::new(0)
        let mut column: usize = 0
        while column < self._size {
            if self._cells⁅node * self._size + column⁆.is_some() {
                result.push(column)
            }

            column = column + 1
        }

        return result
    }
}
