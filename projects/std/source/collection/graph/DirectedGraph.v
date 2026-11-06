namespace std.collection;

# 有向图：泛型节点标识 + 邻接表。
#
# - 节点只是标识，不内嵌 payload：业务数据由外部 `HashMap<N, P>` 组合，本类型不演化成
#   `Graph<N, P>` 双泛形 god 类。
# - 节点集合 `_nodes: ArrayList<N>` 保持插入序（拓扑排序与遍历结果确定性）；
#   `_node_set: HashSet<N>` 承担 O(1) 存在性判定。
# - 邻接双索引：`_forward`（出边）与 `_backward`（入边）同写同删，后继/前驱/度数查询
#   都是邻接表级别，不做全图线性扫描。
# - `add_edge` 幂等：重复边不重复插入、不重复计数；`_edge_count` 随车维护。
# - 节点标识约束 `N: Equal & Hash`，复用 `HashMap` / `HashSet` / `ArrayList` 既有容器，
#   不造平行容器。
class DirectedGraph<N> {
    _nodes: ArrayList<N>
    _node_set: HashSet<N>
    _forward: HashMap<N, ArrayList<N>>
    _backward: HashMap<N, ArrayList<N>>
    _edge_count: usize
}

imply DirectedGraph<N> {
    micro new(): Self
        where N: Equal & Hash
    {
        return Self {
            _nodes: ArrayList::new(0),
            _node_set: HashSet::new(),
            _forward: HashMap::new(0),
            _backward: HashMap::new(0),
            _edge_count: 0,
        }
    }

    micro is_empty(self): bool {
        return self._nodes.is_empty()
    }

    micro node_count(self): usize {
        return self._nodes.length()
    }

    micro edge_count(self): usize {
        return self._edge_count
    }

    # 节点列表（插入序）。
    micro nodes(self): ArrayList<N> {
        return self._nodes
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

    micro has_edge(self, from: N, to: N): bool
        where N: Equal & Hash
    {
        let targets: Option<ArrayList<N>> = self._forward[from]
        if targets.is_none() {
            return false
        }

        return targets.unwrap().contains(to)
    }

    # 添加有向边 `from → to`，自动补缺失节点；重复边幂等（不重复计数）。
    micro add_edge(mut self, from: N, to: N): unit
        where N: Equal & Hash
    {
        self.add_node(from)
        self.add_node(to)

        if self.has_edge(from, to) {
            return
        }

        let existing_forward: Option<ArrayList<N>> = self._forward[from]
        if existing_forward.is_some() {
            let mut targets: ArrayList<N> = existing_forward.unwrap()
            targets.push(to)
            self._forward[from] = targets
        }
        else {
            let mut targets: ArrayList<N> = ArrayList::new(1)
            targets.push(to)
            self._forward[from] = targets
        }

        let existing_backward: Option<ArrayList<N>> = self._backward[to]
        if existing_backward.is_some() {
            let mut sources: ArrayList<N> = existing_backward.unwrap()
            sources.push(from)
            self._backward[to] = sources
        }
        else {
            let mut sources: ArrayList<N> = ArrayList::new(1)
            sources.push(from)
            self._backward[to] = sources
        }

        self._edge_count = self._edge_count + 1
    }

    # 删除一条有向边；边不存在则忽略（幂等）。
    micro remove_edge(mut self, from: N, to: N): unit
        where N: Equal & Hash
    {
        if !self.has_edge(from, to) {
            return
        }

        let targets: ArrayList<N> = self._forward[from].unwrap()
        self._forward[from] = remove_list_value(targets, to)

        let sources: ArrayList<N> = self._backward[to].unwrap()
        self._backward[to] = remove_list_value(sources, from)

        self._edge_count = self._edge_count - 1
    }

    # 删除节点及其关联的所有边（出边与入边同步清理）。
    micro remove_node(mut self, node: N): unit
        where N: Equal & Hash
    {
        if !self.has_node(node) {
            return
        }

        let outgoing: Option<ArrayList<N>> = self._forward[node]
        if outgoing.is_some() {
            let targets: ArrayList<N> = outgoing.unwrap()
            let mut i: usize = 0
            while i < targets.length() {
                let target: N = targets⁅i⁆
                let sources: ArrayList<N> = self._backward[target].unwrap()
                self._backward[target] = remove_list_value(sources, node)
                self._edge_count = self._edge_count - 1
                i = i + 1
            }

            self._forward.remove(node)
        }

        let incoming: Option<ArrayList<N>> = self._backward[node]
        if incoming.is_some() {
            let sources: ArrayList<N> = incoming.unwrap()
            let mut i: usize = 0
            while i < sources.length() {
                let source: N = sources⁅i⁆
                let targets: ArrayList<N> = self._forward[source].unwrap()
                self._forward[source] = remove_list_value(targets, node)
                self._edge_count = self._edge_count - 1
                i = i + 1
            }

            self._backward.remove(node)
        }

        self._node_set.remove(node)

        # `_nodes` 保持插入序：按值定位后按 1 基序数移除。
        let mut i: usize = 0
        while i < self._nodes.length() {
            if self._nodes⁅i⁆ == node {
                self._nodes.remove(i + 1)
                return
            }

            i = i + 1
        }
    }

    # 后继列表（邻接表直出；节点不存在时为空表）。
    micro successors(self, node: N): ArrayList<N>
        where N: Equal & Hash
    {
        let targets: Option<ArrayList<N>> = self._forward[node]
        if targets.is_none() {
            return ArrayList::new(0)
        }

        return targets.unwrap()
    }

    # 前驱列表（反向索引直出；节点不存在时为空表）。
    micro predecessors(self, node: N): ArrayList<N>
        where N: Equal & Hash
    {
        let sources: Option<ArrayList<N>> = self._backward[node]
        if sources.is_none() {
            return ArrayList::new(0)
        }

        return sources.unwrap()
    }

    micro out_degree(self, node: N): usize
        where N: Equal & Hash
    {
        return self.successors(node).length()
    }

    micro in_degree(self, node: N): usize
        where N: Equal & Hash
    {
        return self.predecessors(node).length()
    }

    # 深拷贝：按插入序重放节点与边，供不可变外壳（如文档 IR）在变更前复制，
    # 旧版本持有的图实例不被后续修改污染。
    micro clone(self): Self
        where N: Equal & Hash
    {
        let mut copy: DirectedGraph<N> = DirectedGraph::new()
        let mut i: usize = 0
        while i < self._nodes.length() {
            copy.add_node(self._nodes⁅i⁆)
            i = i + 1
        }

        i = 0
        while i < self._nodes.length() {
            let node: N = self._nodes⁅i⁆
            let targets: ArrayList<N> = self.successors(node)
            let mut s: usize = 0
            while s < targets.length() {
                copy.add_edge(node, targets⁅s⁆)
                s = s + 1
            }

            i = i + 1
        }

        return copy
    }
}

# 从列表中按值删除首个匹配项（1 基序数移除），返回新列表；供邻接表收缩使用。
private micro remove_list_value<N>(list: ArrayList<N>, value: N): ArrayList<N>
    where N: Equal & Hash
{
    let mut i: usize = 0
    while i < list.length() {
        if list⁅i⁆ == value {
            let mut result: ArrayList<N> = ArrayList::new(list.length())
            let mut j: usize = 0
            while j < list.length() {
                if j != i {
                    result.push(list⁅j⁆)
                }

                j = j + 1
            }

            return result
        }

        i = i + 1
    }

    return list
}
