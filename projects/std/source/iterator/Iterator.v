namespace std.iterator;

⍝ 迭代器 trait
⍝ 定义按顺序产出元素的统一接口。
⍝
⍝ 协议事实只有一条：`next` 是唯一的推进事实。迭代器是否还有元素，只能经
⍝ `next` 产出的 `Option<Item>` 观察；「先问有没有、再取一个」不得把一次
⍝ 推进拆成两个互相矛盾的事实。
⍝
⍝ `has_next` 是「`next()` 是否会返回 `Some`」的幂等观察，保留在 trait 上
⍝ 为抽象声明（无默认体）：for-in 的 obligation 结算依赖它（§4.3），
⍝ 是否有下一步无法由协议层统一代答，每个实现必须按自己的推进结构承担。
⍝ 实现合同：
⍝ - 推进必须基于一格缓存：缓存为空时恰好调一次底层（或自身推进路径的）
⍝   `next` 并把结果存入缓存；重复 `has_next` 命中缓存，不再推进；
⍝ - `next` 先交缓存、再走底层；`has_next` + `next` 组合对每个元素恰好
⍝   消费一次，predicate/mapper 每元素恰好执行一次；
⍝ - 禁止复制底层 iterator 探测、重复执行回调或只探测底层；
⍝ - terminal 组合子继续消费 `next` 的真实 `Option`，禁止
⍝   `has_next` + `next().unwrap()` 组合。
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

    ⍝ 「`next()` 是否会返回 `Some`」的幂等观察（实现合同见文件头）。
    ⍝ `mut self`：一格缓存的推进需要写入缓存字段。
    micro has_next(mut self): bool

    micro enumerate(self) -> EnumerateIterator<Item, Self> {
        return EnumerateIterator {
            _iter: self,
            _ordinal: 1,
            _peek: None,
            _peeked: false,
        }
    }

    micro skip(self, count: usize) -> SkipIterator<Item, Self> {
        return SkipIterator {
            _iter: self,
            _count: count,
            _skipped: 0,
            _peek: None,
            _peeked: false,
        }
    }

    micro take(self, count: usize) -> TakeIterator<Item, Self> {
        return TakeIterator {
            _iter: self,
            _count: count,
            _taken: 0,
            _peek: None,
            _peeked: false,
        }
    }

    micro map<U>(self, f: micro(Item) -> U) -> MapIterator<Item, U, Self> {
        return MapIterator {
            _iter: self,
            _mapper: f,
            _peek: None,
            _peeked: false,
        }
    }

    micro filter(self, pred: micro(Item) -> bool) -> FilterIterator<Item, Self> {
        return FilterIterator {
            _iter: self,
            _predicate: pred,
            _peek: None,
            _peeked: false,
        }
    }

    micro filter_map<U>(self, f: micro(Item) -> Option<U>) -> FilterMapIterator<Item, U, Self> {
        return FilterMapIterator {
            _iter: self,
            _mapper: f,
            _peek: None,
            _peeked: false,
        }
    }

    micro skip_while(self, pred: micro(Item) -> bool) -> SkipWhileIterator<Item, Self> {
        return SkipWhileIterator {
            _iter: self,
            _predicate: pred,
            _skipped: false,
            _peek: None,
            _peeked: false,
        }
    }

    micro take_while(self, pred: micro(Item) -> bool) -> TakeWhileIterator<Item, Self> {
        return TakeWhileIterator {
            _iter: self,
            _predicate: pred,
            _done: false,
            _peek: None,
            _peeked: false,
        }
    }

    ⍝ 预看能力：包装本迭代器，`peek` 至多缓存一个元素。
    ⍝ `Peekable` 的缓存与 `has_next` 的一格缓存天然同构，复用同一格。
    micro peekable(self) -> Peekable<Item, Self> {
        return Peekable {
            _iter: self,
            _peeked: None,
            _exhausted: false,
        }
    }
}
