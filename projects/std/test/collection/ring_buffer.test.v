namespace std.collection.test;

using std.collection::RingBuffer;

structure RingBufferPayload {
    value: i64
}

[test]
micro `test ring buffer zero capacity`() {
    let mut buffer: RingBuffer<i64> = RingBuffer::new(0)
    if !buffer.is_empty() || !buffer.is_full() || buffer.length() != 0 {
        panic("zero capacity ring buffer state failed")
    }
    if buffer.enqueue(1) || buffer.dequeue().is_some() || buffer.peek().is_some() {
        panic("zero capacity ring buffer access failed")
    }
    buffer.clear()
}

[test]
micro `test ring buffer one slot reuse`() {
    let mut buffer: RingBuffer<i64> = RingBuffer::new(1)
    if !buffer.enqueue(7) || buffer.enqueue(8) || !buffer.is_full() {
        panic("single slot ring buffer capacity failed")
    }
    if buffer.peek().unwrap() != 7 || buffer.dequeue().unwrap() != 7 {
        panic("single slot ring buffer read failed")
    }
    if buffer.peek().is_some() || buffer.dequeue().is_some() || !buffer.is_empty() {
        panic("single slot ring buffer release failed")
    }
    if !buffer.enqueue(9) || buffer.dequeue().unwrap() != 9 {
        panic("single slot ring buffer reuse failed")
    }
}

[test]
micro `test ring buffer wrap clear and refill`() {
    let mut buffer: RingBuffer<i64> = RingBuffer::new(3)
    buffer.enqueue(1)
    buffer.enqueue(2)
    buffer.enqueue(3)
    if buffer.dequeue().unwrap() != 1 || buffer.dequeue().unwrap() != 2 {
        panic("ring buffer initial drain failed")
    }
    buffer.enqueue(4)
    buffer.enqueue(5)
    if buffer.length() != 3 || !buffer.is_full() || buffer.enqueue(6) {
        panic("ring buffer wrapped capacity failed")
    }
    if buffer.peek().unwrap() != 3 || buffer.dequeue().unwrap() != 3 {
        panic("ring buffer wrapped head failed")
    }
    buffer.clear()
    if !buffer.is_empty() || buffer.is_full() || buffer.peek().is_some() {
        panic("ring buffer wrapped clear failed")
    }
    buffer.enqueue(6)
    buffer.enqueue(7)
    buffer.enqueue(8)
    if buffer.dequeue().unwrap() != 6 || buffer.dequeue().unwrap() != 7 || buffer.dequeue().unwrap() != 8 {
        panic("ring buffer refill order failed")
    }
    if buffer.dequeue().is_some() {
        panic("ring buffer drained vacancy failed")
    }
}

[test]
micro `test ring buffer payload without default`() {
    let mut buffer: RingBuffer<RingBufferPayload> = RingBuffer::new(2)
    buffer.enqueue(RingBufferPayload { value: 41 })
    if buffer.peek().unwrap().value != 41 || buffer.dequeue().unwrap().value != 41 {
        panic("ring buffer non-default payload failed")
    }
    buffer.enqueue(RingBufferPayload { value: 42 })
    buffer.clear()
    buffer.enqueue(RingBufferPayload { value: 43 })
    if buffer.dequeue().unwrap().value != 43 || buffer.dequeue().is_some() {
        panic("ring buffer non-default payload reuse failed")
    }
}
