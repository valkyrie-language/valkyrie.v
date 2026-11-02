# std.collection: primitive Hash implementations

namespace std.collection;

# `hash_utf8` 放在 imply 之前：demand graph lowering 在同文件内按序处理，
# 先 lower 的顶层 micro 让后续 imply 方法体内的引用能正确命中。
# 遍历口径：`length` 是标量数，`⁅ ⁆`（`Cardinal`）是 0 基标量索引、自动取值为 `char`，
# 逐 `char` 取码位哈希。历史上 `length`（标量数）曾与字节下标混用导致多字节文本截断；
# 口径统一为字符后，同一文本的哈希值随之改变，属预期行为变化。
micro hash_utf8(s: utf8) -> usize {
    let mut hash: usize = 0
    let mut i: usize = 0
    while i < s.length() {
        hash = hash * 31 + s⁅i⁆ as usize
        i = i + 1
    }
    return hash
}

imply utf8: Hash {
    micro hash(self) -> usize {
        return hash_utf8(self)
    }
}

imply i32: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply u32: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply i64: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply u64: Hash {
    micro hash(self) -> usize {
        return self as usize
    }
}

imply f32: Hash {
    micro hash(self) -> usize {
        return (self * 1000000.0) as usize
    }
}

imply f64: Hash {
    micro hash(self) -> usize {
        return (self * 1000000.0) as usize
    }
}
