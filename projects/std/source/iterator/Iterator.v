namespace std.iterator;

⍝ 迭代器 trait
⍝ 定义按顺序产出元素的统一接口。
⍝
⍝ 协议事实只有一条：`next` 是唯一的推进事实。迭代器是否还有元素，只能经
⍝ `next` 产出的 `Option<Item>` 观察；协议不提供独立的预探测义务——「先问
⍝ 有没有、再取一个」把一次推进拆成两个可能互相矛盾的事实。
⍝ 需要预看时不扩协议，而是显式包一层缓存：`peekable` 产出 `Peekable`，
⍝ 由缓存承担「多看一步」，底层迭代器仍只被 `next` 推进。
⍝
⍝ `next` 的返回不能设计成 `Item?`：当 `Item` 自身允许为 `null` 时，
⍝ `Item?` 无法区分「产出了一个 `null`」与「迭代已经结束」这两种语义。
trait Iterator {
    type Item;

    ⍝ 返回下一个元素。
    ⍝ 当迭代结束时返回 `None`，否则返回 `Some(Item)`。
    ⍝ 结束之后再调用仍返回 `None`；`None` 之后没有「下一个」。
    micro next(mut self): Option<Item>

    micro enumerate(self) -> EnumerateIterator<Item, Self> {
        return EnumerateIterator {
            _iter: self,
            _ordinal: 1,
        }
    }

    micro skip(self, count: usize) -> SkipIterator<Item, Self> {
        return SkipIterator {
            _iter: self,
            _count: count,
            _skipped: 0,
        }
    }

    micro take(self, count: usize) -> TakeIterator<Item, Self> {
        return TakeIterator {
            _iter: self,
            _count: count,
            _taken: 0,
        }
    }

    micro map<U>(self, f: micro(Item) -> U) -> MapIterator<Item, U, Self> {
        return MapIterator {
            _iter: self,
            _mapper: f,
        }
    }

    micro filter(self, pred: micro(Item) -> bool) -> FilterIterator<Item, Self> {
        return FilterIterator {
            _iter: self,
            _predicate: pred,
        }
    }

    micro filter_map<U>(self, f: micro(Item) -> Option<U>) -> FilterMapIterator<Item, U, Self> {
        return FilterMapIterator {
            _iter: self,
            _mapper: f,
        }
    }

    micro skip_while(self, pred: micro(Item) -> bool) -> SkipWhileIterator<Item, Self> {
        return SkipWhileIterator {
            _iter: self,
            _predicate: pred,
            _skipped: false,
        }
    }

    micro take_while(self, pred: micro(Item) -> bool) -> TakeWhileIterator<Item, Self> {
        return TakeWhileIterator {
            _iter: self,
            _predicate: pred,
            _done: false,
        }
    }

    ⍝ 预看能力：包装本迭代器，`peek` 至多缓存一个元素。
    micro peekable(self) -> Peekable<Item, Self> {
        return Peekable {
            _iter: self,
            _peeked: None,
            _exhausted: false,
        }
    }
}
