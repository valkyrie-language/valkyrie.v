namespace std.adaptor.jvm.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return __random_jvm_new()
}

[host_provider(std::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.random.Random {
    return __random_jvm_with_seed(i64(seed))
}

[host_provider(std::random::Random::next_i32)]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32 {
    return __random_jvm_next_i32(random, max_exclusive)
}

[host_provider(std::random::Random::next_f64)]
micro host_next_f64(random: std.random.Random) -> f64 {
    return __random_jvm_next_f64(random)
}

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_new(): std.random.Random { }

[jvm("java.util.Random", "<init>")]
private micro __random_jvm_with_seed(seed: i64): std.random.Random { }

[jvm("java.util.Random", "nextInt")]
private micro __random_jvm_next_i32(random: std.random.Random, max_exclusive: i32): i32 { }

[jvm("java.util.Random", "nextDouble")]
private micro __random_jvm_next_f64(random: std.random.Random): f64 { }
