namespace std.collection;

# ArrayView：`[T]` 上的零拷贝窗口（借用视图）。
#
# 语义：
# - 视图覆盖创建时刻源数组的 `[offset, offset + length)` 区间；元素不复制，
#   头部（基址与区间描述）按值共享底层存储。
# - 视图与源在源未重分配时互通读写；源随后扩容重分配时，视图仍指向旧存储
#   （旧存储由 GC 保活），看不到新内容——视图是「创建时刻的窗口」，不是活绑定。
# - 本类型只承载不变语义面（计数 + 索引访问）；扩容、追加等可变语义归 `ArrayList`。
structure ArrayView<T> {
    _source: [T]
    _offset: usize
    _length: usize
}

# 全窗视图：覆盖 `source` 的全部元素。
micro array_view<T>(source: [T]) -> ArrayView<T> {
    return ArrayView { _source: source, _offset: 0, _length: source.length }
}

imply ArrayView<T> {
    # 窗口长度（元素个数）。
    micro length(self): usize {
        return self._length
    }

    micro is_empty(self): bool {
        return self._length == 0
    }
}

# 0 基索引读写合同：与 `std::operator::Cardinal` 同语义，索引按窗口计数；
# 写经窗口落到底层存储（写穿），越界结构化失败。
imply ArrayView<T>: std::operator::Cardinal {
    type Element = T;
    type Index = usize;

    suffix `⁅ ⁆`(self, offset: usize): T {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆ 越界：offset 超出窗口元素个数")
        }

        return self._source⁅self._offset + offset⁆
    }

    suffix `⁅ ⁆=`(mut self, offset: usize, value: T): unit {
        if offset >= self._length {
            std::types::panic("Cardinal ⁅ ⁆= 越界：offset 超出窗口元素个数")
        }

        self._source⁅self._offset + offset⁆ = value
    }

    micro get_cardinal(self, offset: usize): T {
        return self⁅offset⁆
    }

    micro set_cardinal(mut self, offset: usize, value: T): unit {
        self⁅offset⁆ = value
    }
}
