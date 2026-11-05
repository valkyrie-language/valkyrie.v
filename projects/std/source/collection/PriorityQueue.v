namespace std.collection;

# std.collection: PriorityQueue (min-heap)
class PriorityQueue<T> {
    _impl: BinaryHeap<T>
}

imply PriorityQueue<T> {
    [host_contract]
    micro new(): Self
        where T: std::operator::Comparable
    {
        return Self {
            _impl: BinaryHeap::new(),
        }
    }

    [host_contract]
    micro push(mut self, value: T): unit
        where T: std::operator::Comparable
    {
        self._impl.push(value)
    }

    [host_contract]
    micro pop(mut self): Option<T>
        where T: std::operator::Comparable
    {
        if self.is_empty() {
            return None
        }

        return self._impl.pop()
    }

    [host_contract]
    micro peek(self): Option<T> {
        if self.is_empty() {
            return None
        }

        return self._impl.peek()
    }

    [host_contract]
    micro length(self): usize {
        return self._impl.length()
    }

    micro is_empty(self): bool {
        return self.length() == 0
    }

    [host_contract]
    micro clear(mut self): unit {
        self._impl.clear()
    }
}
