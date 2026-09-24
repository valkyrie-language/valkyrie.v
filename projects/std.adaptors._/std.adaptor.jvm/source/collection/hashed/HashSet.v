namespace std.adaptor.jvm.collections;

[host_provider(std::collection::HashSet::insert)]
[inline(always)]
private micro hash_set_insert<T>(set: std.collection.HashSet<T>, value: T): bool {
    return __hash_set_jvm_add(set, value)
}

[host_provider(std::collection::HashSet::remove)]
[inline(always)]
private micro hash_set_remove<T>(set: std.collection.HashSet<T>, value: T): bool {
    return __hash_set_jvm_remove(set, value)
}

[host_provider(std::collection::HashSet::contains)]
[inline(always)]
private micro hash_set_contains<T>(set: std.collection.HashSet<T>, value: T): bool {
    return __hash_set_jvm_contains(set, value)
}

[host_provider(std::collection::HashSet::length)]
[inline(always)]
private micro hash_set_length<T>(set: std.collection.HashSet<T>): usize {
    return __hash_set_jvm_length(set)
}

[host_provider(std::collection::HashSet::clear)]
[inline(always)]
private micro hash_set_clear<T>(set: std.collection.HashSet<T>): unit {
    __hash_set_jvm_clear(set)
}

[host_provider(std::collection::HashSet::to_list)]
[inline(always)]
private micro hash_set_to_list<T>(set: std.collection.HashSet<T>): std.collection.List<T> {
    return __hash_set_jvm_list_from_any::<T>(set)
}

[host_provider(std::collection::HashSet::new)]
[inline(always)]
private micro hash_set_new<T>(): std.collection.HashSet<T> {
    return __hash_set_jvm_new::<T>()
}

[jvm("java.util.HashSet", "<init>")]
private micro __hash_set_jvm_new<T>(): std.collection.HashSet<T> { }

[jvm("java.util.HashSet", "add")]
private micro __hash_set_jvm_add<T>(set: std.collection.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "remove")]
private micro __hash_set_jvm_remove<T>(set: std.collection.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "contains"), pure]
private micro __hash_set_jvm_contains<T>(set: std.collection.HashSet<T>, value: T): bool { }

[jvm("java.util.HashSet", "size"), pure]
private micro __hash_set_jvm_length<T>(set: std.collection.HashSet<T>): usize { }

[jvm("java.util.HashSet", "clear")]
private micro __hash_set_jvm_clear<T>(set: std.collection.HashSet<T>): unit { }

[jvm("java.util.ArrayList", "<init>")]
private micro __hash_set_jvm_list_from_any<T>(items: any): std.collection.ArrayList<T> { }
