namespace std.collection;

# std.collection: Stack - LIFO 栈
class Stack<T> {
    data: ArrayList<T>
}

imply Stack<T> {
    micro new(): Self {
        return Self { data: ArrayList::new(0) }
    }
    micro push(mut self, value: T): unit {
        self.data.push(value)
    }
    micro pop(mut self): Option<T> {
        return self.data.pop()
    }
    micro peek(self): Option<T> {
        return self.data.last()
    }
    micro length(self): usize {
        return self.data.length()
    }
    micro is_empty(self): bool {
        return self.data.is_empty()
    }
    micro clear(mut self): unit {
        self.data.clear()
    }
    # 自顶向下遍历：索引取 `usize` 且只在本文件内递减，越界不可能发生；
    # 元素经 0 基 `⁅ ⁆` 合同直接读取（不是 1 基序数 `get`）。
    micro iter(self, f: micro(T) -> unit): unit {
        let mut index: usize = self.length()
        while index > 0 {
            index = index - 1
            f(self.data⁅index⁆)
        }
    }
}



