# std.collection: HashSet implementation

namespace std.collection;

class HashSet<T> {
    _impl: SwissSet<T>
}

imply HashSet<T>: Set<T> {
    [host_contract]
    micro insert(mut self, value: T): bool
        where T: Equal & Hash
    {
        return self._impl.insert(value)
    }

    [host_contract]
    micro remove(mut self, value: T): bool
        where T: Equal & Hash
    {
        return self._impl.remove(value)
    }

    [host_contract]
    micro contains(self, value: T): bool
        where T: Equal & Hash
    {
        return self._impl.contains(value)
    }

    [host_contract]
    micro length(self): usize {
        return self._impl.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self) -> unit {
        self._impl.clear()
    }

    micro iter(self, f: micro(T) -> unit) -> unit {
        let items: ArrayList<T> = self.to_list()
        loop item in items {
            f(item)
        }
    }

    [host_contract]
    micro to_list(self): ArrayList<T> {
        return self._impl.to_list()
    }

    micro from_list(list: ArrayList<T>): Self
        where T: Equal & Hash
    {
        let mut result: Self = Self::new()
        list.iter(micro(value: T) -> unit { result.insert(value) })
        return result
    }
}

imply HashSet<T> {
    [host_contract]
    micro new(): Self {
        return Self { _impl: SwissSet::new(16) }
    }
}

# 序数合同：键即索引，`Index = T`（集合里键与元素同型），与 `isize` / `usize` 无关。
# 集合只有按键访问语义、没有 0 基偏移计数语义，因此不实现 `Cardinal`。
# 读路径：`[ ]` 是裸值形态，缺键结构化失败；可恢复形态是 `get`（`Option<T>`）。
# 写路径：`[ ]=` 与 `insert` 同源——缺键时新增，已存在时不改变元素个数。
imply HashSet<T>: std::operator::Ordinal {
    type Index = T;
    type Element = T;

    suffix `[ ]`(self, value: T): T {
        let result: Option<T> = self.get(value)
        if result.is_none() {
            std::types::panic("HashSet [ ] 键缺失：主访问是裸值形态")
        }
        return result.unwrap()
    }

    # 写入直接走存储层：`Set::insert` 是带 `Equal & Hash` 约束的 trait 方法，
    # 在 `Ordinal` impl 内无法解析该约束（`Ordinal` 合同不带泛型约束），
    # 因此与 `HashSet::insert` 共用同一条 `SwissSet::insert` 存储路径，不维护第二套。
    suffix `[ ]=`(mut self, key: T, element: T) {
        let inserted: bool = self._impl.insert(element)
    }

    micro get(self, value: T): Option<T> {
        return self._impl.get(value)
    }

    # 与 `[ ]=` 同源：键用于定位，元素即写入值。
    micro set(mut self, value: T, element: T) {
        self[value] = element
    }
}
