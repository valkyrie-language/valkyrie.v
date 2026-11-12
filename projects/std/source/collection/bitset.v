namespace std.collection;

# std.collection: BitSet - 位图

class BitSet {
    words: ArrayList<u64>
}

imply BitSet {
    [host_contract]
    micro new(): Self {
        return Self { words: ArrayList::new(0) }
    }

    [host_contract]
    micro with_capacity(bits: usize): Self {
        let words_needed: usize = (bits + 63) / 64
        let mut words: ArrayList<u64> = ArrayList::new(0)
        let mut i: usize = 0
        while i < words_needed {
            words.push(0)
            i = i + 1
        }
        return Self { words: words }
    }

    [host_contract]
    micro `set`(mut self, index: usize): unit {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        self.ensure_capacity(word_idx + 1)
        let word: u64 = self.words.get((word_idx + 1) as isize).unwrap()
        self.words.set((word_idx + 1) as isize, word | ((1 as u64) << (bit_idx as u64)))
    }

    [host_contract]
    micro clear_bit(mut self, index: usize): unit {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return
        }
        let word: u64 = self.words.get((word_idx + 1) as isize).unwrap()
        self.words.set((word_idx + 1) as isize, word ^ (word & ((1 as u64) << (bit_idx as u64))))
    }

    [host_contract]
    micro `get`(self, index: usize): bool {
        let word_idx: usize = index / 64
        let bit_idx: usize = index % 64
        if word_idx >= self.words.length() {
            return false
        }
        let word: u64 = self.words.get((word_idx + 1) as isize).unwrap()
        return (word & ((1 as u64) << (bit_idx as u64))) != 0
    }

    [host_contract]
    micro toggle(mut self, index: usize): unit {
        if self.get(index) {
            self.clear_bit(index)
        }
        else {
            self.set(index)
        }
    }

    [host_contract]
    micro intersect(mut self, other: BitSet): unit {
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get((i + 1) as isize).unwrap()
            let b: u64 = other.words.get((i + 1) as isize).unwrap()
            self.words.set((i + 1) as isize, a & b)
            i = i + 1
        }
        while i < self.words.length() {
            self.words.set((i + 1) as isize, 0)
            i = i + 1
        }
    }

    [host_contract]
    micro union(mut self, other: BitSet): unit {
        self.ensure_capacity(other.words.length())
        let mut i: usize = 0
        while i < other.words.length() {
            let a: u64 = self.words.get((i + 1) as isize).unwrap()
            let b: u64 = other.words.get((i + 1) as isize).unwrap()
            self.words.set((i + 1) as isize, a | b)
            i = i + 1
        }
    }

    [host_contract]
    micro difference(mut self, other: BitSet): unit {
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get((i + 1) as isize).unwrap()
            let b: u64 = other.words.get((i + 1) as isize).unwrap()
            self.words.set((i + 1) as isize, a ^ (a & b))
            i = i + 1
        }
    }

    [host_contract]
    micro xor(mut self, other: BitSet): unit {
        self.ensure_capacity(other.words.length())
        let minimum_length: usize = if self.words.length() < other.words.length() { self.words.length() } else { other.words.length() }
        let mut i: usize = 0
        while i < minimum_length {
            let a: u64 = self.words.get((i + 1) as isize).unwrap()
            let b: u64 = other.words.get((i + 1) as isize).unwrap()
            self.words.set((i + 1) as isize, a ^ b)
            i = i + 1
        }
        while i < other.words.length() {
            self.words.set((i + 1) as isize, other.words.get((i + 1) as isize).unwrap())
            i = i + 1
        }
    }

    [host_contract]
    micro is_empty(self): bool {
        let mut i: usize = 0
        while i < self.words.length() {
            if self.words.get((i + 1) as isize).unwrap() != 0 {
                return false
            }
            i = i + 1
        }
        return true
    }

    [host_contract]
    micro clear_all(mut self): unit {
        let mut i: usize = 0
        while i < self.words.length() {
            self.words.set((i + 1) as isize, 0)
            i = i + 1
        }
    }

    # 置位数：逐 word 用 `word & (word - 1)` 清除最低置位，全 0 位图为 0。
    micro count(self): usize {
        let mut total: usize = 0
        let mut i: usize = 0
        while i < self.words.length() {
            let mut word: u64 = self.words.get((i + 1) as isize).unwrap()
            while word != 0 {
                word = word & (word - 1)
                total = total + 1
            }
            i = i + 1
        }
        return total
    }

    # 最高置位 + 1（有效位宽）；全 0 位图为 0。
    micro bit_length(self): usize {
        let mut i: usize = self.words.length()
        while i > 0 {
            let word: u64 = self.words.get(i as isize).unwrap()
            if word != 0 {
                let mut bit: usize = 64
                while bit > 0 {
                    bit = bit - 1
                    if (word & ((1 as u64) << (bit as u64))) != 0 {
                        return (i - 1) * 64 + bit + 1
                    }
                }
            }
            i = i - 1
        }
        return 0
    }

    micro ensure_capacity(mut self, needed: usize): unit {
        while self.words.length() < needed {
            self.words.push(0)
        }
    }

    # 深拷贝：words 逐项复制，副本与原位图互不影响。
    micro clone(self): Self {
        let mut words: ArrayList<u64> = ArrayList::new(self.words.length())
        let mut index: usize = 0
        while index < self.words.length() {
            words.push(self.words.get((index + 1) as isize).unwrap())
            index = index + 1
        }

        return Self { words: words }
    }

    # 分配位宽（`words.length() * 64`，必为 64 的倍数），不是已用位宽。
    # 已用位宽（最高置位 + 1）用 `bit_length()`；空位图为 0。
    micro length(self): usize {
        return self.words.length() * 64
    }

    # 置位下标（0 基）升序迭代；迭代器持有 words 快照，之后原位图变化不影响它。
    micro iter(self) -> BitSetIterator {
        return BitSetIterator { _words: self.words.to_array(), _cursor: 0, _peek: None, _peeked: false }
    }
}

# 位图迭代器：按置位下标（0 基）升序产出，所有置位访问完后返回 `None`。
class BitSetIterator {
    _words: [u64]
    _cursor: usize
    _peek: Option<usize>
    _peeked: bool
}

imply BitSetIterator: std::iterator::Iterator {
    type Item = usize;

    micro next(mut self): Option<usize> {
        if self._peeked {
            self._peeked = false
            let cached: Option<usize> = self._peek
            let empty: Option<usize> = None
            self._peek = empty
            return cached
        }

        let total: usize = self._words.length() * 64
        while self._cursor < total {
            let index: usize = self._cursor
            let word: u64 = self._words⁅index / 64⁆
            let bit: usize = index % 64
            self._cursor = index + 1
            if (word & ((1 as u64) << (bit as u64))) != 0 {
                return Some(index)
            }
        }

        return None
    }

    # 幂等观察：一格缓存。缓存空时沿唯一扫描路径前进到下一个置位（或扫尽），
    # 结果存入缓存；重复调用命中缓存，游标不会双份前进。
    micro has_next(mut self): bool {
        if !self._peeked {
            let total: usize = self._words.length() * 64
            while self._cursor < total {
                let index: usize = self._cursor
                let word: u64 = self._words⁅index / 64⁆
                let bit: usize = index % 64
                self._cursor = index + 1
                if (word & ((1 as u64) << (bit as u64))) != 0 {
                    self._peek = Some(index)
                    break
                }
            }

            self._peeked = true
        }

        return self._peek.is_some()
    }
}

imply BitSet: std::iterator::IntoIterator {
    type Item = usize;
    type Iter = BitSetIterator;

    micro into_iterator(self): BitSetIterator {
        return self.iter()
    }
}




