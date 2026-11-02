namespace std.collection;

class BinaryHeap<T> {
    data: ArrayList<T>
}

imply BinaryHeap<T> {
    micro new(): Self {
        return Self {
            data: ArrayList::new(0),
        }
    }

    micro push(mut self, value: T): unit {
        self.data.push(value)
        self.sift_up(self.data.length() - 1)
    }

    micro pop(mut self): Option<T> {
        if self.data.is_empty() {
            return None
        }

        let length: usize = self.data.length()
        if length == 1 {
            return self.data.remove(1)
        }

        let result: T = self.data.get(1)
        let last: T = self.data.remove(length).unwrap()
        self.data.set(1, last)
        self.sift_down(0)
        return Some(result)
    }

    micro peek(self): Option<T> {
        return self.data.first()
    }

    micro length(self): usize {
        return self.data.length()
    }

    micro is_empty(self): bool {
        return self.data.is_empty()
    }

    micro clear(mut self): unit {
        self.data.clear()
    }

    micro sift_up(mut self, index: usize): unit {
        let mut cursor: usize = index
        while cursor > 0 {
            let parent: usize = (cursor - 1) / 2
            let current: T = self.data.get((cursor + 1) as isize)
            let parent_value: T = self.data.get((parent + 1) as isize)
            if current >= parent_value {
                break
            }

            self.data.set((cursor + 1) as isize, parent_value)
            self.data.set((parent + 1) as isize, current)
            cursor = parent
        }
    }

    micro sift_down(mut self, index: usize): unit {
        let length: usize = self.data.length()
        let mut cursor: usize = index
        while true {
            let left: usize = 2 * cursor + 1
            let right: usize = 2 * cursor + 2
            let mut smallest: usize = cursor

            if left < length && self.data.get((left + 1) as isize) < self.data.get((smallest + 1) as isize) {
                smallest = left
            }

            if right < length && self.data.get((right + 1) as isize) < self.data.get((smallest + 1) as isize) {
                smallest = right
            }

            if smallest == cursor {
                break
            }

            let current: T = self.data.get((cursor + 1) as isize)
            self.data.set((cursor + 1) as isize, self.data.get((smallest + 1) as isize))
            self.data.set((smallest + 1) as isize, current)
            cursor = smallest
        }
    }
}
