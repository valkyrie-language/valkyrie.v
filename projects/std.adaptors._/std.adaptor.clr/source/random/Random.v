namespace std.adaptor.clr.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return __random_clr_new()
}

[host_provider(std::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.random.Random {
    return __random_clr_with_seed(seed)
}

[host_provider(std::random::Random::next_i32)]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32 {
    return __random_clr_next_i32(random, max_exclusive)
}

[host_provider(std::random::Random::next_f64)]
micro host_next_f64(random: std.random.Random) -> f64 {
    return __random_clr_next_f64(random)
}

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_new(): std.random.Random { }

[clr("System.Runtime", "System.Random", ".ctor")]
private micro __random_clr_with_seed(seed: i32): std.random.Random { }

[clr("System.Runtime", "System.Random", "Next")]
private micro __random_clr_next_i32(random: std.random.Random, max_exclusive: i32): i32 { }

[clr("System.Runtime", "System.Random", "NextDouble")]
private micro __random_clr_next_f64(random: std.random.Random): f64 { }
