
namespace core::text;

[primitive("core::text::char")]
structure char {

}

imply char {
    micro to_u32(self) -> u32 {
        return self as u16 as u32
    }

    micro lowercase_ascii_index(self) -> Option<i64> {
        let code: u32 = self.to_u32()
        if code < 97 {
            return option_none::<i64>()
        }
        if code > 122 {
            return option_none::<i64>()
        }
        return Some((code - 97) as i64)
    }
}
