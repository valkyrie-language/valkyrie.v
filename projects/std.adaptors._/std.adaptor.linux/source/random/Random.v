namespace std.adaptor.linux.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random {
        _state: 1
    }
}

[host_provider(std::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.random.Random {
    return std.random.Random {
        _state: seed
    }
}

[host_provider(std::random::Random::next_i32)]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32 {
    return std.random.__random_fallback_next_i32(random, max_exclusive)
}

[host_provider(std::random::Random::next_f64)]
micro host_next_f64(random: std.random.Random) -> f64 {
    return f64(std.random.__random_fallback_next_i32(random, 2147483647)) / 2147483647.0
}
