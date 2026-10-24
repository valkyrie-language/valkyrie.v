namespace std.collection;

# Map 合同：与 HashMap / OrderedMap / SortedMap 的公开表面一致。
# insert 返回被替换的旧值（无则 None）；键存在性用 contains_key；大小用 length。
trait Map<K, V> {
    micro `get`(self, key: K): Option<V>
    micro insert(mut self, key: K, value: V): Option<V>
    micro remove(mut self, key: K): Option<V>
    micro contains_key(self, key: K): bool
    micro keys(self): List<K>
    micro values(self): List<V>
    micro length(self): usize
    micro is_empty(self): bool
    micro clear(mut self) -> unit
    micro iterator(self, f: micro(K, V) -> unit) -> unit
}
