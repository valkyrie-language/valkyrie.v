namespace hardware;

# kernel 层测试：Kernel trait 合同的直接消费（泛型 bound 调度当前不可解析）。

structure ScaleKernel {
    factor: i64
}

imply ScaleKernel: Kernel<i64, i64> {
    micro apply(self, input: i64) -> i64 {
        return input * self.factor
    }
}

[test]
micro test_kernel_apply_carries_state() -> unit {
    let kernel = ScaleKernel { factor: 7 }
    let answer: i64 = kernel.apply(6)
    if answer != 42 {
        panic("kernel apply must carry the kernel structure's parameters")
    }
}

[test]
micro test_kernel_apply_identity_factor() -> unit {
    let kernel = ScaleKernel { factor: 1 }
    let answer: i64 = kernel.apply(41)
    if answer != 41 {
        panic("factor 1 must be the identity map")
    }
}
