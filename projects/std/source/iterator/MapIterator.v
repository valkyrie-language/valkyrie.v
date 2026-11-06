<% match arch %>
<% case "clr" %>
namespace std.iterator;
# CLR: function-valued iterator adapters deferred (field call → DynamicInvoke).
<% else %>
namespace std.iterator;

structure MapIterator<T, U, I> {
    _iter: I
    _mapper: micro(T) -> U
}

imply MapIterator<T, U, I>: Iterator {
    type Item = U;

    micro has_next(self): bool
        where I: Iterator<Item = T>
    {
        return self._iter.has_next()
    }

    micro next(mut self): Option<U>
        where I: Iterator<Item = T>
    {
        if !self._iter.has_next() {
            return None
        }

        let item: T = self._iter.next().unwrap()
        return Some(self._mapper(item))
    }
}

<% end %>