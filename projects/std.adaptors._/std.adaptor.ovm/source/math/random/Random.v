namespace std.adaptor.ovm.math.random;

[host_provider(std::math::random::Random::new)]
micro host_new() -> std.math.random.Random {
    return std.math.random.Random {
        _state: 0
    }
}

[host_provider(std::math::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    let resolved: i32 = std.math.random.__random_normalize_seed(seed)
    return std.math.random.Random {
        _state: resolved
    }
}

[host_provider(std::math::random::Random::next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    if random._state != 0 {
        return std.math.random.__random_fallback_next_i32(random, max_exclusive)
    }

    let value: i32 = std.adaptor.ovm.builtin.math_rand()
    if value < 0 {
        return (-value) % max_exclusive
    }

    return value % max_exclusive
}

[host_provider(std::math::random::Random::next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    if random._state != 0 {
        return f64(std.math.random.__random_fallback_next_i32(random, 2147483647)) / 2147483647.0
    }

    return f64(host_next_i32(random, 2147483647)) / 2147483647.0
}
