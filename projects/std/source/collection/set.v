# std.collection: Set trait

namespace std.collection;

trait Set<T> {
    micro insert(mut self, value: T): bool
    micro remove(mut self, value: T): bool
    micro contains(self, value: T): bool
    micro length(self): usize
    micro is_empty(self): bool
    micro clear(mut self) -> unit
    micro iter(self, f: micro(T) -> unit) -> unit
    micro to_list(self): ArrayList<T>
    micro from_list(list: ArrayList<T>): Self
}
