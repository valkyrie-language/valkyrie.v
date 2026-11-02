namespace std.collection;

[clr("System.Collections", "System.Collections.Generic.Dictionary`2")]
[jvm("java.util.HashMap")]
class HashMap<K, V> {
    _impl: SwissTable<K, V>
}

imply HashMap<K, V>: Map<K, V> {
    [host_contract]
    micro `get`(self, key: K): Option<V>
        where K: Equal & Hash
    {
        let result: Option<V> = self._impl.get(key)
        return result
    }

    [host_contract]
    micro insert(mut self, key: K, value: V): Option<V>
        where K: Equal & Hash
    {
        # 显式 Option 注解：避免 `insert` 名与 SwissSet/HashSet（返回 bool）在无期望类型时误匹配。
        let previous: Option<V> = self._impl.insert(key, value)
        return previous
    }

    [host_contract]
    micro remove(mut self, key: K): Option<V>
        where K: Equal & Hash
    {
        return self._impl.remove(key)
    }

    [host_contract]
    micro contains_key(self, key: K): bool
        where K: Equal & Hash
    {
        return self._impl.contains_key(key)
    }

    [host_contract]
    micro keys(self): ArrayList<K> {
        return self._impl.keys()
    }

    [host_contract]
    micro values(self): ArrayList<V> {
        return self._impl.values()
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

    micro iterator(self, f: micro(K, V) -> unit) -> unit
        where K: Equal & Hash
    {
        let keys: ArrayList<K> = self.keys()
        loop key in keys {
            f(key, self.get(key).unwrap())
        }
    }
}

# 序数合同：键即索引，`Index = K` 与 `isize` / `usize` 无关。
# 只有位置/键访问语义、没有 0 基偏移计数语义，因此不实现 `Cardinal`；
# 读写直接委托底层 `SwissTable`。命名 `get` 由 `Map` 提供（`get(K) -> Option<V>`
# 与本合同的命名读路径同签名同语义，天然满足），`set` 由本 impl 按 `[ ]=` 同源给出。
imply HashMap<K, V>: std::operator::Ordinal {
    type Index = K;
    type Element = V;

    # 键即索引的主访问：裸 `V`，键缺失结构化失败（panic）。
    # 可恢复形态走 `Map::get`（`Option<V>`），不要靠 panic 判存在性。
    suffix `[ ]`(self, key: K): V {
        let result: Option<V> = self._impl.get(key)
        if result.is_none() {
            std::types::panic("HashMap [ ] 键缺失：主访问是裸值形态")
        }
        return result.unwrap()
    }

    # 键写入即插入；键不存在时新增，存在时覆盖。
    suffix `[ ]=`(mut self, key: K, value: V) {
        let previous: Option<V> = self._impl.insert(key, value)
    }

    # 与 `[ ]=` 同源：命名方法形态，互为委托。
    micro set(mut self, key: K, value: V) {
        self[key] = value
    }
}

imply HashMap<K, V> {
    [host_contract]
    micro new(capacity: usize): Self {
        return Self {
            _impl: SwissTable::new(capacity),
        }
    }
}
