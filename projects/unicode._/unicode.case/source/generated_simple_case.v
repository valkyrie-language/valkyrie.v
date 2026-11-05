namespace unicode.case;

⍝ 自动生成，请勿手改：node scripts/gen-unicode-case.mjs
⍝ 包版本：unicode.case 0.1.0
⍝ 数据版本：Unicode 16.0.0
⍝ 来源与输入哈希：
⍝   https://www.unicode.org/Public/16.0.0/ucd/UnicodeData.txt
⍝     SHA-256 FF58E5823BD095166564A006E47D111130813DCF8BF234EF79FA51A870EDB48F
⍝ 覆盖范围：
⍝   simple 小写 1178 条 / simple 大写 1195 条（仅 BMP）
⍝   跳过非 BMP 源 23202 条 / 非 BMP 目标 0 条
⍝ 限制：`char` 是 u16，非 BMP 不能表达，直接不支持。
⍝ 布局：每对「源码点、目标码点」占 2 个槽位，按源码点严格递增；
⍝   按 512 码点切成 128 块，每块一个函数（OVM 单函数代码上限 64KiB）。

⍝ ────────── simple 小写 ──────────
⍝ 分派器：按码点所在块选表；查不到即返回原码点（大小写映射是局部函数，未命中即自身）。
micro lower_simple(c: char) -> char {
    let code: u32 = c as u32
    if code < 0x200 {
        return simple_pair_lookup(unicode_case_lower_chunk_0(), code)
    }

    if code < 0x400 {
        return simple_pair_lookup(unicode_case_lower_chunk_1(), code)
    }

    if code < 0x600 {
        return simple_pair_lookup(unicode_case_lower_chunk_2(), code)
    }

    if code < 0x800 {
        return simple_pair_lookup(unicode_case_lower_chunk_3(), code)
    }

    if code < 0xA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_4(), code)
    }

    if code < 0xC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_5(), code)
    }

    if code < 0xE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_6(), code)
    }

    if code < 0x1000 {
        return simple_pair_lookup(unicode_case_lower_chunk_7(), code)
    }

    if code < 0x1200 {
        return simple_pair_lookup(unicode_case_lower_chunk_8(), code)
    }

    if code < 0x1400 {
        return simple_pair_lookup(unicode_case_lower_chunk_9(), code)
    }

    if code < 0x1600 {
        return simple_pair_lookup(unicode_case_lower_chunk_10(), code)
    }

    if code < 0x1800 {
        return simple_pair_lookup(unicode_case_lower_chunk_11(), code)
    }

    if code < 0x1A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_12(), code)
    }

    if code < 0x1C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_13(), code)
    }

    if code < 0x1E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_14(), code)
    }

    if code < 0x2000 {
        return simple_pair_lookup(unicode_case_lower_chunk_15(), code)
    }

    if code < 0x2200 {
        return simple_pair_lookup(unicode_case_lower_chunk_16(), code)
    }

    if code < 0x2400 {
        return simple_pair_lookup(unicode_case_lower_chunk_17(), code)
    }

    if code < 0x2600 {
        return simple_pair_lookup(unicode_case_lower_chunk_18(), code)
    }

    if code < 0x2800 {
        return simple_pair_lookup(unicode_case_lower_chunk_19(), code)
    }

    if code < 0x2A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_20(), code)
    }

    if code < 0x2C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_21(), code)
    }

    if code < 0x2E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_22(), code)
    }

    if code < 0x3000 {
        return simple_pair_lookup(unicode_case_lower_chunk_23(), code)
    }

    if code < 0x3200 {
        return simple_pair_lookup(unicode_case_lower_chunk_24(), code)
    }

    if code < 0x3400 {
        return simple_pair_lookup(unicode_case_lower_chunk_25(), code)
    }

    if code < 0x3600 {
        return simple_pair_lookup(unicode_case_lower_chunk_26(), code)
    }

    if code < 0x3800 {
        return simple_pair_lookup(unicode_case_lower_chunk_27(), code)
    }

    if code < 0x3A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_28(), code)
    }

    if code < 0x3C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_29(), code)
    }

    if code < 0x3E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_30(), code)
    }

    if code < 0x4000 {
        return simple_pair_lookup(unicode_case_lower_chunk_31(), code)
    }

    if code < 0x4200 {
        return simple_pair_lookup(unicode_case_lower_chunk_32(), code)
    }

    if code < 0x4400 {
        return simple_pair_lookup(unicode_case_lower_chunk_33(), code)
    }

    if code < 0x4600 {
        return simple_pair_lookup(unicode_case_lower_chunk_34(), code)
    }

    if code < 0x4800 {
        return simple_pair_lookup(unicode_case_lower_chunk_35(), code)
    }

    if code < 0x4A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_36(), code)
    }

    if code < 0x4C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_37(), code)
    }

    if code < 0x4E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_38(), code)
    }

    if code < 0x5000 {
        return simple_pair_lookup(unicode_case_lower_chunk_39(), code)
    }

    if code < 0x5200 {
        return simple_pair_lookup(unicode_case_lower_chunk_40(), code)
    }

    if code < 0x5400 {
        return simple_pair_lookup(unicode_case_lower_chunk_41(), code)
    }

    if code < 0x5600 {
        return simple_pair_lookup(unicode_case_lower_chunk_42(), code)
    }

    if code < 0x5800 {
        return simple_pair_lookup(unicode_case_lower_chunk_43(), code)
    }

    if code < 0x5A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_44(), code)
    }

    if code < 0x5C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_45(), code)
    }

    if code < 0x5E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_46(), code)
    }

    if code < 0x6000 {
        return simple_pair_lookup(unicode_case_lower_chunk_47(), code)
    }

    if code < 0x6200 {
        return simple_pair_lookup(unicode_case_lower_chunk_48(), code)
    }

    if code < 0x6400 {
        return simple_pair_lookup(unicode_case_lower_chunk_49(), code)
    }

    if code < 0x6600 {
        return simple_pair_lookup(unicode_case_lower_chunk_50(), code)
    }

    if code < 0x6800 {
        return simple_pair_lookup(unicode_case_lower_chunk_51(), code)
    }

    if code < 0x6A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_52(), code)
    }

    if code < 0x6C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_53(), code)
    }

    if code < 0x6E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_54(), code)
    }

    if code < 0x7000 {
        return simple_pair_lookup(unicode_case_lower_chunk_55(), code)
    }

    if code < 0x7200 {
        return simple_pair_lookup(unicode_case_lower_chunk_56(), code)
    }

    if code < 0x7400 {
        return simple_pair_lookup(unicode_case_lower_chunk_57(), code)
    }

    if code < 0x7600 {
        return simple_pair_lookup(unicode_case_lower_chunk_58(), code)
    }

    if code < 0x7800 {
        return simple_pair_lookup(unicode_case_lower_chunk_59(), code)
    }

    if code < 0x7A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_60(), code)
    }

    if code < 0x7C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_61(), code)
    }

    if code < 0x7E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_62(), code)
    }

    if code < 0x8000 {
        return simple_pair_lookup(unicode_case_lower_chunk_63(), code)
    }

    if code < 0x8200 {
        return simple_pair_lookup(unicode_case_lower_chunk_64(), code)
    }

    if code < 0x8400 {
        return simple_pair_lookup(unicode_case_lower_chunk_65(), code)
    }

    if code < 0x8600 {
        return simple_pair_lookup(unicode_case_lower_chunk_66(), code)
    }

    if code < 0x8800 {
        return simple_pair_lookup(unicode_case_lower_chunk_67(), code)
    }

    if code < 0x8A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_68(), code)
    }

    if code < 0x8C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_69(), code)
    }

    if code < 0x8E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_70(), code)
    }

    if code < 0x9000 {
        return simple_pair_lookup(unicode_case_lower_chunk_71(), code)
    }

    if code < 0x9200 {
        return simple_pair_lookup(unicode_case_lower_chunk_72(), code)
    }

    if code < 0x9400 {
        return simple_pair_lookup(unicode_case_lower_chunk_73(), code)
    }

    if code < 0x9600 {
        return simple_pair_lookup(unicode_case_lower_chunk_74(), code)
    }

    if code < 0x9800 {
        return simple_pair_lookup(unicode_case_lower_chunk_75(), code)
    }

    if code < 0x9A00 {
        return simple_pair_lookup(unicode_case_lower_chunk_76(), code)
    }

    if code < 0x9C00 {
        return simple_pair_lookup(unicode_case_lower_chunk_77(), code)
    }

    if code < 0x9E00 {
        return simple_pair_lookup(unicode_case_lower_chunk_78(), code)
    }

    if code < 0xA000 {
        return simple_pair_lookup(unicode_case_lower_chunk_79(), code)
    }

    if code < 0xA200 {
        return simple_pair_lookup(unicode_case_lower_chunk_80(), code)
    }

    if code < 0xA400 {
        return simple_pair_lookup(unicode_case_lower_chunk_81(), code)
    }

    if code < 0xA600 {
        return simple_pair_lookup(unicode_case_lower_chunk_82(), code)
    }

    if code < 0xA800 {
        return simple_pair_lookup(unicode_case_lower_chunk_83(), code)
    }

    if code < 0xAA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_84(), code)
    }

    if code < 0xAC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_85(), code)
    }

    if code < 0xAE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_86(), code)
    }

    if code < 0xB000 {
        return simple_pair_lookup(unicode_case_lower_chunk_87(), code)
    }

    if code < 0xB200 {
        return simple_pair_lookup(unicode_case_lower_chunk_88(), code)
    }

    if code < 0xB400 {
        return simple_pair_lookup(unicode_case_lower_chunk_89(), code)
    }

    if code < 0xB600 {
        return simple_pair_lookup(unicode_case_lower_chunk_90(), code)
    }

    if code < 0xB800 {
        return simple_pair_lookup(unicode_case_lower_chunk_91(), code)
    }

    if code < 0xBA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_92(), code)
    }

    if code < 0xBC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_93(), code)
    }

    if code < 0xBE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_94(), code)
    }

    if code < 0xC000 {
        return simple_pair_lookup(unicode_case_lower_chunk_95(), code)
    }

    if code < 0xC200 {
        return simple_pair_lookup(unicode_case_lower_chunk_96(), code)
    }

    if code < 0xC400 {
        return simple_pair_lookup(unicode_case_lower_chunk_97(), code)
    }

    if code < 0xC600 {
        return simple_pair_lookup(unicode_case_lower_chunk_98(), code)
    }

    if code < 0xC800 {
        return simple_pair_lookup(unicode_case_lower_chunk_99(), code)
    }

    if code < 0xCA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_100(), code)
    }

    if code < 0xCC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_101(), code)
    }

    if code < 0xCE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_102(), code)
    }

    if code < 0xD000 {
        return simple_pair_lookup(unicode_case_lower_chunk_103(), code)
    }

    if code < 0xD200 {
        return simple_pair_lookup(unicode_case_lower_chunk_104(), code)
    }

    if code < 0xD400 {
        return simple_pair_lookup(unicode_case_lower_chunk_105(), code)
    }

    if code < 0xD600 {
        return simple_pair_lookup(unicode_case_lower_chunk_106(), code)
    }

    if code < 0xD800 {
        return simple_pair_lookup(unicode_case_lower_chunk_107(), code)
    }

    if code < 0xDA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_108(), code)
    }

    if code < 0xDC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_109(), code)
    }

    if code < 0xDE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_110(), code)
    }

    if code < 0xE000 {
        return simple_pair_lookup(unicode_case_lower_chunk_111(), code)
    }

    if code < 0xE200 {
        return simple_pair_lookup(unicode_case_lower_chunk_112(), code)
    }

    if code < 0xE400 {
        return simple_pair_lookup(unicode_case_lower_chunk_113(), code)
    }

    if code < 0xE600 {
        return simple_pair_lookup(unicode_case_lower_chunk_114(), code)
    }

    if code < 0xE800 {
        return simple_pair_lookup(unicode_case_lower_chunk_115(), code)
    }

    if code < 0xEA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_116(), code)
    }

    if code < 0xEC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_117(), code)
    }

    if code < 0xEE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_118(), code)
    }

    if code < 0xF000 {
        return simple_pair_lookup(unicode_case_lower_chunk_119(), code)
    }

    if code < 0xF200 {
        return simple_pair_lookup(unicode_case_lower_chunk_120(), code)
    }

    if code < 0xF400 {
        return simple_pair_lookup(unicode_case_lower_chunk_121(), code)
    }

    if code < 0xF600 {
        return simple_pair_lookup(unicode_case_lower_chunk_122(), code)
    }

    if code < 0xF800 {
        return simple_pair_lookup(unicode_case_lower_chunk_123(), code)
    }

    if code < 0xFA00 {
        return simple_pair_lookup(unicode_case_lower_chunk_124(), code)
    }

    if code < 0xFC00 {
        return simple_pair_lookup(unicode_case_lower_chunk_125(), code)
    }

    if code < 0xFE00 {
        return simple_pair_lookup(unicode_case_lower_chunk_126(), code)
    }

    return simple_pair_lookup(unicode_case_lower_chunk_127(), code)
}

⍝ U+0000..U+01FF
micro unicode_case_lower_chunk_0() -> [char] {
    return [
        0x0041 as char, 0x0061 as char, 0x0042 as char, 0x0062 as char,
        0x0043 as char, 0x0063 as char, 0x0044 as char, 0x0064 as char,
        0x0045 as char, 0x0065 as char, 0x0046 as char, 0x0066 as char,
        0x0047 as char, 0x0067 as char, 0x0048 as char, 0x0068 as char,
        0x0049 as char, 0x0069 as char, 0x004A as char, 0x006A as char,
        0x004B as char, 0x006B as char, 0x004C as char, 0x006C as char,
        0x004D as char, 0x006D as char, 0x004E as char, 0x006E as char,
        0x004F as char, 0x006F as char, 0x0050 as char, 0x0070 as char,
        0x0051 as char, 0x0071 as char, 0x0052 as char, 0x0072 as char,
        0x0053 as char, 0x0073 as char, 0x0054 as char, 0x0074 as char,
        0x0055 as char, 0x0075 as char, 0x0056 as char, 0x0076 as char,
        0x0057 as char, 0x0077 as char, 0x0058 as char, 0x0078 as char,
        0x0059 as char, 0x0079 as char, 0x005A as char, 0x007A as char,
        0x00C0 as char, 0x00E0 as char, 0x00C1 as char, 0x00E1 as char,
        0x00C2 as char, 0x00E2 as char, 0x00C3 as char, 0x00E3 as char,
        0x00C4 as char, 0x00E4 as char, 0x00C5 as char, 0x00E5 as char,
        0x00C6 as char, 0x00E6 as char, 0x00C7 as char, 0x00E7 as char,
        0x00C8 as char, 0x00E8 as char, 0x00C9 as char, 0x00E9 as char,
        0x00CA as char, 0x00EA as char, 0x00CB as char, 0x00EB as char,
        0x00CC as char, 0x00EC as char, 0x00CD as char, 0x00ED as char,
        0x00CE as char, 0x00EE as char, 0x00CF as char, 0x00EF as char,
        0x00D0 as char, 0x00F0 as char, 0x00D1 as char, 0x00F1 as char,
        0x00D2 as char, 0x00F2 as char, 0x00D3 as char, 0x00F3 as char,
        0x00D4 as char, 0x00F4 as char, 0x00D5 as char, 0x00F5 as char,
        0x00D6 as char, 0x00F6 as char, 0x00D8 as char, 0x00F8 as char,
        0x00D9 as char, 0x00F9 as char, 0x00DA as char, 0x00FA as char,
        0x00DB as char, 0x00FB as char, 0x00DC as char, 0x00FC as char,
        0x00DD as char, 0x00FD as char, 0x00DE as char, 0x00FE as char,
        0x0100 as char, 0x0101 as char, 0x0102 as char, 0x0103 as char,
        0x0104 as char, 0x0105 as char, 0x0106 as char, 0x0107 as char,
        0x0108 as char, 0x0109 as char, 0x010A as char, 0x010B as char,
        0x010C as char, 0x010D as char, 0x010E as char, 0x010F as char,
        0x0110 as char, 0x0111 as char, 0x0112 as char, 0x0113 as char,
        0x0114 as char, 0x0115 as char, 0x0116 as char, 0x0117 as char,
        0x0118 as char, 0x0119 as char, 0x011A as char, 0x011B as char,
        0x011C as char, 0x011D as char, 0x011E as char, 0x011F as char,
        0x0120 as char, 0x0121 as char, 0x0122 as char, 0x0123 as char,
        0x0124 as char, 0x0125 as char, 0x0126 as char, 0x0127 as char,
        0x0128 as char, 0x0129 as char, 0x012A as char, 0x012B as char,
        0x012C as char, 0x012D as char, 0x012E as char, 0x012F as char,
        0x0130 as char, 0x0069 as char, 0x0132 as char, 0x0133 as char,
        0x0134 as char, 0x0135 as char, 0x0136 as char, 0x0137 as char,
        0x0139 as char, 0x013A as char, 0x013B as char, 0x013C as char,
        0x013D as char, 0x013E as char, 0x013F as char, 0x0140 as char,
        0x0141 as char, 0x0142 as char, 0x0143 as char, 0x0144 as char,
        0x0145 as char, 0x0146 as char, 0x0147 as char, 0x0148 as char,
        0x014A as char, 0x014B as char, 0x014C as char, 0x014D as char,
        0x014E as char, 0x014F as char, 0x0150 as char, 0x0151 as char,
        0x0152 as char, 0x0153 as char, 0x0154 as char, 0x0155 as char,
        0x0156 as char, 0x0157 as char, 0x0158 as char, 0x0159 as char,
        0x015A as char, 0x015B as char, 0x015C as char, 0x015D as char,
        0x015E as char, 0x015F as char, 0x0160 as char, 0x0161 as char,
        0x0162 as char, 0x0163 as char, 0x0164 as char, 0x0165 as char,
        0x0166 as char, 0x0167 as char, 0x0168 as char, 0x0169 as char,
        0x016A as char, 0x016B as char, 0x016C as char, 0x016D as char,
        0x016E as char, 0x016F as char, 0x0170 as char, 0x0171 as char,
        0x0172 as char, 0x0173 as char, 0x0174 as char, 0x0175 as char,
        0x0176 as char, 0x0177 as char, 0x0178 as char, 0x00FF as char,
        0x0179 as char, 0x017A as char, 0x017B as char, 0x017C as char,
        0x017D as char, 0x017E as char, 0x0181 as char, 0x0253 as char,
        0x0182 as char, 0x0183 as char, 0x0184 as char, 0x0185 as char,
        0x0186 as char, 0x0254 as char, 0x0187 as char, 0x0188 as char,
        0x0189 as char, 0x0256 as char, 0x018A as char, 0x0257 as char,
        0x018B as char, 0x018C as char, 0x018E as char, 0x01DD as char,
        0x018F as char, 0x0259 as char, 0x0190 as char, 0x025B as char,
        0x0191 as char, 0x0192 as char, 0x0193 as char, 0x0260 as char,
        0x0194 as char, 0x0263 as char, 0x0196 as char, 0x0269 as char,
        0x0197 as char, 0x0268 as char, 0x0198 as char, 0x0199 as char,
        0x019C as char, 0x026F as char, 0x019D as char, 0x0272 as char,
        0x019F as char, 0x0275 as char, 0x01A0 as char, 0x01A1 as char,
        0x01A2 as char, 0x01A3 as char, 0x01A4 as char, 0x01A5 as char,
        0x01A6 as char, 0x0280 as char, 0x01A7 as char, 0x01A8 as char,
        0x01A9 as char, 0x0283 as char, 0x01AC as char, 0x01AD as char,
        0x01AE as char, 0x0288 as char, 0x01AF as char, 0x01B0 as char,
        0x01B1 as char, 0x028A as char, 0x01B2 as char, 0x028B as char,
        0x01B3 as char, 0x01B4 as char, 0x01B5 as char, 0x01B6 as char,
        0x01B7 as char, 0x0292 as char, 0x01B8 as char, 0x01B9 as char,
        0x01BC as char, 0x01BD as char, 0x01C4 as char, 0x01C6 as char,
        0x01C5 as char, 0x01C6 as char, 0x01C7 as char, 0x01C9 as char,
        0x01C8 as char, 0x01C9 as char, 0x01CA as char, 0x01CC as char,
        0x01CB as char, 0x01CC as char, 0x01CD as char, 0x01CE as char,
        0x01CF as char, 0x01D0 as char, 0x01D1 as char, 0x01D2 as char,
        0x01D3 as char, 0x01D4 as char, 0x01D5 as char, 0x01D6 as char,
        0x01D7 as char, 0x01D8 as char, 0x01D9 as char, 0x01DA as char,
        0x01DB as char, 0x01DC as char, 0x01DE as char, 0x01DF as char,
        0x01E0 as char, 0x01E1 as char, 0x01E2 as char, 0x01E3 as char,
        0x01E4 as char, 0x01E5 as char, 0x01E6 as char, 0x01E7 as char,
        0x01E8 as char, 0x01E9 as char, 0x01EA as char, 0x01EB as char,
        0x01EC as char, 0x01ED as char, 0x01EE as char, 0x01EF as char,
        0x01F1 as char, 0x01F3 as char, 0x01F2 as char, 0x01F3 as char,
        0x01F4 as char, 0x01F5 as char, 0x01F6 as char, 0x0195 as char,
        0x01F7 as char, 0x01BF as char, 0x01F8 as char, 0x01F9 as char,
        0x01FA as char, 0x01FB as char, 0x01FC as char, 0x01FD as char,
        0x01FE as char, 0x01FF as char,
    ]
}

⍝ U+0200..U+03FF
micro unicode_case_lower_chunk_1() -> [char] {
    return [
        0x0200 as char, 0x0201 as char, 0x0202 as char, 0x0203 as char,
        0x0204 as char, 0x0205 as char, 0x0206 as char, 0x0207 as char,
        0x0208 as char, 0x0209 as char, 0x020A as char, 0x020B as char,
        0x020C as char, 0x020D as char, 0x020E as char, 0x020F as char,
        0x0210 as char, 0x0211 as char, 0x0212 as char, 0x0213 as char,
        0x0214 as char, 0x0215 as char, 0x0216 as char, 0x0217 as char,
        0x0218 as char, 0x0219 as char, 0x021A as char, 0x021B as char,
        0x021C as char, 0x021D as char, 0x021E as char, 0x021F as char,
        0x0220 as char, 0x019E as char, 0x0222 as char, 0x0223 as char,
        0x0224 as char, 0x0225 as char, 0x0226 as char, 0x0227 as char,
        0x0228 as char, 0x0229 as char, 0x022A as char, 0x022B as char,
        0x022C as char, 0x022D as char, 0x022E as char, 0x022F as char,
        0x0230 as char, 0x0231 as char, 0x0232 as char, 0x0233 as char,
        0x023A as char, 0x2C65 as char, 0x023B as char, 0x023C as char,
        0x023D as char, 0x019A as char, 0x023E as char, 0x2C66 as char,
        0x0241 as char, 0x0242 as char, 0x0243 as char, 0x0180 as char,
        0x0244 as char, 0x0289 as char, 0x0245 as char, 0x028C as char,
        0x0246 as char, 0x0247 as char, 0x0248 as char, 0x0249 as char,
        0x024A as char, 0x024B as char, 0x024C as char, 0x024D as char,
        0x024E as char, 0x024F as char, 0x0370 as char, 0x0371 as char,
        0x0372 as char, 0x0373 as char, 0x0376 as char, 0x0377 as char,
        0x037F as char, 0x03F3 as char, 0x0386 as char, 0x03AC as char,
        0x0388 as char, 0x03AD as char, 0x0389 as char, 0x03AE as char,
        0x038A as char, 0x03AF as char, 0x038C as char, 0x03CC as char,
        0x038E as char, 0x03CD as char, 0x038F as char, 0x03CE as char,
        0x0391 as char, 0x03B1 as char, 0x0392 as char, 0x03B2 as char,
        0x0393 as char, 0x03B3 as char, 0x0394 as char, 0x03B4 as char,
        0x0395 as char, 0x03B5 as char, 0x0396 as char, 0x03B6 as char,
        0x0397 as char, 0x03B7 as char, 0x0398 as char, 0x03B8 as char,
        0x0399 as char, 0x03B9 as char, 0x039A as char, 0x03BA as char,
        0x039B as char, 0x03BB as char, 0x039C as char, 0x03BC as char,
        0x039D as char, 0x03BD as char, 0x039E as char, 0x03BE as char,
        0x039F as char, 0x03BF as char, 0x03A0 as char, 0x03C0 as char,
        0x03A1 as char, 0x03C1 as char, 0x03A3 as char, 0x03C3 as char,
        0x03A4 as char, 0x03C4 as char, 0x03A5 as char, 0x03C5 as char,
        0x03A6 as char, 0x03C6 as char, 0x03A7 as char, 0x03C7 as char,
        0x03A8 as char, 0x03C8 as char, 0x03A9 as char, 0x03C9 as char,
        0x03AA as char, 0x03CA as char, 0x03AB as char, 0x03CB as char,
        0x03CF as char, 0x03D7 as char, 0x03D8 as char, 0x03D9 as char,
        0x03DA as char, 0x03DB as char, 0x03DC as char, 0x03DD as char,
        0x03DE as char, 0x03DF as char, 0x03E0 as char, 0x03E1 as char,
        0x03E2 as char, 0x03E3 as char, 0x03E4 as char, 0x03E5 as char,
        0x03E6 as char, 0x03E7 as char, 0x03E8 as char, 0x03E9 as char,
        0x03EA as char, 0x03EB as char, 0x03EC as char, 0x03ED as char,
        0x03EE as char, 0x03EF as char, 0x03F4 as char, 0x03B8 as char,
        0x03F7 as char, 0x03F8 as char, 0x03F9 as char, 0x03F2 as char,
        0x03FA as char, 0x03FB as char, 0x03FD as char, 0x037B as char,
        0x03FE as char, 0x037C as char, 0x03FF as char, 0x037D as char,
    ]
}

⍝ U+0400..U+05FF
micro unicode_case_lower_chunk_2() -> [char] {
    return [
        0x0400 as char, 0x0450 as char, 0x0401 as char, 0x0451 as char,
        0x0402 as char, 0x0452 as char, 0x0403 as char, 0x0453 as char,
        0x0404 as char, 0x0454 as char, 0x0405 as char, 0x0455 as char,
        0x0406 as char, 0x0456 as char, 0x0407 as char, 0x0457 as char,
        0x0408 as char, 0x0458 as char, 0x0409 as char, 0x0459 as char,
        0x040A as char, 0x045A as char, 0x040B as char, 0x045B as char,
        0x040C as char, 0x045C as char, 0x040D as char, 0x045D as char,
        0x040E as char, 0x045E as char, 0x040F as char, 0x045F as char,
        0x0410 as char, 0x0430 as char, 0x0411 as char, 0x0431 as char,
        0x0412 as char, 0x0432 as char, 0x0413 as char, 0x0433 as char,
        0x0414 as char, 0x0434 as char, 0x0415 as char, 0x0435 as char,
        0x0416 as char, 0x0436 as char, 0x0417 as char, 0x0437 as char,
        0x0418 as char, 0x0438 as char, 0x0419 as char, 0x0439 as char,
        0x041A as char, 0x043A as char, 0x041B as char, 0x043B as char,
        0x041C as char, 0x043C as char, 0x041D as char, 0x043D as char,
        0x041E as char, 0x043E as char, 0x041F as char, 0x043F as char,
        0x0420 as char, 0x0440 as char, 0x0421 as char, 0x0441 as char,
        0x0422 as char, 0x0442 as char, 0x0423 as char, 0x0443 as char,
        0x0424 as char, 0x0444 as char, 0x0425 as char, 0x0445 as char,
        0x0426 as char, 0x0446 as char, 0x0427 as char, 0x0447 as char,
        0x0428 as char, 0x0448 as char, 0x0429 as char, 0x0449 as char,
        0x042A as char, 0x044A as char, 0x042B as char, 0x044B as char,
        0x042C as char, 0x044C as char, 0x042D as char, 0x044D as char,
        0x042E as char, 0x044E as char, 0x042F as char, 0x044F as char,
        0x0460 as char, 0x0461 as char, 0x0462 as char, 0x0463 as char,
        0x0464 as char, 0x0465 as char, 0x0466 as char, 0x0467 as char,
        0x0468 as char, 0x0469 as char, 0x046A as char, 0x046B as char,
        0x046C as char, 0x046D as char, 0x046E as char, 0x046F as char,
        0x0470 as char, 0x0471 as char, 0x0472 as char, 0x0473 as char,
        0x0474 as char, 0x0475 as char, 0x0476 as char, 0x0477 as char,
        0x0478 as char, 0x0479 as char, 0x047A as char, 0x047B as char,
        0x047C as char, 0x047D as char, 0x047E as char, 0x047F as char,
        0x0480 as char, 0x0481 as char, 0x048A as char, 0x048B as char,
        0x048C as char, 0x048D as char, 0x048E as char, 0x048F as char,
        0x0490 as char, 0x0491 as char, 0x0492 as char, 0x0493 as char,
        0x0494 as char, 0x0495 as char, 0x0496 as char, 0x0497 as char,
        0x0498 as char, 0x0499 as char, 0x049A as char, 0x049B as char,
        0x049C as char, 0x049D as char, 0x049E as char, 0x049F as char,
        0x04A0 as char, 0x04A1 as char, 0x04A2 as char, 0x04A3 as char,
        0x04A4 as char, 0x04A5 as char, 0x04A6 as char, 0x04A7 as char,
        0x04A8 as char, 0x04A9 as char, 0x04AA as char, 0x04AB as char,
        0x04AC as char, 0x04AD as char, 0x04AE as char, 0x04AF as char,
        0x04B0 as char, 0x04B1 as char, 0x04B2 as char, 0x04B3 as char,
        0x04B4 as char, 0x04B5 as char, 0x04B6 as char, 0x04B7 as char,
        0x04B8 as char, 0x04B9 as char, 0x04BA as char, 0x04BB as char,
        0x04BC as char, 0x04BD as char, 0x04BE as char, 0x04BF as char,
        0x04C0 as char, 0x04CF as char, 0x04C1 as char, 0x04C2 as char,
        0x04C3 as char, 0x04C4 as char, 0x04C5 as char, 0x04C6 as char,
        0x04C7 as char, 0x04C8 as char, 0x04C9 as char, 0x04CA as char,
        0x04CB as char, 0x04CC as char, 0x04CD as char, 0x04CE as char,
        0x04D0 as char, 0x04D1 as char, 0x04D2 as char, 0x04D3 as char,
        0x04D4 as char, 0x04D5 as char, 0x04D6 as char, 0x04D7 as char,
        0x04D8 as char, 0x04D9 as char, 0x04DA as char, 0x04DB as char,
        0x04DC as char, 0x04DD as char, 0x04DE as char, 0x04DF as char,
        0x04E0 as char, 0x04E1 as char, 0x04E2 as char, 0x04E3 as char,
        0x04E4 as char, 0x04E5 as char, 0x04E6 as char, 0x04E7 as char,
        0x04E8 as char, 0x04E9 as char, 0x04EA as char, 0x04EB as char,
        0x04EC as char, 0x04ED as char, 0x04EE as char, 0x04EF as char,
        0x04F0 as char, 0x04F1 as char, 0x04F2 as char, 0x04F3 as char,
        0x04F4 as char, 0x04F5 as char, 0x04F6 as char, 0x04F7 as char,
        0x04F8 as char, 0x04F9 as char, 0x04FA as char, 0x04FB as char,
        0x04FC as char, 0x04FD as char, 0x04FE as char, 0x04FF as char,
        0x0500 as char, 0x0501 as char, 0x0502 as char, 0x0503 as char,
        0x0504 as char, 0x0505 as char, 0x0506 as char, 0x0507 as char,
        0x0508 as char, 0x0509 as char, 0x050A as char, 0x050B as char,
        0x050C as char, 0x050D as char, 0x050E as char, 0x050F as char,
        0x0510 as char, 0x0511 as char, 0x0512 as char, 0x0513 as char,
        0x0514 as char, 0x0515 as char, 0x0516 as char, 0x0517 as char,
        0x0518 as char, 0x0519 as char, 0x051A as char, 0x051B as char,
        0x051C as char, 0x051D as char, 0x051E as char, 0x051F as char,
        0x0520 as char, 0x0521 as char, 0x0522 as char, 0x0523 as char,
        0x0524 as char, 0x0525 as char, 0x0526 as char, 0x0527 as char,
        0x0528 as char, 0x0529 as char, 0x052A as char, 0x052B as char,
        0x052C as char, 0x052D as char, 0x052E as char, 0x052F as char,
        0x0531 as char, 0x0561 as char, 0x0532 as char, 0x0562 as char,
        0x0533 as char, 0x0563 as char, 0x0534 as char, 0x0564 as char,
        0x0535 as char, 0x0565 as char, 0x0536 as char, 0x0566 as char,
        0x0537 as char, 0x0567 as char, 0x0538 as char, 0x0568 as char,
        0x0539 as char, 0x0569 as char, 0x053A as char, 0x056A as char,
        0x053B as char, 0x056B as char, 0x053C as char, 0x056C as char,
        0x053D as char, 0x056D as char, 0x053E as char, 0x056E as char,
        0x053F as char, 0x056F as char, 0x0540 as char, 0x0570 as char,
        0x0541 as char, 0x0571 as char, 0x0542 as char, 0x0572 as char,
        0x0543 as char, 0x0573 as char, 0x0544 as char, 0x0574 as char,
        0x0545 as char, 0x0575 as char, 0x0546 as char, 0x0576 as char,
        0x0547 as char, 0x0577 as char, 0x0548 as char, 0x0578 as char,
        0x0549 as char, 0x0579 as char, 0x054A as char, 0x057A as char,
        0x054B as char, 0x057B as char, 0x054C as char, 0x057C as char,
        0x054D as char, 0x057D as char, 0x054E as char, 0x057E as char,
        0x054F as char, 0x057F as char, 0x0550 as char, 0x0580 as char,
        0x0551 as char, 0x0581 as char, 0x0552 as char, 0x0582 as char,
        0x0553 as char, 0x0583 as char, 0x0554 as char, 0x0584 as char,
        0x0555 as char, 0x0585 as char, 0x0556 as char, 0x0586 as char,
    ]
}

⍝ U+0600..U+07FF
micro unicode_case_lower_chunk_3() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0800..U+09FF
micro unicode_case_lower_chunk_4() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0A00..U+0BFF
micro unicode_case_lower_chunk_5() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0C00..U+0DFF
micro unicode_case_lower_chunk_6() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0E00..U+0FFF
micro unicode_case_lower_chunk_7() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1000..U+11FF
micro unicode_case_lower_chunk_8() -> [char] {
    return [
        0x10A0 as char, 0x2D00 as char, 0x10A1 as char, 0x2D01 as char,
        0x10A2 as char, 0x2D02 as char, 0x10A3 as char, 0x2D03 as char,
        0x10A4 as char, 0x2D04 as char, 0x10A5 as char, 0x2D05 as char,
        0x10A6 as char, 0x2D06 as char, 0x10A7 as char, 0x2D07 as char,
        0x10A8 as char, 0x2D08 as char, 0x10A9 as char, 0x2D09 as char,
        0x10AA as char, 0x2D0A as char, 0x10AB as char, 0x2D0B as char,
        0x10AC as char, 0x2D0C as char, 0x10AD as char, 0x2D0D as char,
        0x10AE as char, 0x2D0E as char, 0x10AF as char, 0x2D0F as char,
        0x10B0 as char, 0x2D10 as char, 0x10B1 as char, 0x2D11 as char,
        0x10B2 as char, 0x2D12 as char, 0x10B3 as char, 0x2D13 as char,
        0x10B4 as char, 0x2D14 as char, 0x10B5 as char, 0x2D15 as char,
        0x10B6 as char, 0x2D16 as char, 0x10B7 as char, 0x2D17 as char,
        0x10B8 as char, 0x2D18 as char, 0x10B9 as char, 0x2D19 as char,
        0x10BA as char, 0x2D1A as char, 0x10BB as char, 0x2D1B as char,
        0x10BC as char, 0x2D1C as char, 0x10BD as char, 0x2D1D as char,
        0x10BE as char, 0x2D1E as char, 0x10BF as char, 0x2D1F as char,
        0x10C0 as char, 0x2D20 as char, 0x10C1 as char, 0x2D21 as char,
        0x10C2 as char, 0x2D22 as char, 0x10C3 as char, 0x2D23 as char,
        0x10C4 as char, 0x2D24 as char, 0x10C5 as char, 0x2D25 as char,
        0x10C7 as char, 0x2D27 as char, 0x10CD as char, 0x2D2D as char,
    ]
}

⍝ U+1200..U+13FF
micro unicode_case_lower_chunk_9() -> [char] {
    return [
        0x13A0 as char, 0xAB70 as char, 0x13A1 as char, 0xAB71 as char,
        0x13A2 as char, 0xAB72 as char, 0x13A3 as char, 0xAB73 as char,
        0x13A4 as char, 0xAB74 as char, 0x13A5 as char, 0xAB75 as char,
        0x13A6 as char, 0xAB76 as char, 0x13A7 as char, 0xAB77 as char,
        0x13A8 as char, 0xAB78 as char, 0x13A9 as char, 0xAB79 as char,
        0x13AA as char, 0xAB7A as char, 0x13AB as char, 0xAB7B as char,
        0x13AC as char, 0xAB7C as char, 0x13AD as char, 0xAB7D as char,
        0x13AE as char, 0xAB7E as char, 0x13AF as char, 0xAB7F as char,
        0x13B0 as char, 0xAB80 as char, 0x13B1 as char, 0xAB81 as char,
        0x13B2 as char, 0xAB82 as char, 0x13B3 as char, 0xAB83 as char,
        0x13B4 as char, 0xAB84 as char, 0x13B5 as char, 0xAB85 as char,
        0x13B6 as char, 0xAB86 as char, 0x13B7 as char, 0xAB87 as char,
        0x13B8 as char, 0xAB88 as char, 0x13B9 as char, 0xAB89 as char,
        0x13BA as char, 0xAB8A as char, 0x13BB as char, 0xAB8B as char,
        0x13BC as char, 0xAB8C as char, 0x13BD as char, 0xAB8D as char,
        0x13BE as char, 0xAB8E as char, 0x13BF as char, 0xAB8F as char,
        0x13C0 as char, 0xAB90 as char, 0x13C1 as char, 0xAB91 as char,
        0x13C2 as char, 0xAB92 as char, 0x13C3 as char, 0xAB93 as char,
        0x13C4 as char, 0xAB94 as char, 0x13C5 as char, 0xAB95 as char,
        0x13C6 as char, 0xAB96 as char, 0x13C7 as char, 0xAB97 as char,
        0x13C8 as char, 0xAB98 as char, 0x13C9 as char, 0xAB99 as char,
        0x13CA as char, 0xAB9A as char, 0x13CB as char, 0xAB9B as char,
        0x13CC as char, 0xAB9C as char, 0x13CD as char, 0xAB9D as char,
        0x13CE as char, 0xAB9E as char, 0x13CF as char, 0xAB9F as char,
        0x13D0 as char, 0xABA0 as char, 0x13D1 as char, 0xABA1 as char,
        0x13D2 as char, 0xABA2 as char, 0x13D3 as char, 0xABA3 as char,
        0x13D4 as char, 0xABA4 as char, 0x13D5 as char, 0xABA5 as char,
        0x13D6 as char, 0xABA6 as char, 0x13D7 as char, 0xABA7 as char,
        0x13D8 as char, 0xABA8 as char, 0x13D9 as char, 0xABA9 as char,
        0x13DA as char, 0xABAA as char, 0x13DB as char, 0xABAB as char,
        0x13DC as char, 0xABAC as char, 0x13DD as char, 0xABAD as char,
        0x13DE as char, 0xABAE as char, 0x13DF as char, 0xABAF as char,
        0x13E0 as char, 0xABB0 as char, 0x13E1 as char, 0xABB1 as char,
        0x13E2 as char, 0xABB2 as char, 0x13E3 as char, 0xABB3 as char,
        0x13E4 as char, 0xABB4 as char, 0x13E5 as char, 0xABB5 as char,
        0x13E6 as char, 0xABB6 as char, 0x13E7 as char, 0xABB7 as char,
        0x13E8 as char, 0xABB8 as char, 0x13E9 as char, 0xABB9 as char,
        0x13EA as char, 0xABBA as char, 0x13EB as char, 0xABBB as char,
        0x13EC as char, 0xABBC as char, 0x13ED as char, 0xABBD as char,
        0x13EE as char, 0xABBE as char, 0x13EF as char, 0xABBF as char,
        0x13F0 as char, 0x13F8 as char, 0x13F1 as char, 0x13F9 as char,
        0x13F2 as char, 0x13FA as char, 0x13F3 as char, 0x13FB as char,
        0x13F4 as char, 0x13FC as char, 0x13F5 as char, 0x13FD as char,
    ]
}

⍝ U+1400..U+15FF
micro unicode_case_lower_chunk_10() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1600..U+17FF
micro unicode_case_lower_chunk_11() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1800..U+19FF
micro unicode_case_lower_chunk_12() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1A00..U+1BFF
micro unicode_case_lower_chunk_13() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1C00..U+1DFF
micro unicode_case_lower_chunk_14() -> [char] {
    return [
        0x1C89 as char, 0x1C8A as char, 0x1C90 as char, 0x10D0 as char,
        0x1C91 as char, 0x10D1 as char, 0x1C92 as char, 0x10D2 as char,
        0x1C93 as char, 0x10D3 as char, 0x1C94 as char, 0x10D4 as char,
        0x1C95 as char, 0x10D5 as char, 0x1C96 as char, 0x10D6 as char,
        0x1C97 as char, 0x10D7 as char, 0x1C98 as char, 0x10D8 as char,
        0x1C99 as char, 0x10D9 as char, 0x1C9A as char, 0x10DA as char,
        0x1C9B as char, 0x10DB as char, 0x1C9C as char, 0x10DC as char,
        0x1C9D as char, 0x10DD as char, 0x1C9E as char, 0x10DE as char,
        0x1C9F as char, 0x10DF as char, 0x1CA0 as char, 0x10E0 as char,
        0x1CA1 as char, 0x10E1 as char, 0x1CA2 as char, 0x10E2 as char,
        0x1CA3 as char, 0x10E3 as char, 0x1CA4 as char, 0x10E4 as char,
        0x1CA5 as char, 0x10E5 as char, 0x1CA6 as char, 0x10E6 as char,
        0x1CA7 as char, 0x10E7 as char, 0x1CA8 as char, 0x10E8 as char,
        0x1CA9 as char, 0x10E9 as char, 0x1CAA as char, 0x10EA as char,
        0x1CAB as char, 0x10EB as char, 0x1CAC as char, 0x10EC as char,
        0x1CAD as char, 0x10ED as char, 0x1CAE as char, 0x10EE as char,
        0x1CAF as char, 0x10EF as char, 0x1CB0 as char, 0x10F0 as char,
        0x1CB1 as char, 0x10F1 as char, 0x1CB2 as char, 0x10F2 as char,
        0x1CB3 as char, 0x10F3 as char, 0x1CB4 as char, 0x10F4 as char,
        0x1CB5 as char, 0x10F5 as char, 0x1CB6 as char, 0x10F6 as char,
        0x1CB7 as char, 0x10F7 as char, 0x1CB8 as char, 0x10F8 as char,
        0x1CB9 as char, 0x10F9 as char, 0x1CBA as char, 0x10FA as char,
        0x1CBD as char, 0x10FD as char, 0x1CBE as char, 0x10FE as char,
        0x1CBF as char, 0x10FF as char,
    ]
}

⍝ U+1E00..U+1FFF
micro unicode_case_lower_chunk_15() -> [char] {
    return [
        0x1E00 as char, 0x1E01 as char, 0x1E02 as char, 0x1E03 as char,
        0x1E04 as char, 0x1E05 as char, 0x1E06 as char, 0x1E07 as char,
        0x1E08 as char, 0x1E09 as char, 0x1E0A as char, 0x1E0B as char,
        0x1E0C as char, 0x1E0D as char, 0x1E0E as char, 0x1E0F as char,
        0x1E10 as char, 0x1E11 as char, 0x1E12 as char, 0x1E13 as char,
        0x1E14 as char, 0x1E15 as char, 0x1E16 as char, 0x1E17 as char,
        0x1E18 as char, 0x1E19 as char, 0x1E1A as char, 0x1E1B as char,
        0x1E1C as char, 0x1E1D as char, 0x1E1E as char, 0x1E1F as char,
        0x1E20 as char, 0x1E21 as char, 0x1E22 as char, 0x1E23 as char,
        0x1E24 as char, 0x1E25 as char, 0x1E26 as char, 0x1E27 as char,
        0x1E28 as char, 0x1E29 as char, 0x1E2A as char, 0x1E2B as char,
        0x1E2C as char, 0x1E2D as char, 0x1E2E as char, 0x1E2F as char,
        0x1E30 as char, 0x1E31 as char, 0x1E32 as char, 0x1E33 as char,
        0x1E34 as char, 0x1E35 as char, 0x1E36 as char, 0x1E37 as char,
        0x1E38 as char, 0x1E39 as char, 0x1E3A as char, 0x1E3B as char,
        0x1E3C as char, 0x1E3D as char, 0x1E3E as char, 0x1E3F as char,
        0x1E40 as char, 0x1E41 as char, 0x1E42 as char, 0x1E43 as char,
        0x1E44 as char, 0x1E45 as char, 0x1E46 as char, 0x1E47 as char,
        0x1E48 as char, 0x1E49 as char, 0x1E4A as char, 0x1E4B as char,
        0x1E4C as char, 0x1E4D as char, 0x1E4E as char, 0x1E4F as char,
        0x1E50 as char, 0x1E51 as char, 0x1E52 as char, 0x1E53 as char,
        0x1E54 as char, 0x1E55 as char, 0x1E56 as char, 0x1E57 as char,
        0x1E58 as char, 0x1E59 as char, 0x1E5A as char, 0x1E5B as char,
        0x1E5C as char, 0x1E5D as char, 0x1E5E as char, 0x1E5F as char,
        0x1E60 as char, 0x1E61 as char, 0x1E62 as char, 0x1E63 as char,
        0x1E64 as char, 0x1E65 as char, 0x1E66 as char, 0x1E67 as char,
        0x1E68 as char, 0x1E69 as char, 0x1E6A as char, 0x1E6B as char,
        0x1E6C as char, 0x1E6D as char, 0x1E6E as char, 0x1E6F as char,
        0x1E70 as char, 0x1E71 as char, 0x1E72 as char, 0x1E73 as char,
        0x1E74 as char, 0x1E75 as char, 0x1E76 as char, 0x1E77 as char,
        0x1E78 as char, 0x1E79 as char, 0x1E7A as char, 0x1E7B as char,
        0x1E7C as char, 0x1E7D as char, 0x1E7E as char, 0x1E7F as char,
        0x1E80 as char, 0x1E81 as char, 0x1E82 as char, 0x1E83 as char,
        0x1E84 as char, 0x1E85 as char, 0x1E86 as char, 0x1E87 as char,
        0x1E88 as char, 0x1E89 as char, 0x1E8A as char, 0x1E8B as char,
        0x1E8C as char, 0x1E8D as char, 0x1E8E as char, 0x1E8F as char,
        0x1E90 as char, 0x1E91 as char, 0x1E92 as char, 0x1E93 as char,
        0x1E94 as char, 0x1E95 as char, 0x1E9E as char, 0x00DF as char,
        0x1EA0 as char, 0x1EA1 as char, 0x1EA2 as char, 0x1EA3 as char,
        0x1EA4 as char, 0x1EA5 as char, 0x1EA6 as char, 0x1EA7 as char,
        0x1EA8 as char, 0x1EA9 as char, 0x1EAA as char, 0x1EAB as char,
        0x1EAC as char, 0x1EAD as char, 0x1EAE as char, 0x1EAF as char,
        0x1EB0 as char, 0x1EB1 as char, 0x1EB2 as char, 0x1EB3 as char,
        0x1EB4 as char, 0x1EB5 as char, 0x1EB6 as char, 0x1EB7 as char,
        0x1EB8 as char, 0x1EB9 as char, 0x1EBA as char, 0x1EBB as char,
        0x1EBC as char, 0x1EBD as char, 0x1EBE as char, 0x1EBF as char,
        0x1EC0 as char, 0x1EC1 as char, 0x1EC2 as char, 0x1EC3 as char,
        0x1EC4 as char, 0x1EC5 as char, 0x1EC6 as char, 0x1EC7 as char,
        0x1EC8 as char, 0x1EC9 as char, 0x1ECA as char, 0x1ECB as char,
        0x1ECC as char, 0x1ECD as char, 0x1ECE as char, 0x1ECF as char,
        0x1ED0 as char, 0x1ED1 as char, 0x1ED2 as char, 0x1ED3 as char,
        0x1ED4 as char, 0x1ED5 as char, 0x1ED6 as char, 0x1ED7 as char,
        0x1ED8 as char, 0x1ED9 as char, 0x1EDA as char, 0x1EDB as char,
        0x1EDC as char, 0x1EDD as char, 0x1EDE as char, 0x1EDF as char,
        0x1EE0 as char, 0x1EE1 as char, 0x1EE2 as char, 0x1EE3 as char,
        0x1EE4 as char, 0x1EE5 as char, 0x1EE6 as char, 0x1EE7 as char,
        0x1EE8 as char, 0x1EE9 as char, 0x1EEA as char, 0x1EEB as char,
        0x1EEC as char, 0x1EED as char, 0x1EEE as char, 0x1EEF as char,
        0x1EF0 as char, 0x1EF1 as char, 0x1EF2 as char, 0x1EF3 as char,
        0x1EF4 as char, 0x1EF5 as char, 0x1EF6 as char, 0x1EF7 as char,
        0x1EF8 as char, 0x1EF9 as char, 0x1EFA as char, 0x1EFB as char,
        0x1EFC as char, 0x1EFD as char, 0x1EFE as char, 0x1EFF as char,
        0x1F08 as char, 0x1F00 as char, 0x1F09 as char, 0x1F01 as char,
        0x1F0A as char, 0x1F02 as char, 0x1F0B as char, 0x1F03 as char,
        0x1F0C as char, 0x1F04 as char, 0x1F0D as char, 0x1F05 as char,
        0x1F0E as char, 0x1F06 as char, 0x1F0F as char, 0x1F07 as char,
        0x1F18 as char, 0x1F10 as char, 0x1F19 as char, 0x1F11 as char,
        0x1F1A as char, 0x1F12 as char, 0x1F1B as char, 0x1F13 as char,
        0x1F1C as char, 0x1F14 as char, 0x1F1D as char, 0x1F15 as char,
        0x1F28 as char, 0x1F20 as char, 0x1F29 as char, 0x1F21 as char,
        0x1F2A as char, 0x1F22 as char, 0x1F2B as char, 0x1F23 as char,
        0x1F2C as char, 0x1F24 as char, 0x1F2D as char, 0x1F25 as char,
        0x1F2E as char, 0x1F26 as char, 0x1F2F as char, 0x1F27 as char,
        0x1F38 as char, 0x1F30 as char, 0x1F39 as char, 0x1F31 as char,
        0x1F3A as char, 0x1F32 as char, 0x1F3B as char, 0x1F33 as char,
        0x1F3C as char, 0x1F34 as char, 0x1F3D as char, 0x1F35 as char,
        0x1F3E as char, 0x1F36 as char, 0x1F3F as char, 0x1F37 as char,
        0x1F48 as char, 0x1F40 as char, 0x1F49 as char, 0x1F41 as char,
        0x1F4A as char, 0x1F42 as char, 0x1F4B as char, 0x1F43 as char,
        0x1F4C as char, 0x1F44 as char, 0x1F4D as char, 0x1F45 as char,
        0x1F59 as char, 0x1F51 as char, 0x1F5B as char, 0x1F53 as char,
        0x1F5D as char, 0x1F55 as char, 0x1F5F as char, 0x1F57 as char,
        0x1F68 as char, 0x1F60 as char, 0x1F69 as char, 0x1F61 as char,
        0x1F6A as char, 0x1F62 as char, 0x1F6B as char, 0x1F63 as char,
        0x1F6C as char, 0x1F64 as char, 0x1F6D as char, 0x1F65 as char,
        0x1F6E as char, 0x1F66 as char, 0x1F6F as char, 0x1F67 as char,
        0x1F88 as char, 0x1F80 as char, 0x1F89 as char, 0x1F81 as char,
        0x1F8A as char, 0x1F82 as char, 0x1F8B as char, 0x1F83 as char,
        0x1F8C as char, 0x1F84 as char, 0x1F8D as char, 0x1F85 as char,
        0x1F8E as char, 0x1F86 as char, 0x1F8F as char, 0x1F87 as char,
        0x1F98 as char, 0x1F90 as char, 0x1F99 as char, 0x1F91 as char,
        0x1F9A as char, 0x1F92 as char, 0x1F9B as char, 0x1F93 as char,
        0x1F9C as char, 0x1F94 as char, 0x1F9D as char, 0x1F95 as char,
        0x1F9E as char, 0x1F96 as char, 0x1F9F as char, 0x1F97 as char,
        0x1FA8 as char, 0x1FA0 as char, 0x1FA9 as char, 0x1FA1 as char,
        0x1FAA as char, 0x1FA2 as char, 0x1FAB as char, 0x1FA3 as char,
        0x1FAC as char, 0x1FA4 as char, 0x1FAD as char, 0x1FA5 as char,
        0x1FAE as char, 0x1FA6 as char, 0x1FAF as char, 0x1FA7 as char,
        0x1FB8 as char, 0x1FB0 as char, 0x1FB9 as char, 0x1FB1 as char,
        0x1FBA as char, 0x1F70 as char, 0x1FBB as char, 0x1F71 as char,
        0x1FBC as char, 0x1FB3 as char, 0x1FC8 as char, 0x1F72 as char,
        0x1FC9 as char, 0x1F73 as char, 0x1FCA as char, 0x1F74 as char,
        0x1FCB as char, 0x1F75 as char, 0x1FCC as char, 0x1FC3 as char,
        0x1FD8 as char, 0x1FD0 as char, 0x1FD9 as char, 0x1FD1 as char,
        0x1FDA as char, 0x1F76 as char, 0x1FDB as char, 0x1F77 as char,
        0x1FE8 as char, 0x1FE0 as char, 0x1FE9 as char, 0x1FE1 as char,
        0x1FEA as char, 0x1F7A as char, 0x1FEB as char, 0x1F7B as char,
        0x1FEC as char, 0x1FE5 as char, 0x1FF8 as char, 0x1F78 as char,
        0x1FF9 as char, 0x1F79 as char, 0x1FFA as char, 0x1F7C as char,
        0x1FFB as char, 0x1F7D as char, 0x1FFC as char, 0x1FF3 as char,
    ]
}

⍝ U+2000..U+21FF
micro unicode_case_lower_chunk_16() -> [char] {
    return [
        0x2126 as char, 0x03C9 as char, 0x212A as char, 0x006B as char,
        0x212B as char, 0x00E5 as char, 0x2132 as char, 0x214E as char,
        0x2160 as char, 0x2170 as char, 0x2161 as char, 0x2171 as char,
        0x2162 as char, 0x2172 as char, 0x2163 as char, 0x2173 as char,
        0x2164 as char, 0x2174 as char, 0x2165 as char, 0x2175 as char,
        0x2166 as char, 0x2176 as char, 0x2167 as char, 0x2177 as char,
        0x2168 as char, 0x2178 as char, 0x2169 as char, 0x2179 as char,
        0x216A as char, 0x217A as char, 0x216B as char, 0x217B as char,
        0x216C as char, 0x217C as char, 0x216D as char, 0x217D as char,
        0x216E as char, 0x217E as char, 0x216F as char, 0x217F as char,
        0x2183 as char, 0x2184 as char,
    ]
}

⍝ U+2200..U+23FF
micro unicode_case_lower_chunk_17() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2400..U+25FF
micro unicode_case_lower_chunk_18() -> [char] {
    return [
        0x24B6 as char, 0x24D0 as char, 0x24B7 as char, 0x24D1 as char,
        0x24B8 as char, 0x24D2 as char, 0x24B9 as char, 0x24D3 as char,
        0x24BA as char, 0x24D4 as char, 0x24BB as char, 0x24D5 as char,
        0x24BC as char, 0x24D6 as char, 0x24BD as char, 0x24D7 as char,
        0x24BE as char, 0x24D8 as char, 0x24BF as char, 0x24D9 as char,
        0x24C0 as char, 0x24DA as char, 0x24C1 as char, 0x24DB as char,
        0x24C2 as char, 0x24DC as char, 0x24C3 as char, 0x24DD as char,
        0x24C4 as char, 0x24DE as char, 0x24C5 as char, 0x24DF as char,
        0x24C6 as char, 0x24E0 as char, 0x24C7 as char, 0x24E1 as char,
        0x24C8 as char, 0x24E2 as char, 0x24C9 as char, 0x24E3 as char,
        0x24CA as char, 0x24E4 as char, 0x24CB as char, 0x24E5 as char,
        0x24CC as char, 0x24E6 as char, 0x24CD as char, 0x24E7 as char,
        0x24CE as char, 0x24E8 as char, 0x24CF as char, 0x24E9 as char,
    ]
}

⍝ U+2600..U+27FF
micro unicode_case_lower_chunk_19() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2800..U+29FF
micro unicode_case_lower_chunk_20() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2A00..U+2BFF
micro unicode_case_lower_chunk_21() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2C00..U+2DFF
micro unicode_case_lower_chunk_22() -> [char] {
    return [
        0x2C00 as char, 0x2C30 as char, 0x2C01 as char, 0x2C31 as char,
        0x2C02 as char, 0x2C32 as char, 0x2C03 as char, 0x2C33 as char,
        0x2C04 as char, 0x2C34 as char, 0x2C05 as char, 0x2C35 as char,
        0x2C06 as char, 0x2C36 as char, 0x2C07 as char, 0x2C37 as char,
        0x2C08 as char, 0x2C38 as char, 0x2C09 as char, 0x2C39 as char,
        0x2C0A as char, 0x2C3A as char, 0x2C0B as char, 0x2C3B as char,
        0x2C0C as char, 0x2C3C as char, 0x2C0D as char, 0x2C3D as char,
        0x2C0E as char, 0x2C3E as char, 0x2C0F as char, 0x2C3F as char,
        0x2C10 as char, 0x2C40 as char, 0x2C11 as char, 0x2C41 as char,
        0x2C12 as char, 0x2C42 as char, 0x2C13 as char, 0x2C43 as char,
        0x2C14 as char, 0x2C44 as char, 0x2C15 as char, 0x2C45 as char,
        0x2C16 as char, 0x2C46 as char, 0x2C17 as char, 0x2C47 as char,
        0x2C18 as char, 0x2C48 as char, 0x2C19 as char, 0x2C49 as char,
        0x2C1A as char, 0x2C4A as char, 0x2C1B as char, 0x2C4B as char,
        0x2C1C as char, 0x2C4C as char, 0x2C1D as char, 0x2C4D as char,
        0x2C1E as char, 0x2C4E as char, 0x2C1F as char, 0x2C4F as char,
        0x2C20 as char, 0x2C50 as char, 0x2C21 as char, 0x2C51 as char,
        0x2C22 as char, 0x2C52 as char, 0x2C23 as char, 0x2C53 as char,
        0x2C24 as char, 0x2C54 as char, 0x2C25 as char, 0x2C55 as char,
        0x2C26 as char, 0x2C56 as char, 0x2C27 as char, 0x2C57 as char,
        0x2C28 as char, 0x2C58 as char, 0x2C29 as char, 0x2C59 as char,
        0x2C2A as char, 0x2C5A as char, 0x2C2B as char, 0x2C5B as char,
        0x2C2C as char, 0x2C5C as char, 0x2C2D as char, 0x2C5D as char,
        0x2C2E as char, 0x2C5E as char, 0x2C2F as char, 0x2C5F as char,
        0x2C60 as char, 0x2C61 as char, 0x2C62 as char, 0x026B as char,
        0x2C63 as char, 0x1D7D as char, 0x2C64 as char, 0x027D as char,
        0x2C67 as char, 0x2C68 as char, 0x2C69 as char, 0x2C6A as char,
        0x2C6B as char, 0x2C6C as char, 0x2C6D as char, 0x0251 as char,
        0x2C6E as char, 0x0271 as char, 0x2C6F as char, 0x0250 as char,
        0x2C70 as char, 0x0252 as char, 0x2C72 as char, 0x2C73 as char,
        0x2C75 as char, 0x2C76 as char, 0x2C7E as char, 0x023F as char,
        0x2C7F as char, 0x0240 as char, 0x2C80 as char, 0x2C81 as char,
        0x2C82 as char, 0x2C83 as char, 0x2C84 as char, 0x2C85 as char,
        0x2C86 as char, 0x2C87 as char, 0x2C88 as char, 0x2C89 as char,
        0x2C8A as char, 0x2C8B as char, 0x2C8C as char, 0x2C8D as char,
        0x2C8E as char, 0x2C8F as char, 0x2C90 as char, 0x2C91 as char,
        0x2C92 as char, 0x2C93 as char, 0x2C94 as char, 0x2C95 as char,
        0x2C96 as char, 0x2C97 as char, 0x2C98 as char, 0x2C99 as char,
        0x2C9A as char, 0x2C9B as char, 0x2C9C as char, 0x2C9D as char,
        0x2C9E as char, 0x2C9F as char, 0x2CA0 as char, 0x2CA1 as char,
        0x2CA2 as char, 0x2CA3 as char, 0x2CA4 as char, 0x2CA5 as char,
        0x2CA6 as char, 0x2CA7 as char, 0x2CA8 as char, 0x2CA9 as char,
        0x2CAA as char, 0x2CAB as char, 0x2CAC as char, 0x2CAD as char,
        0x2CAE as char, 0x2CAF as char, 0x2CB0 as char, 0x2CB1 as char,
        0x2CB2 as char, 0x2CB3 as char, 0x2CB4 as char, 0x2CB5 as char,
        0x2CB6 as char, 0x2CB7 as char, 0x2CB8 as char, 0x2CB9 as char,
        0x2CBA as char, 0x2CBB as char, 0x2CBC as char, 0x2CBD as char,
        0x2CBE as char, 0x2CBF as char, 0x2CC0 as char, 0x2CC1 as char,
        0x2CC2 as char, 0x2CC3 as char, 0x2CC4 as char, 0x2CC5 as char,
        0x2CC6 as char, 0x2CC7 as char, 0x2CC8 as char, 0x2CC9 as char,
        0x2CCA as char, 0x2CCB as char, 0x2CCC as char, 0x2CCD as char,
        0x2CCE as char, 0x2CCF as char, 0x2CD0 as char, 0x2CD1 as char,
        0x2CD2 as char, 0x2CD3 as char, 0x2CD4 as char, 0x2CD5 as char,
        0x2CD6 as char, 0x2CD7 as char, 0x2CD8 as char, 0x2CD9 as char,
        0x2CDA as char, 0x2CDB as char, 0x2CDC as char, 0x2CDD as char,
        0x2CDE as char, 0x2CDF as char, 0x2CE0 as char, 0x2CE1 as char,
        0x2CE2 as char, 0x2CE3 as char, 0x2CEB as char, 0x2CEC as char,
        0x2CED as char, 0x2CEE as char, 0x2CF2 as char, 0x2CF3 as char,
    ]
}

⍝ U+2E00..U+2FFF
micro unicode_case_lower_chunk_23() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3000..U+31FF
micro unicode_case_lower_chunk_24() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3200..U+33FF
micro unicode_case_lower_chunk_25() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3400..U+35FF
micro unicode_case_lower_chunk_26() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3600..U+37FF
micro unicode_case_lower_chunk_27() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3800..U+39FF
micro unicode_case_lower_chunk_28() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3A00..U+3BFF
micro unicode_case_lower_chunk_29() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3C00..U+3DFF
micro unicode_case_lower_chunk_30() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3E00..U+3FFF
micro unicode_case_lower_chunk_31() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4000..U+41FF
micro unicode_case_lower_chunk_32() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4200..U+43FF
micro unicode_case_lower_chunk_33() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4400..U+45FF
micro unicode_case_lower_chunk_34() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4600..U+47FF
micro unicode_case_lower_chunk_35() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4800..U+49FF
micro unicode_case_lower_chunk_36() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4A00..U+4BFF
micro unicode_case_lower_chunk_37() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4C00..U+4DFF
micro unicode_case_lower_chunk_38() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4E00..U+4FFF
micro unicode_case_lower_chunk_39() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5000..U+51FF
micro unicode_case_lower_chunk_40() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5200..U+53FF
micro unicode_case_lower_chunk_41() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5400..U+55FF
micro unicode_case_lower_chunk_42() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5600..U+57FF
micro unicode_case_lower_chunk_43() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5800..U+59FF
micro unicode_case_lower_chunk_44() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5A00..U+5BFF
micro unicode_case_lower_chunk_45() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5C00..U+5DFF
micro unicode_case_lower_chunk_46() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5E00..U+5FFF
micro unicode_case_lower_chunk_47() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6000..U+61FF
micro unicode_case_lower_chunk_48() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6200..U+63FF
micro unicode_case_lower_chunk_49() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6400..U+65FF
micro unicode_case_lower_chunk_50() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6600..U+67FF
micro unicode_case_lower_chunk_51() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6800..U+69FF
micro unicode_case_lower_chunk_52() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6A00..U+6BFF
micro unicode_case_lower_chunk_53() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6C00..U+6DFF
micro unicode_case_lower_chunk_54() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6E00..U+6FFF
micro unicode_case_lower_chunk_55() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7000..U+71FF
micro unicode_case_lower_chunk_56() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7200..U+73FF
micro unicode_case_lower_chunk_57() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7400..U+75FF
micro unicode_case_lower_chunk_58() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7600..U+77FF
micro unicode_case_lower_chunk_59() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7800..U+79FF
micro unicode_case_lower_chunk_60() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7A00..U+7BFF
micro unicode_case_lower_chunk_61() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7C00..U+7DFF
micro unicode_case_lower_chunk_62() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7E00..U+7FFF
micro unicode_case_lower_chunk_63() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8000..U+81FF
micro unicode_case_lower_chunk_64() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8200..U+83FF
micro unicode_case_lower_chunk_65() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8400..U+85FF
micro unicode_case_lower_chunk_66() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8600..U+87FF
micro unicode_case_lower_chunk_67() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8800..U+89FF
micro unicode_case_lower_chunk_68() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8A00..U+8BFF
micro unicode_case_lower_chunk_69() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8C00..U+8DFF
micro unicode_case_lower_chunk_70() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8E00..U+8FFF
micro unicode_case_lower_chunk_71() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9000..U+91FF
micro unicode_case_lower_chunk_72() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9200..U+93FF
micro unicode_case_lower_chunk_73() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9400..U+95FF
micro unicode_case_lower_chunk_74() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9600..U+97FF
micro unicode_case_lower_chunk_75() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9800..U+99FF
micro unicode_case_lower_chunk_76() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9A00..U+9BFF
micro unicode_case_lower_chunk_77() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9C00..U+9DFF
micro unicode_case_lower_chunk_78() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9E00..U+9FFF
micro unicode_case_lower_chunk_79() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A000..U+A1FF
micro unicode_case_lower_chunk_80() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A200..U+A3FF
micro unicode_case_lower_chunk_81() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A400..U+A5FF
micro unicode_case_lower_chunk_82() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A600..U+A7FF
micro unicode_case_lower_chunk_83() -> [char] {
    return [
        0xA640 as char, 0xA641 as char, 0xA642 as char, 0xA643 as char,
        0xA644 as char, 0xA645 as char, 0xA646 as char, 0xA647 as char,
        0xA648 as char, 0xA649 as char, 0xA64A as char, 0xA64B as char,
        0xA64C as char, 0xA64D as char, 0xA64E as char, 0xA64F as char,
        0xA650 as char, 0xA651 as char, 0xA652 as char, 0xA653 as char,
        0xA654 as char, 0xA655 as char, 0xA656 as char, 0xA657 as char,
        0xA658 as char, 0xA659 as char, 0xA65A as char, 0xA65B as char,
        0xA65C as char, 0xA65D as char, 0xA65E as char, 0xA65F as char,
        0xA660 as char, 0xA661 as char, 0xA662 as char, 0xA663 as char,
        0xA664 as char, 0xA665 as char, 0xA666 as char, 0xA667 as char,
        0xA668 as char, 0xA669 as char, 0xA66A as char, 0xA66B as char,
        0xA66C as char, 0xA66D as char, 0xA680 as char, 0xA681 as char,
        0xA682 as char, 0xA683 as char, 0xA684 as char, 0xA685 as char,
        0xA686 as char, 0xA687 as char, 0xA688 as char, 0xA689 as char,
        0xA68A as char, 0xA68B as char, 0xA68C as char, 0xA68D as char,
        0xA68E as char, 0xA68F as char, 0xA690 as char, 0xA691 as char,
        0xA692 as char, 0xA693 as char, 0xA694 as char, 0xA695 as char,
        0xA696 as char, 0xA697 as char, 0xA698 as char, 0xA699 as char,
        0xA69A as char, 0xA69B as char, 0xA722 as char, 0xA723 as char,
        0xA724 as char, 0xA725 as char, 0xA726 as char, 0xA727 as char,
        0xA728 as char, 0xA729 as char, 0xA72A as char, 0xA72B as char,
        0xA72C as char, 0xA72D as char, 0xA72E as char, 0xA72F as char,
        0xA732 as char, 0xA733 as char, 0xA734 as char, 0xA735 as char,
        0xA736 as char, 0xA737 as char, 0xA738 as char, 0xA739 as char,
        0xA73A as char, 0xA73B as char, 0xA73C as char, 0xA73D as char,
        0xA73E as char, 0xA73F as char, 0xA740 as char, 0xA741 as char,
        0xA742 as char, 0xA743 as char, 0xA744 as char, 0xA745 as char,
        0xA746 as char, 0xA747 as char, 0xA748 as char, 0xA749 as char,
        0xA74A as char, 0xA74B as char, 0xA74C as char, 0xA74D as char,
        0xA74E as char, 0xA74F as char, 0xA750 as char, 0xA751 as char,
        0xA752 as char, 0xA753 as char, 0xA754 as char, 0xA755 as char,
        0xA756 as char, 0xA757 as char, 0xA758 as char, 0xA759 as char,
        0xA75A as char, 0xA75B as char, 0xA75C as char, 0xA75D as char,
        0xA75E as char, 0xA75F as char, 0xA760 as char, 0xA761 as char,
        0xA762 as char, 0xA763 as char, 0xA764 as char, 0xA765 as char,
        0xA766 as char, 0xA767 as char, 0xA768 as char, 0xA769 as char,
        0xA76A as char, 0xA76B as char, 0xA76C as char, 0xA76D as char,
        0xA76E as char, 0xA76F as char, 0xA779 as char, 0xA77A as char,
        0xA77B as char, 0xA77C as char, 0xA77D as char, 0x1D79 as char,
        0xA77E as char, 0xA77F as char, 0xA780 as char, 0xA781 as char,
        0xA782 as char, 0xA783 as char, 0xA784 as char, 0xA785 as char,
        0xA786 as char, 0xA787 as char, 0xA78B as char, 0xA78C as char,
        0xA78D as char, 0x0265 as char, 0xA790 as char, 0xA791 as char,
        0xA792 as char, 0xA793 as char, 0xA796 as char, 0xA797 as char,
        0xA798 as char, 0xA799 as char, 0xA79A as char, 0xA79B as char,
        0xA79C as char, 0xA79D as char, 0xA79E as char, 0xA79F as char,
        0xA7A0 as char, 0xA7A1 as char, 0xA7A2 as char, 0xA7A3 as char,
        0xA7A4 as char, 0xA7A5 as char, 0xA7A6 as char, 0xA7A7 as char,
        0xA7A8 as char, 0xA7A9 as char, 0xA7AA as char, 0x0266 as char,
        0xA7AB as char, 0x025C as char, 0xA7AC as char, 0x0261 as char,
        0xA7AD as char, 0x026C as char, 0xA7AE as char, 0x026A as char,
        0xA7B0 as char, 0x029E as char, 0xA7B1 as char, 0x0287 as char,
        0xA7B2 as char, 0x029D as char, 0xA7B3 as char, 0xAB53 as char,
        0xA7B4 as char, 0xA7B5 as char, 0xA7B6 as char, 0xA7B7 as char,
        0xA7B8 as char, 0xA7B9 as char, 0xA7BA as char, 0xA7BB as char,
        0xA7BC as char, 0xA7BD as char, 0xA7BE as char, 0xA7BF as char,
        0xA7C0 as char, 0xA7C1 as char, 0xA7C2 as char, 0xA7C3 as char,
        0xA7C4 as char, 0xA794 as char, 0xA7C5 as char, 0x0282 as char,
        0xA7C6 as char, 0x1D8E as char, 0xA7C7 as char, 0xA7C8 as char,
        0xA7C9 as char, 0xA7CA as char, 0xA7CB as char, 0x0264 as char,
        0xA7CC as char, 0xA7CD as char, 0xA7D0 as char, 0xA7D1 as char,
        0xA7D6 as char, 0xA7D7 as char, 0xA7D8 as char, 0xA7D9 as char,
        0xA7DA as char, 0xA7DB as char, 0xA7DC as char, 0x019B as char,
        0xA7F5 as char, 0xA7F6 as char,
    ]
}

⍝ U+A800..U+A9FF
micro unicode_case_lower_chunk_84() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+AA00..U+ABFF
micro unicode_case_lower_chunk_85() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+AC00..U+ADFF
micro unicode_case_lower_chunk_86() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+AE00..U+AFFF
micro unicode_case_lower_chunk_87() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B000..U+B1FF
micro unicode_case_lower_chunk_88() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B200..U+B3FF
micro unicode_case_lower_chunk_89() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B400..U+B5FF
micro unicode_case_lower_chunk_90() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B600..U+B7FF
micro unicode_case_lower_chunk_91() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B800..U+B9FF
micro unicode_case_lower_chunk_92() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BA00..U+BBFF
micro unicode_case_lower_chunk_93() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BC00..U+BDFF
micro unicode_case_lower_chunk_94() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BE00..U+BFFF
micro unicode_case_lower_chunk_95() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C000..U+C1FF
micro unicode_case_lower_chunk_96() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C200..U+C3FF
micro unicode_case_lower_chunk_97() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C400..U+C5FF
micro unicode_case_lower_chunk_98() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C600..U+C7FF
micro unicode_case_lower_chunk_99() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C800..U+C9FF
micro unicode_case_lower_chunk_100() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CA00..U+CBFF
micro unicode_case_lower_chunk_101() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CC00..U+CDFF
micro unicode_case_lower_chunk_102() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CE00..U+CFFF
micro unicode_case_lower_chunk_103() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D000..U+D1FF
micro unicode_case_lower_chunk_104() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D200..U+D3FF
micro unicode_case_lower_chunk_105() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D400..U+D5FF
micro unicode_case_lower_chunk_106() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D600..U+D7FF
micro unicode_case_lower_chunk_107() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D800..U+D9FF
micro unicode_case_lower_chunk_108() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DA00..U+DBFF
micro unicode_case_lower_chunk_109() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DC00..U+DDFF
micro unicode_case_lower_chunk_110() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DE00..U+DFFF
micro unicode_case_lower_chunk_111() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E000..U+E1FF
micro unicode_case_lower_chunk_112() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E200..U+E3FF
micro unicode_case_lower_chunk_113() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E400..U+E5FF
micro unicode_case_lower_chunk_114() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E600..U+E7FF
micro unicode_case_lower_chunk_115() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E800..U+E9FF
micro unicode_case_lower_chunk_116() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EA00..U+EBFF
micro unicode_case_lower_chunk_117() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EC00..U+EDFF
micro unicode_case_lower_chunk_118() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EE00..U+EFFF
micro unicode_case_lower_chunk_119() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F000..U+F1FF
micro unicode_case_lower_chunk_120() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F200..U+F3FF
micro unicode_case_lower_chunk_121() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F400..U+F5FF
micro unicode_case_lower_chunk_122() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F600..U+F7FF
micro unicode_case_lower_chunk_123() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F800..U+F9FF
micro unicode_case_lower_chunk_124() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FA00..U+FBFF
micro unicode_case_lower_chunk_125() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FC00..U+FDFF
micro unicode_case_lower_chunk_126() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FE00..U+FFFF
micro unicode_case_lower_chunk_127() -> [char] {
    return [
        0xFF21 as char, 0xFF41 as char, 0xFF22 as char, 0xFF42 as char,
        0xFF23 as char, 0xFF43 as char, 0xFF24 as char, 0xFF44 as char,
        0xFF25 as char, 0xFF45 as char, 0xFF26 as char, 0xFF46 as char,
        0xFF27 as char, 0xFF47 as char, 0xFF28 as char, 0xFF48 as char,
        0xFF29 as char, 0xFF49 as char, 0xFF2A as char, 0xFF4A as char,
        0xFF2B as char, 0xFF4B as char, 0xFF2C as char, 0xFF4C as char,
        0xFF2D as char, 0xFF4D as char, 0xFF2E as char, 0xFF4E as char,
        0xFF2F as char, 0xFF4F as char, 0xFF30 as char, 0xFF50 as char,
        0xFF31 as char, 0xFF51 as char, 0xFF32 as char, 0xFF52 as char,
        0xFF33 as char, 0xFF53 as char, 0xFF34 as char, 0xFF54 as char,
        0xFF35 as char, 0xFF55 as char, 0xFF36 as char, 0xFF56 as char,
        0xFF37 as char, 0xFF57 as char, 0xFF38 as char, 0xFF58 as char,
        0xFF39 as char, 0xFF59 as char, 0xFF3A as char, 0xFF5A as char,
    ]
}

⍝ ────────── simple 大写 ──────────
⍝ 分派器：按码点所在块选表；查不到即返回原码点（大小写映射是局部函数，未命中即自身）。
micro upper_simple(c: char) -> char {
    let code: u32 = c as u32
    if code < 0x200 {
        return simple_pair_lookup(unicode_case_upper_chunk_0(), code)
    }

    if code < 0x400 {
        return simple_pair_lookup(unicode_case_upper_chunk_1(), code)
    }

    if code < 0x600 {
        return simple_pair_lookup(unicode_case_upper_chunk_2(), code)
    }

    if code < 0x800 {
        return simple_pair_lookup(unicode_case_upper_chunk_3(), code)
    }

    if code < 0xA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_4(), code)
    }

    if code < 0xC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_5(), code)
    }

    if code < 0xE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_6(), code)
    }

    if code < 0x1000 {
        return simple_pair_lookup(unicode_case_upper_chunk_7(), code)
    }

    if code < 0x1200 {
        return simple_pair_lookup(unicode_case_upper_chunk_8(), code)
    }

    if code < 0x1400 {
        return simple_pair_lookup(unicode_case_upper_chunk_9(), code)
    }

    if code < 0x1600 {
        return simple_pair_lookup(unicode_case_upper_chunk_10(), code)
    }

    if code < 0x1800 {
        return simple_pair_lookup(unicode_case_upper_chunk_11(), code)
    }

    if code < 0x1A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_12(), code)
    }

    if code < 0x1C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_13(), code)
    }

    if code < 0x1E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_14(), code)
    }

    if code < 0x2000 {
        return simple_pair_lookup(unicode_case_upper_chunk_15(), code)
    }

    if code < 0x2200 {
        return simple_pair_lookup(unicode_case_upper_chunk_16(), code)
    }

    if code < 0x2400 {
        return simple_pair_lookup(unicode_case_upper_chunk_17(), code)
    }

    if code < 0x2600 {
        return simple_pair_lookup(unicode_case_upper_chunk_18(), code)
    }

    if code < 0x2800 {
        return simple_pair_lookup(unicode_case_upper_chunk_19(), code)
    }

    if code < 0x2A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_20(), code)
    }

    if code < 0x2C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_21(), code)
    }

    if code < 0x2E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_22(), code)
    }

    if code < 0x3000 {
        return simple_pair_lookup(unicode_case_upper_chunk_23(), code)
    }

    if code < 0x3200 {
        return simple_pair_lookup(unicode_case_upper_chunk_24(), code)
    }

    if code < 0x3400 {
        return simple_pair_lookup(unicode_case_upper_chunk_25(), code)
    }

    if code < 0x3600 {
        return simple_pair_lookup(unicode_case_upper_chunk_26(), code)
    }

    if code < 0x3800 {
        return simple_pair_lookup(unicode_case_upper_chunk_27(), code)
    }

    if code < 0x3A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_28(), code)
    }

    if code < 0x3C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_29(), code)
    }

    if code < 0x3E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_30(), code)
    }

    if code < 0x4000 {
        return simple_pair_lookup(unicode_case_upper_chunk_31(), code)
    }

    if code < 0x4200 {
        return simple_pair_lookup(unicode_case_upper_chunk_32(), code)
    }

    if code < 0x4400 {
        return simple_pair_lookup(unicode_case_upper_chunk_33(), code)
    }

    if code < 0x4600 {
        return simple_pair_lookup(unicode_case_upper_chunk_34(), code)
    }

    if code < 0x4800 {
        return simple_pair_lookup(unicode_case_upper_chunk_35(), code)
    }

    if code < 0x4A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_36(), code)
    }

    if code < 0x4C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_37(), code)
    }

    if code < 0x4E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_38(), code)
    }

    if code < 0x5000 {
        return simple_pair_lookup(unicode_case_upper_chunk_39(), code)
    }

    if code < 0x5200 {
        return simple_pair_lookup(unicode_case_upper_chunk_40(), code)
    }

    if code < 0x5400 {
        return simple_pair_lookup(unicode_case_upper_chunk_41(), code)
    }

    if code < 0x5600 {
        return simple_pair_lookup(unicode_case_upper_chunk_42(), code)
    }

    if code < 0x5800 {
        return simple_pair_lookup(unicode_case_upper_chunk_43(), code)
    }

    if code < 0x5A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_44(), code)
    }

    if code < 0x5C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_45(), code)
    }

    if code < 0x5E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_46(), code)
    }

    if code < 0x6000 {
        return simple_pair_lookup(unicode_case_upper_chunk_47(), code)
    }

    if code < 0x6200 {
        return simple_pair_lookup(unicode_case_upper_chunk_48(), code)
    }

    if code < 0x6400 {
        return simple_pair_lookup(unicode_case_upper_chunk_49(), code)
    }

    if code < 0x6600 {
        return simple_pair_lookup(unicode_case_upper_chunk_50(), code)
    }

    if code < 0x6800 {
        return simple_pair_lookup(unicode_case_upper_chunk_51(), code)
    }

    if code < 0x6A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_52(), code)
    }

    if code < 0x6C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_53(), code)
    }

    if code < 0x6E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_54(), code)
    }

    if code < 0x7000 {
        return simple_pair_lookup(unicode_case_upper_chunk_55(), code)
    }

    if code < 0x7200 {
        return simple_pair_lookup(unicode_case_upper_chunk_56(), code)
    }

    if code < 0x7400 {
        return simple_pair_lookup(unicode_case_upper_chunk_57(), code)
    }

    if code < 0x7600 {
        return simple_pair_lookup(unicode_case_upper_chunk_58(), code)
    }

    if code < 0x7800 {
        return simple_pair_lookup(unicode_case_upper_chunk_59(), code)
    }

    if code < 0x7A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_60(), code)
    }

    if code < 0x7C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_61(), code)
    }

    if code < 0x7E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_62(), code)
    }

    if code < 0x8000 {
        return simple_pair_lookup(unicode_case_upper_chunk_63(), code)
    }

    if code < 0x8200 {
        return simple_pair_lookup(unicode_case_upper_chunk_64(), code)
    }

    if code < 0x8400 {
        return simple_pair_lookup(unicode_case_upper_chunk_65(), code)
    }

    if code < 0x8600 {
        return simple_pair_lookup(unicode_case_upper_chunk_66(), code)
    }

    if code < 0x8800 {
        return simple_pair_lookup(unicode_case_upper_chunk_67(), code)
    }

    if code < 0x8A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_68(), code)
    }

    if code < 0x8C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_69(), code)
    }

    if code < 0x8E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_70(), code)
    }

    if code < 0x9000 {
        return simple_pair_lookup(unicode_case_upper_chunk_71(), code)
    }

    if code < 0x9200 {
        return simple_pair_lookup(unicode_case_upper_chunk_72(), code)
    }

    if code < 0x9400 {
        return simple_pair_lookup(unicode_case_upper_chunk_73(), code)
    }

    if code < 0x9600 {
        return simple_pair_lookup(unicode_case_upper_chunk_74(), code)
    }

    if code < 0x9800 {
        return simple_pair_lookup(unicode_case_upper_chunk_75(), code)
    }

    if code < 0x9A00 {
        return simple_pair_lookup(unicode_case_upper_chunk_76(), code)
    }

    if code < 0x9C00 {
        return simple_pair_lookup(unicode_case_upper_chunk_77(), code)
    }

    if code < 0x9E00 {
        return simple_pair_lookup(unicode_case_upper_chunk_78(), code)
    }

    if code < 0xA000 {
        return simple_pair_lookup(unicode_case_upper_chunk_79(), code)
    }

    if code < 0xA200 {
        return simple_pair_lookup(unicode_case_upper_chunk_80(), code)
    }

    if code < 0xA400 {
        return simple_pair_lookup(unicode_case_upper_chunk_81(), code)
    }

    if code < 0xA600 {
        return simple_pair_lookup(unicode_case_upper_chunk_82(), code)
    }

    if code < 0xA800 {
        return simple_pair_lookup(unicode_case_upper_chunk_83(), code)
    }

    if code < 0xAA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_84(), code)
    }

    if code < 0xAC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_85(), code)
    }

    if code < 0xAE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_86(), code)
    }

    if code < 0xB000 {
        return simple_pair_lookup(unicode_case_upper_chunk_87(), code)
    }

    if code < 0xB200 {
        return simple_pair_lookup(unicode_case_upper_chunk_88(), code)
    }

    if code < 0xB400 {
        return simple_pair_lookup(unicode_case_upper_chunk_89(), code)
    }

    if code < 0xB600 {
        return simple_pair_lookup(unicode_case_upper_chunk_90(), code)
    }

    if code < 0xB800 {
        return simple_pair_lookup(unicode_case_upper_chunk_91(), code)
    }

    if code < 0xBA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_92(), code)
    }

    if code < 0xBC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_93(), code)
    }

    if code < 0xBE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_94(), code)
    }

    if code < 0xC000 {
        return simple_pair_lookup(unicode_case_upper_chunk_95(), code)
    }

    if code < 0xC200 {
        return simple_pair_lookup(unicode_case_upper_chunk_96(), code)
    }

    if code < 0xC400 {
        return simple_pair_lookup(unicode_case_upper_chunk_97(), code)
    }

    if code < 0xC600 {
        return simple_pair_lookup(unicode_case_upper_chunk_98(), code)
    }

    if code < 0xC800 {
        return simple_pair_lookup(unicode_case_upper_chunk_99(), code)
    }

    if code < 0xCA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_100(), code)
    }

    if code < 0xCC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_101(), code)
    }

    if code < 0xCE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_102(), code)
    }

    if code < 0xD000 {
        return simple_pair_lookup(unicode_case_upper_chunk_103(), code)
    }

    if code < 0xD200 {
        return simple_pair_lookup(unicode_case_upper_chunk_104(), code)
    }

    if code < 0xD400 {
        return simple_pair_lookup(unicode_case_upper_chunk_105(), code)
    }

    if code < 0xD600 {
        return simple_pair_lookup(unicode_case_upper_chunk_106(), code)
    }

    if code < 0xD800 {
        return simple_pair_lookup(unicode_case_upper_chunk_107(), code)
    }

    if code < 0xDA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_108(), code)
    }

    if code < 0xDC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_109(), code)
    }

    if code < 0xDE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_110(), code)
    }

    if code < 0xE000 {
        return simple_pair_lookup(unicode_case_upper_chunk_111(), code)
    }

    if code < 0xE200 {
        return simple_pair_lookup(unicode_case_upper_chunk_112(), code)
    }

    if code < 0xE400 {
        return simple_pair_lookup(unicode_case_upper_chunk_113(), code)
    }

    if code < 0xE600 {
        return simple_pair_lookup(unicode_case_upper_chunk_114(), code)
    }

    if code < 0xE800 {
        return simple_pair_lookup(unicode_case_upper_chunk_115(), code)
    }

    if code < 0xEA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_116(), code)
    }

    if code < 0xEC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_117(), code)
    }

    if code < 0xEE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_118(), code)
    }

    if code < 0xF000 {
        return simple_pair_lookup(unicode_case_upper_chunk_119(), code)
    }

    if code < 0xF200 {
        return simple_pair_lookup(unicode_case_upper_chunk_120(), code)
    }

    if code < 0xF400 {
        return simple_pair_lookup(unicode_case_upper_chunk_121(), code)
    }

    if code < 0xF600 {
        return simple_pair_lookup(unicode_case_upper_chunk_122(), code)
    }

    if code < 0xF800 {
        return simple_pair_lookup(unicode_case_upper_chunk_123(), code)
    }

    if code < 0xFA00 {
        return simple_pair_lookup(unicode_case_upper_chunk_124(), code)
    }

    if code < 0xFC00 {
        return simple_pair_lookup(unicode_case_upper_chunk_125(), code)
    }

    if code < 0xFE00 {
        return simple_pair_lookup(unicode_case_upper_chunk_126(), code)
    }

    return simple_pair_lookup(unicode_case_upper_chunk_127(), code)
}

⍝ U+0000..U+01FF
micro unicode_case_upper_chunk_0() -> [char] {
    return [
        0x0061 as char, 0x0041 as char, 0x0062 as char, 0x0042 as char,
        0x0063 as char, 0x0043 as char, 0x0064 as char, 0x0044 as char,
        0x0065 as char, 0x0045 as char, 0x0066 as char, 0x0046 as char,
        0x0067 as char, 0x0047 as char, 0x0068 as char, 0x0048 as char,
        0x0069 as char, 0x0049 as char, 0x006A as char, 0x004A as char,
        0x006B as char, 0x004B as char, 0x006C as char, 0x004C as char,
        0x006D as char, 0x004D as char, 0x006E as char, 0x004E as char,
        0x006F as char, 0x004F as char, 0x0070 as char, 0x0050 as char,
        0x0071 as char, 0x0051 as char, 0x0072 as char, 0x0052 as char,
        0x0073 as char, 0x0053 as char, 0x0074 as char, 0x0054 as char,
        0x0075 as char, 0x0055 as char, 0x0076 as char, 0x0056 as char,
        0x0077 as char, 0x0057 as char, 0x0078 as char, 0x0058 as char,
        0x0079 as char, 0x0059 as char, 0x007A as char, 0x005A as char,
        0x00B5 as char, 0x039C as char, 0x00E0 as char, 0x00C0 as char,
        0x00E1 as char, 0x00C1 as char, 0x00E2 as char, 0x00C2 as char,
        0x00E3 as char, 0x00C3 as char, 0x00E4 as char, 0x00C4 as char,
        0x00E5 as char, 0x00C5 as char, 0x00E6 as char, 0x00C6 as char,
        0x00E7 as char, 0x00C7 as char, 0x00E8 as char, 0x00C8 as char,
        0x00E9 as char, 0x00C9 as char, 0x00EA as char, 0x00CA as char,
        0x00EB as char, 0x00CB as char, 0x00EC as char, 0x00CC as char,
        0x00ED as char, 0x00CD as char, 0x00EE as char, 0x00CE as char,
        0x00EF as char, 0x00CF as char, 0x00F0 as char, 0x00D0 as char,
        0x00F1 as char, 0x00D1 as char, 0x00F2 as char, 0x00D2 as char,
        0x00F3 as char, 0x00D3 as char, 0x00F4 as char, 0x00D4 as char,
        0x00F5 as char, 0x00D5 as char, 0x00F6 as char, 0x00D6 as char,
        0x00F8 as char, 0x00D8 as char, 0x00F9 as char, 0x00D9 as char,
        0x00FA as char, 0x00DA as char, 0x00FB as char, 0x00DB as char,
        0x00FC as char, 0x00DC as char, 0x00FD as char, 0x00DD as char,
        0x00FE as char, 0x00DE as char, 0x00FF as char, 0x0178 as char,
        0x0101 as char, 0x0100 as char, 0x0103 as char, 0x0102 as char,
        0x0105 as char, 0x0104 as char, 0x0107 as char, 0x0106 as char,
        0x0109 as char, 0x0108 as char, 0x010B as char, 0x010A as char,
        0x010D as char, 0x010C as char, 0x010F as char, 0x010E as char,
        0x0111 as char, 0x0110 as char, 0x0113 as char, 0x0112 as char,
        0x0115 as char, 0x0114 as char, 0x0117 as char, 0x0116 as char,
        0x0119 as char, 0x0118 as char, 0x011B as char, 0x011A as char,
        0x011D as char, 0x011C as char, 0x011F as char, 0x011E as char,
        0x0121 as char, 0x0120 as char, 0x0123 as char, 0x0122 as char,
        0x0125 as char, 0x0124 as char, 0x0127 as char, 0x0126 as char,
        0x0129 as char, 0x0128 as char, 0x012B as char, 0x012A as char,
        0x012D as char, 0x012C as char, 0x012F as char, 0x012E as char,
        0x0131 as char, 0x0049 as char, 0x0133 as char, 0x0132 as char,
        0x0135 as char, 0x0134 as char, 0x0137 as char, 0x0136 as char,
        0x013A as char, 0x0139 as char, 0x013C as char, 0x013B as char,
        0x013E as char, 0x013D as char, 0x0140 as char, 0x013F as char,
        0x0142 as char, 0x0141 as char, 0x0144 as char, 0x0143 as char,
        0x0146 as char, 0x0145 as char, 0x0148 as char, 0x0147 as char,
        0x014B as char, 0x014A as char, 0x014D as char, 0x014C as char,
        0x014F as char, 0x014E as char, 0x0151 as char, 0x0150 as char,
        0x0153 as char, 0x0152 as char, 0x0155 as char, 0x0154 as char,
        0x0157 as char, 0x0156 as char, 0x0159 as char, 0x0158 as char,
        0x015B as char, 0x015A as char, 0x015D as char, 0x015C as char,
        0x015F as char, 0x015E as char, 0x0161 as char, 0x0160 as char,
        0x0163 as char, 0x0162 as char, 0x0165 as char, 0x0164 as char,
        0x0167 as char, 0x0166 as char, 0x0169 as char, 0x0168 as char,
        0x016B as char, 0x016A as char, 0x016D as char, 0x016C as char,
        0x016F as char, 0x016E as char, 0x0171 as char, 0x0170 as char,
        0x0173 as char, 0x0172 as char, 0x0175 as char, 0x0174 as char,
        0x0177 as char, 0x0176 as char, 0x017A as char, 0x0179 as char,
        0x017C as char, 0x017B as char, 0x017E as char, 0x017D as char,
        0x017F as char, 0x0053 as char, 0x0180 as char, 0x0243 as char,
        0x0183 as char, 0x0182 as char, 0x0185 as char, 0x0184 as char,
        0x0188 as char, 0x0187 as char, 0x018C as char, 0x018B as char,
        0x0192 as char, 0x0191 as char, 0x0195 as char, 0x01F6 as char,
        0x0199 as char, 0x0198 as char, 0x019A as char, 0x023D as char,
        0x019B as char, 0xA7DC as char, 0x019E as char, 0x0220 as char,
        0x01A1 as char, 0x01A0 as char, 0x01A3 as char, 0x01A2 as char,
        0x01A5 as char, 0x01A4 as char, 0x01A8 as char, 0x01A7 as char,
        0x01AD as char, 0x01AC as char, 0x01B0 as char, 0x01AF as char,
        0x01B4 as char, 0x01B3 as char, 0x01B6 as char, 0x01B5 as char,
        0x01B9 as char, 0x01B8 as char, 0x01BD as char, 0x01BC as char,
        0x01BF as char, 0x01F7 as char, 0x01C5 as char, 0x01C4 as char,
        0x01C6 as char, 0x01C4 as char, 0x01C8 as char, 0x01C7 as char,
        0x01C9 as char, 0x01C7 as char, 0x01CB as char, 0x01CA as char,
        0x01CC as char, 0x01CA as char, 0x01CE as char, 0x01CD as char,
        0x01D0 as char, 0x01CF as char, 0x01D2 as char, 0x01D1 as char,
        0x01D4 as char, 0x01D3 as char, 0x01D6 as char, 0x01D5 as char,
        0x01D8 as char, 0x01D7 as char, 0x01DA as char, 0x01D9 as char,
        0x01DC as char, 0x01DB as char, 0x01DD as char, 0x018E as char,
        0x01DF as char, 0x01DE as char, 0x01E1 as char, 0x01E0 as char,
        0x01E3 as char, 0x01E2 as char, 0x01E5 as char, 0x01E4 as char,
        0x01E7 as char, 0x01E6 as char, 0x01E9 as char, 0x01E8 as char,
        0x01EB as char, 0x01EA as char, 0x01ED as char, 0x01EC as char,
        0x01EF as char, 0x01EE as char, 0x01F2 as char, 0x01F1 as char,
        0x01F3 as char, 0x01F1 as char, 0x01F5 as char, 0x01F4 as char,
        0x01F9 as char, 0x01F8 as char, 0x01FB as char, 0x01FA as char,
        0x01FD as char, 0x01FC as char, 0x01FF as char, 0x01FE as char,
    ]
}

⍝ U+0200..U+03FF
micro unicode_case_upper_chunk_1() -> [char] {
    return [
        0x0201 as char, 0x0200 as char, 0x0203 as char, 0x0202 as char,
        0x0205 as char, 0x0204 as char, 0x0207 as char, 0x0206 as char,
        0x0209 as char, 0x0208 as char, 0x020B as char, 0x020A as char,
        0x020D as char, 0x020C as char, 0x020F as char, 0x020E as char,
        0x0211 as char, 0x0210 as char, 0x0213 as char, 0x0212 as char,
        0x0215 as char, 0x0214 as char, 0x0217 as char, 0x0216 as char,
        0x0219 as char, 0x0218 as char, 0x021B as char, 0x021A as char,
        0x021D as char, 0x021C as char, 0x021F as char, 0x021E as char,
        0x0223 as char, 0x0222 as char, 0x0225 as char, 0x0224 as char,
        0x0227 as char, 0x0226 as char, 0x0229 as char, 0x0228 as char,
        0x022B as char, 0x022A as char, 0x022D as char, 0x022C as char,
        0x022F as char, 0x022E as char, 0x0231 as char, 0x0230 as char,
        0x0233 as char, 0x0232 as char, 0x023C as char, 0x023B as char,
        0x023F as char, 0x2C7E as char, 0x0240 as char, 0x2C7F as char,
        0x0242 as char, 0x0241 as char, 0x0247 as char, 0x0246 as char,
        0x0249 as char, 0x0248 as char, 0x024B as char, 0x024A as char,
        0x024D as char, 0x024C as char, 0x024F as char, 0x024E as char,
        0x0250 as char, 0x2C6F as char, 0x0251 as char, 0x2C6D as char,
        0x0252 as char, 0x2C70 as char, 0x0253 as char, 0x0181 as char,
        0x0254 as char, 0x0186 as char, 0x0256 as char, 0x0189 as char,
        0x0257 as char, 0x018A as char, 0x0259 as char, 0x018F as char,
        0x025B as char, 0x0190 as char, 0x025C as char, 0xA7AB as char,
        0x0260 as char, 0x0193 as char, 0x0261 as char, 0xA7AC as char,
        0x0263 as char, 0x0194 as char, 0x0264 as char, 0xA7CB as char,
        0x0265 as char, 0xA78D as char, 0x0266 as char, 0xA7AA as char,
        0x0268 as char, 0x0197 as char, 0x0269 as char, 0x0196 as char,
        0x026A as char, 0xA7AE as char, 0x026B as char, 0x2C62 as char,
        0x026C as char, 0xA7AD as char, 0x026F as char, 0x019C as char,
        0x0271 as char, 0x2C6E as char, 0x0272 as char, 0x019D as char,
        0x0275 as char, 0x019F as char, 0x027D as char, 0x2C64 as char,
        0x0280 as char, 0x01A6 as char, 0x0282 as char, 0xA7C5 as char,
        0x0283 as char, 0x01A9 as char, 0x0287 as char, 0xA7B1 as char,
        0x0288 as char, 0x01AE as char, 0x0289 as char, 0x0244 as char,
        0x028A as char, 0x01B1 as char, 0x028B as char, 0x01B2 as char,
        0x028C as char, 0x0245 as char, 0x0292 as char, 0x01B7 as char,
        0x029D as char, 0xA7B2 as char, 0x029E as char, 0xA7B0 as char,
        0x0345 as char, 0x0399 as char, 0x0371 as char, 0x0370 as char,
        0x0373 as char, 0x0372 as char, 0x0377 as char, 0x0376 as char,
        0x037B as char, 0x03FD as char, 0x037C as char, 0x03FE as char,
        0x037D as char, 0x03FF as char, 0x03AC as char, 0x0386 as char,
        0x03AD as char, 0x0388 as char, 0x03AE as char, 0x0389 as char,
        0x03AF as char, 0x038A as char, 0x03B1 as char, 0x0391 as char,
        0x03B2 as char, 0x0392 as char, 0x03B3 as char, 0x0393 as char,
        0x03B4 as char, 0x0394 as char, 0x03B5 as char, 0x0395 as char,
        0x03B6 as char, 0x0396 as char, 0x03B7 as char, 0x0397 as char,
        0x03B8 as char, 0x0398 as char, 0x03B9 as char, 0x0399 as char,
        0x03BA as char, 0x039A as char, 0x03BB as char, 0x039B as char,
        0x03BC as char, 0x039C as char, 0x03BD as char, 0x039D as char,
        0x03BE as char, 0x039E as char, 0x03BF as char, 0x039F as char,
        0x03C0 as char, 0x03A0 as char, 0x03C1 as char, 0x03A1 as char,
        0x03C2 as char, 0x03A3 as char, 0x03C3 as char, 0x03A3 as char,
        0x03C4 as char, 0x03A4 as char, 0x03C5 as char, 0x03A5 as char,
        0x03C6 as char, 0x03A6 as char, 0x03C7 as char, 0x03A7 as char,
        0x03C8 as char, 0x03A8 as char, 0x03C9 as char, 0x03A9 as char,
        0x03CA as char, 0x03AA as char, 0x03CB as char, 0x03AB as char,
        0x03CC as char, 0x038C as char, 0x03CD as char, 0x038E as char,
        0x03CE as char, 0x038F as char, 0x03D0 as char, 0x0392 as char,
        0x03D1 as char, 0x0398 as char, 0x03D5 as char, 0x03A6 as char,
        0x03D6 as char, 0x03A0 as char, 0x03D7 as char, 0x03CF as char,
        0x03D9 as char, 0x03D8 as char, 0x03DB as char, 0x03DA as char,
        0x03DD as char, 0x03DC as char, 0x03DF as char, 0x03DE as char,
        0x03E1 as char, 0x03E0 as char, 0x03E3 as char, 0x03E2 as char,
        0x03E5 as char, 0x03E4 as char, 0x03E7 as char, 0x03E6 as char,
        0x03E9 as char, 0x03E8 as char, 0x03EB as char, 0x03EA as char,
        0x03ED as char, 0x03EC as char, 0x03EF as char, 0x03EE as char,
        0x03F0 as char, 0x039A as char, 0x03F1 as char, 0x03A1 as char,
        0x03F2 as char, 0x03F9 as char, 0x03F3 as char, 0x037F as char,
        0x03F5 as char, 0x0395 as char, 0x03F8 as char, 0x03F7 as char,
        0x03FB as char, 0x03FA as char,
    ]
}

⍝ U+0400..U+05FF
micro unicode_case_upper_chunk_2() -> [char] {
    return [
        0x0430 as char, 0x0410 as char, 0x0431 as char, 0x0411 as char,
        0x0432 as char, 0x0412 as char, 0x0433 as char, 0x0413 as char,
        0x0434 as char, 0x0414 as char, 0x0435 as char, 0x0415 as char,
        0x0436 as char, 0x0416 as char, 0x0437 as char, 0x0417 as char,
        0x0438 as char, 0x0418 as char, 0x0439 as char, 0x0419 as char,
        0x043A as char, 0x041A as char, 0x043B as char, 0x041B as char,
        0x043C as char, 0x041C as char, 0x043D as char, 0x041D as char,
        0x043E as char, 0x041E as char, 0x043F as char, 0x041F as char,
        0x0440 as char, 0x0420 as char, 0x0441 as char, 0x0421 as char,
        0x0442 as char, 0x0422 as char, 0x0443 as char, 0x0423 as char,
        0x0444 as char, 0x0424 as char, 0x0445 as char, 0x0425 as char,
        0x0446 as char, 0x0426 as char, 0x0447 as char, 0x0427 as char,
        0x0448 as char, 0x0428 as char, 0x0449 as char, 0x0429 as char,
        0x044A as char, 0x042A as char, 0x044B as char, 0x042B as char,
        0x044C as char, 0x042C as char, 0x044D as char, 0x042D as char,
        0x044E as char, 0x042E as char, 0x044F as char, 0x042F as char,
        0x0450 as char, 0x0400 as char, 0x0451 as char, 0x0401 as char,
        0x0452 as char, 0x0402 as char, 0x0453 as char, 0x0403 as char,
        0x0454 as char, 0x0404 as char, 0x0455 as char, 0x0405 as char,
        0x0456 as char, 0x0406 as char, 0x0457 as char, 0x0407 as char,
        0x0458 as char, 0x0408 as char, 0x0459 as char, 0x0409 as char,
        0x045A as char, 0x040A as char, 0x045B as char, 0x040B as char,
        0x045C as char, 0x040C as char, 0x045D as char, 0x040D as char,
        0x045E as char, 0x040E as char, 0x045F as char, 0x040F as char,
        0x0461 as char, 0x0460 as char, 0x0463 as char, 0x0462 as char,
        0x0465 as char, 0x0464 as char, 0x0467 as char, 0x0466 as char,
        0x0469 as char, 0x0468 as char, 0x046B as char, 0x046A as char,
        0x046D as char, 0x046C as char, 0x046F as char, 0x046E as char,
        0x0471 as char, 0x0470 as char, 0x0473 as char, 0x0472 as char,
        0x0475 as char, 0x0474 as char, 0x0477 as char, 0x0476 as char,
        0x0479 as char, 0x0478 as char, 0x047B as char, 0x047A as char,
        0x047D as char, 0x047C as char, 0x047F as char, 0x047E as char,
        0x0481 as char, 0x0480 as char, 0x048B as char, 0x048A as char,
        0x048D as char, 0x048C as char, 0x048F as char, 0x048E as char,
        0x0491 as char, 0x0490 as char, 0x0493 as char, 0x0492 as char,
        0x0495 as char, 0x0494 as char, 0x0497 as char, 0x0496 as char,
        0x0499 as char, 0x0498 as char, 0x049B as char, 0x049A as char,
        0x049D as char, 0x049C as char, 0x049F as char, 0x049E as char,
        0x04A1 as char, 0x04A0 as char, 0x04A3 as char, 0x04A2 as char,
        0x04A5 as char, 0x04A4 as char, 0x04A7 as char, 0x04A6 as char,
        0x04A9 as char, 0x04A8 as char, 0x04AB as char, 0x04AA as char,
        0x04AD as char, 0x04AC as char, 0x04AF as char, 0x04AE as char,
        0x04B1 as char, 0x04B0 as char, 0x04B3 as char, 0x04B2 as char,
        0x04B5 as char, 0x04B4 as char, 0x04B7 as char, 0x04B6 as char,
        0x04B9 as char, 0x04B8 as char, 0x04BB as char, 0x04BA as char,
        0x04BD as char, 0x04BC as char, 0x04BF as char, 0x04BE as char,
        0x04C2 as char, 0x04C1 as char, 0x04C4 as char, 0x04C3 as char,
        0x04C6 as char, 0x04C5 as char, 0x04C8 as char, 0x04C7 as char,
        0x04CA as char, 0x04C9 as char, 0x04CC as char, 0x04CB as char,
        0x04CE as char, 0x04CD as char, 0x04CF as char, 0x04C0 as char,
        0x04D1 as char, 0x04D0 as char, 0x04D3 as char, 0x04D2 as char,
        0x04D5 as char, 0x04D4 as char, 0x04D7 as char, 0x04D6 as char,
        0x04D9 as char, 0x04D8 as char, 0x04DB as char, 0x04DA as char,
        0x04DD as char, 0x04DC as char, 0x04DF as char, 0x04DE as char,
        0x04E1 as char, 0x04E0 as char, 0x04E3 as char, 0x04E2 as char,
        0x04E5 as char, 0x04E4 as char, 0x04E7 as char, 0x04E6 as char,
        0x04E9 as char, 0x04E8 as char, 0x04EB as char, 0x04EA as char,
        0x04ED as char, 0x04EC as char, 0x04EF as char, 0x04EE as char,
        0x04F1 as char, 0x04F0 as char, 0x04F3 as char, 0x04F2 as char,
        0x04F5 as char, 0x04F4 as char, 0x04F7 as char, 0x04F6 as char,
        0x04F9 as char, 0x04F8 as char, 0x04FB as char, 0x04FA as char,
        0x04FD as char, 0x04FC as char, 0x04FF as char, 0x04FE as char,
        0x0501 as char, 0x0500 as char, 0x0503 as char, 0x0502 as char,
        0x0505 as char, 0x0504 as char, 0x0507 as char, 0x0506 as char,
        0x0509 as char, 0x0508 as char, 0x050B as char, 0x050A as char,
        0x050D as char, 0x050C as char, 0x050F as char, 0x050E as char,
        0x0511 as char, 0x0510 as char, 0x0513 as char, 0x0512 as char,
        0x0515 as char, 0x0514 as char, 0x0517 as char, 0x0516 as char,
        0x0519 as char, 0x0518 as char, 0x051B as char, 0x051A as char,
        0x051D as char, 0x051C as char, 0x051F as char, 0x051E as char,
        0x0521 as char, 0x0520 as char, 0x0523 as char, 0x0522 as char,
        0x0525 as char, 0x0524 as char, 0x0527 as char, 0x0526 as char,
        0x0529 as char, 0x0528 as char, 0x052B as char, 0x052A as char,
        0x052D as char, 0x052C as char, 0x052F as char, 0x052E as char,
        0x0561 as char, 0x0531 as char, 0x0562 as char, 0x0532 as char,
        0x0563 as char, 0x0533 as char, 0x0564 as char, 0x0534 as char,
        0x0565 as char, 0x0535 as char, 0x0566 as char, 0x0536 as char,
        0x0567 as char, 0x0537 as char, 0x0568 as char, 0x0538 as char,
        0x0569 as char, 0x0539 as char, 0x056A as char, 0x053A as char,
        0x056B as char, 0x053B as char, 0x056C as char, 0x053C as char,
        0x056D as char, 0x053D as char, 0x056E as char, 0x053E as char,
        0x056F as char, 0x053F as char, 0x0570 as char, 0x0540 as char,
        0x0571 as char, 0x0541 as char, 0x0572 as char, 0x0542 as char,
        0x0573 as char, 0x0543 as char, 0x0574 as char, 0x0544 as char,
        0x0575 as char, 0x0545 as char, 0x0576 as char, 0x0546 as char,
        0x0577 as char, 0x0547 as char, 0x0578 as char, 0x0548 as char,
        0x0579 as char, 0x0549 as char, 0x057A as char, 0x054A as char,
        0x057B as char, 0x054B as char, 0x057C as char, 0x054C as char,
        0x057D as char, 0x054D as char, 0x057E as char, 0x054E as char,
        0x057F as char, 0x054F as char, 0x0580 as char, 0x0550 as char,
        0x0581 as char, 0x0551 as char, 0x0582 as char, 0x0552 as char,
        0x0583 as char, 0x0553 as char, 0x0584 as char, 0x0554 as char,
        0x0585 as char, 0x0555 as char, 0x0586 as char, 0x0556 as char,
    ]
}

⍝ U+0600..U+07FF
micro unicode_case_upper_chunk_3() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0800..U+09FF
micro unicode_case_upper_chunk_4() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0A00..U+0BFF
micro unicode_case_upper_chunk_5() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0C00..U+0DFF
micro unicode_case_upper_chunk_6() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+0E00..U+0FFF
micro unicode_case_upper_chunk_7() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1000..U+11FF
micro unicode_case_upper_chunk_8() -> [char] {
    return [
        0x10D0 as char, 0x1C90 as char, 0x10D1 as char, 0x1C91 as char,
        0x10D2 as char, 0x1C92 as char, 0x10D3 as char, 0x1C93 as char,
        0x10D4 as char, 0x1C94 as char, 0x10D5 as char, 0x1C95 as char,
        0x10D6 as char, 0x1C96 as char, 0x10D7 as char, 0x1C97 as char,
        0x10D8 as char, 0x1C98 as char, 0x10D9 as char, 0x1C99 as char,
        0x10DA as char, 0x1C9A as char, 0x10DB as char, 0x1C9B as char,
        0x10DC as char, 0x1C9C as char, 0x10DD as char, 0x1C9D as char,
        0x10DE as char, 0x1C9E as char, 0x10DF as char, 0x1C9F as char,
        0x10E0 as char, 0x1CA0 as char, 0x10E1 as char, 0x1CA1 as char,
        0x10E2 as char, 0x1CA2 as char, 0x10E3 as char, 0x1CA3 as char,
        0x10E4 as char, 0x1CA4 as char, 0x10E5 as char, 0x1CA5 as char,
        0x10E6 as char, 0x1CA6 as char, 0x10E7 as char, 0x1CA7 as char,
        0x10E8 as char, 0x1CA8 as char, 0x10E9 as char, 0x1CA9 as char,
        0x10EA as char, 0x1CAA as char, 0x10EB as char, 0x1CAB as char,
        0x10EC as char, 0x1CAC as char, 0x10ED as char, 0x1CAD as char,
        0x10EE as char, 0x1CAE as char, 0x10EF as char, 0x1CAF as char,
        0x10F0 as char, 0x1CB0 as char, 0x10F1 as char, 0x1CB1 as char,
        0x10F2 as char, 0x1CB2 as char, 0x10F3 as char, 0x1CB3 as char,
        0x10F4 as char, 0x1CB4 as char, 0x10F5 as char, 0x1CB5 as char,
        0x10F6 as char, 0x1CB6 as char, 0x10F7 as char, 0x1CB7 as char,
        0x10F8 as char, 0x1CB8 as char, 0x10F9 as char, 0x1CB9 as char,
        0x10FA as char, 0x1CBA as char, 0x10FD as char, 0x1CBD as char,
        0x10FE as char, 0x1CBE as char, 0x10FF as char, 0x1CBF as char,
    ]
}

⍝ U+1200..U+13FF
micro unicode_case_upper_chunk_9() -> [char] {
    return [
        0x13F8 as char, 0x13F0 as char, 0x13F9 as char, 0x13F1 as char,
        0x13FA as char, 0x13F2 as char, 0x13FB as char, 0x13F3 as char,
        0x13FC as char, 0x13F4 as char, 0x13FD as char, 0x13F5 as char,
    ]
}

⍝ U+1400..U+15FF
micro unicode_case_upper_chunk_10() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1600..U+17FF
micro unicode_case_upper_chunk_11() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1800..U+19FF
micro unicode_case_upper_chunk_12() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1A00..U+1BFF
micro unicode_case_upper_chunk_13() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+1C00..U+1DFF
micro unicode_case_upper_chunk_14() -> [char] {
    return [
        0x1C80 as char, 0x0412 as char, 0x1C81 as char, 0x0414 as char,
        0x1C82 as char, 0x041E as char, 0x1C83 as char, 0x0421 as char,
        0x1C84 as char, 0x0422 as char, 0x1C85 as char, 0x0422 as char,
        0x1C86 as char, 0x042A as char, 0x1C87 as char, 0x0462 as char,
        0x1C88 as char, 0xA64A as char, 0x1C8A as char, 0x1C89 as char,
        0x1D79 as char, 0xA77D as char, 0x1D7D as char, 0x2C63 as char,
        0x1D8E as char, 0xA7C6 as char,
    ]
}

⍝ U+1E00..U+1FFF
micro unicode_case_upper_chunk_15() -> [char] {
    return [
        0x1E01 as char, 0x1E00 as char, 0x1E03 as char, 0x1E02 as char,
        0x1E05 as char, 0x1E04 as char, 0x1E07 as char, 0x1E06 as char,
        0x1E09 as char, 0x1E08 as char, 0x1E0B as char, 0x1E0A as char,
        0x1E0D as char, 0x1E0C as char, 0x1E0F as char, 0x1E0E as char,
        0x1E11 as char, 0x1E10 as char, 0x1E13 as char, 0x1E12 as char,
        0x1E15 as char, 0x1E14 as char, 0x1E17 as char, 0x1E16 as char,
        0x1E19 as char, 0x1E18 as char, 0x1E1B as char, 0x1E1A as char,
        0x1E1D as char, 0x1E1C as char, 0x1E1F as char, 0x1E1E as char,
        0x1E21 as char, 0x1E20 as char, 0x1E23 as char, 0x1E22 as char,
        0x1E25 as char, 0x1E24 as char, 0x1E27 as char, 0x1E26 as char,
        0x1E29 as char, 0x1E28 as char, 0x1E2B as char, 0x1E2A as char,
        0x1E2D as char, 0x1E2C as char, 0x1E2F as char, 0x1E2E as char,
        0x1E31 as char, 0x1E30 as char, 0x1E33 as char, 0x1E32 as char,
        0x1E35 as char, 0x1E34 as char, 0x1E37 as char, 0x1E36 as char,
        0x1E39 as char, 0x1E38 as char, 0x1E3B as char, 0x1E3A as char,
        0x1E3D as char, 0x1E3C as char, 0x1E3F as char, 0x1E3E as char,
        0x1E41 as char, 0x1E40 as char, 0x1E43 as char, 0x1E42 as char,
        0x1E45 as char, 0x1E44 as char, 0x1E47 as char, 0x1E46 as char,
        0x1E49 as char, 0x1E48 as char, 0x1E4B as char, 0x1E4A as char,
        0x1E4D as char, 0x1E4C as char, 0x1E4F as char, 0x1E4E as char,
        0x1E51 as char, 0x1E50 as char, 0x1E53 as char, 0x1E52 as char,
        0x1E55 as char, 0x1E54 as char, 0x1E57 as char, 0x1E56 as char,
        0x1E59 as char, 0x1E58 as char, 0x1E5B as char, 0x1E5A as char,
        0x1E5D as char, 0x1E5C as char, 0x1E5F as char, 0x1E5E as char,
        0x1E61 as char, 0x1E60 as char, 0x1E63 as char, 0x1E62 as char,
        0x1E65 as char, 0x1E64 as char, 0x1E67 as char, 0x1E66 as char,
        0x1E69 as char, 0x1E68 as char, 0x1E6B as char, 0x1E6A as char,
        0x1E6D as char, 0x1E6C as char, 0x1E6F as char, 0x1E6E as char,
        0x1E71 as char, 0x1E70 as char, 0x1E73 as char, 0x1E72 as char,
        0x1E75 as char, 0x1E74 as char, 0x1E77 as char, 0x1E76 as char,
        0x1E79 as char, 0x1E78 as char, 0x1E7B as char, 0x1E7A as char,
        0x1E7D as char, 0x1E7C as char, 0x1E7F as char, 0x1E7E as char,
        0x1E81 as char, 0x1E80 as char, 0x1E83 as char, 0x1E82 as char,
        0x1E85 as char, 0x1E84 as char, 0x1E87 as char, 0x1E86 as char,
        0x1E89 as char, 0x1E88 as char, 0x1E8B as char, 0x1E8A as char,
        0x1E8D as char, 0x1E8C as char, 0x1E8F as char, 0x1E8E as char,
        0x1E91 as char, 0x1E90 as char, 0x1E93 as char, 0x1E92 as char,
        0x1E95 as char, 0x1E94 as char, 0x1E9B as char, 0x1E60 as char,
        0x1EA1 as char, 0x1EA0 as char, 0x1EA3 as char, 0x1EA2 as char,
        0x1EA5 as char, 0x1EA4 as char, 0x1EA7 as char, 0x1EA6 as char,
        0x1EA9 as char, 0x1EA8 as char, 0x1EAB as char, 0x1EAA as char,
        0x1EAD as char, 0x1EAC as char, 0x1EAF as char, 0x1EAE as char,
        0x1EB1 as char, 0x1EB0 as char, 0x1EB3 as char, 0x1EB2 as char,
        0x1EB5 as char, 0x1EB4 as char, 0x1EB7 as char, 0x1EB6 as char,
        0x1EB9 as char, 0x1EB8 as char, 0x1EBB as char, 0x1EBA as char,
        0x1EBD as char, 0x1EBC as char, 0x1EBF as char, 0x1EBE as char,
        0x1EC1 as char, 0x1EC0 as char, 0x1EC3 as char, 0x1EC2 as char,
        0x1EC5 as char, 0x1EC4 as char, 0x1EC7 as char, 0x1EC6 as char,
        0x1EC9 as char, 0x1EC8 as char, 0x1ECB as char, 0x1ECA as char,
        0x1ECD as char, 0x1ECC as char, 0x1ECF as char, 0x1ECE as char,
        0x1ED1 as char, 0x1ED0 as char, 0x1ED3 as char, 0x1ED2 as char,
        0x1ED5 as char, 0x1ED4 as char, 0x1ED7 as char, 0x1ED6 as char,
        0x1ED9 as char, 0x1ED8 as char, 0x1EDB as char, 0x1EDA as char,
        0x1EDD as char, 0x1EDC as char, 0x1EDF as char, 0x1EDE as char,
        0x1EE1 as char, 0x1EE0 as char, 0x1EE3 as char, 0x1EE2 as char,
        0x1EE5 as char, 0x1EE4 as char, 0x1EE7 as char, 0x1EE6 as char,
        0x1EE9 as char, 0x1EE8 as char, 0x1EEB as char, 0x1EEA as char,
        0x1EED as char, 0x1EEC as char, 0x1EEF as char, 0x1EEE as char,
        0x1EF1 as char, 0x1EF0 as char, 0x1EF3 as char, 0x1EF2 as char,
        0x1EF5 as char, 0x1EF4 as char, 0x1EF7 as char, 0x1EF6 as char,
        0x1EF9 as char, 0x1EF8 as char, 0x1EFB as char, 0x1EFA as char,
        0x1EFD as char, 0x1EFC as char, 0x1EFF as char, 0x1EFE as char,
        0x1F00 as char, 0x1F08 as char, 0x1F01 as char, 0x1F09 as char,
        0x1F02 as char, 0x1F0A as char, 0x1F03 as char, 0x1F0B as char,
        0x1F04 as char, 0x1F0C as char, 0x1F05 as char, 0x1F0D as char,
        0x1F06 as char, 0x1F0E as char, 0x1F07 as char, 0x1F0F as char,
        0x1F10 as char, 0x1F18 as char, 0x1F11 as char, 0x1F19 as char,
        0x1F12 as char, 0x1F1A as char, 0x1F13 as char, 0x1F1B as char,
        0x1F14 as char, 0x1F1C as char, 0x1F15 as char, 0x1F1D as char,
        0x1F20 as char, 0x1F28 as char, 0x1F21 as char, 0x1F29 as char,
        0x1F22 as char, 0x1F2A as char, 0x1F23 as char, 0x1F2B as char,
        0x1F24 as char, 0x1F2C as char, 0x1F25 as char, 0x1F2D as char,
        0x1F26 as char, 0x1F2E as char, 0x1F27 as char, 0x1F2F as char,
        0x1F30 as char, 0x1F38 as char, 0x1F31 as char, 0x1F39 as char,
        0x1F32 as char, 0x1F3A as char, 0x1F33 as char, 0x1F3B as char,
        0x1F34 as char, 0x1F3C as char, 0x1F35 as char, 0x1F3D as char,
        0x1F36 as char, 0x1F3E as char, 0x1F37 as char, 0x1F3F as char,
        0x1F40 as char, 0x1F48 as char, 0x1F41 as char, 0x1F49 as char,
        0x1F42 as char, 0x1F4A as char, 0x1F43 as char, 0x1F4B as char,
        0x1F44 as char, 0x1F4C as char, 0x1F45 as char, 0x1F4D as char,
        0x1F51 as char, 0x1F59 as char, 0x1F53 as char, 0x1F5B as char,
        0x1F55 as char, 0x1F5D as char, 0x1F57 as char, 0x1F5F as char,
        0x1F60 as char, 0x1F68 as char, 0x1F61 as char, 0x1F69 as char,
        0x1F62 as char, 0x1F6A as char, 0x1F63 as char, 0x1F6B as char,
        0x1F64 as char, 0x1F6C as char, 0x1F65 as char, 0x1F6D as char,
        0x1F66 as char, 0x1F6E as char, 0x1F67 as char, 0x1F6F as char,
        0x1F70 as char, 0x1FBA as char, 0x1F71 as char, 0x1FBB as char,
        0x1F72 as char, 0x1FC8 as char, 0x1F73 as char, 0x1FC9 as char,
        0x1F74 as char, 0x1FCA as char, 0x1F75 as char, 0x1FCB as char,
        0x1F76 as char, 0x1FDA as char, 0x1F77 as char, 0x1FDB as char,
        0x1F78 as char, 0x1FF8 as char, 0x1F79 as char, 0x1FF9 as char,
        0x1F7A as char, 0x1FEA as char, 0x1F7B as char, 0x1FEB as char,
        0x1F7C as char, 0x1FFA as char, 0x1F7D as char, 0x1FFB as char,
        0x1F80 as char, 0x1F88 as char, 0x1F81 as char, 0x1F89 as char,
        0x1F82 as char, 0x1F8A as char, 0x1F83 as char, 0x1F8B as char,
        0x1F84 as char, 0x1F8C as char, 0x1F85 as char, 0x1F8D as char,
        0x1F86 as char, 0x1F8E as char, 0x1F87 as char, 0x1F8F as char,
        0x1F90 as char, 0x1F98 as char, 0x1F91 as char, 0x1F99 as char,
        0x1F92 as char, 0x1F9A as char, 0x1F93 as char, 0x1F9B as char,
        0x1F94 as char, 0x1F9C as char, 0x1F95 as char, 0x1F9D as char,
        0x1F96 as char, 0x1F9E as char, 0x1F97 as char, 0x1F9F as char,
        0x1FA0 as char, 0x1FA8 as char, 0x1FA1 as char, 0x1FA9 as char,
        0x1FA2 as char, 0x1FAA as char, 0x1FA3 as char, 0x1FAB as char,
        0x1FA4 as char, 0x1FAC as char, 0x1FA5 as char, 0x1FAD as char,
        0x1FA6 as char, 0x1FAE as char, 0x1FA7 as char, 0x1FAF as char,
        0x1FB0 as char, 0x1FB8 as char, 0x1FB1 as char, 0x1FB9 as char,
        0x1FB3 as char, 0x1FBC as char, 0x1FBE as char, 0x0399 as char,
        0x1FC3 as char, 0x1FCC as char, 0x1FD0 as char, 0x1FD8 as char,
        0x1FD1 as char, 0x1FD9 as char, 0x1FE0 as char, 0x1FE8 as char,
        0x1FE1 as char, 0x1FE9 as char, 0x1FE5 as char, 0x1FEC as char,
        0x1FF3 as char, 0x1FFC as char,
    ]
}

⍝ U+2000..U+21FF
micro unicode_case_upper_chunk_16() -> [char] {
    return [
        0x214E as char, 0x2132 as char, 0x2170 as char, 0x2160 as char,
        0x2171 as char, 0x2161 as char, 0x2172 as char, 0x2162 as char,
        0x2173 as char, 0x2163 as char, 0x2174 as char, 0x2164 as char,
        0x2175 as char, 0x2165 as char, 0x2176 as char, 0x2166 as char,
        0x2177 as char, 0x2167 as char, 0x2178 as char, 0x2168 as char,
        0x2179 as char, 0x2169 as char, 0x217A as char, 0x216A as char,
        0x217B as char, 0x216B as char, 0x217C as char, 0x216C as char,
        0x217D as char, 0x216D as char, 0x217E as char, 0x216E as char,
        0x217F as char, 0x216F as char, 0x2184 as char, 0x2183 as char,
    ]
}

⍝ U+2200..U+23FF
micro unicode_case_upper_chunk_17() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2400..U+25FF
micro unicode_case_upper_chunk_18() -> [char] {
    return [
        0x24D0 as char, 0x24B6 as char, 0x24D1 as char, 0x24B7 as char,
        0x24D2 as char, 0x24B8 as char, 0x24D3 as char, 0x24B9 as char,
        0x24D4 as char, 0x24BA as char, 0x24D5 as char, 0x24BB as char,
        0x24D6 as char, 0x24BC as char, 0x24D7 as char, 0x24BD as char,
        0x24D8 as char, 0x24BE as char, 0x24D9 as char, 0x24BF as char,
        0x24DA as char, 0x24C0 as char, 0x24DB as char, 0x24C1 as char,
        0x24DC as char, 0x24C2 as char, 0x24DD as char, 0x24C3 as char,
        0x24DE as char, 0x24C4 as char, 0x24DF as char, 0x24C5 as char,
        0x24E0 as char, 0x24C6 as char, 0x24E1 as char, 0x24C7 as char,
        0x24E2 as char, 0x24C8 as char, 0x24E3 as char, 0x24C9 as char,
        0x24E4 as char, 0x24CA as char, 0x24E5 as char, 0x24CB as char,
        0x24E6 as char, 0x24CC as char, 0x24E7 as char, 0x24CD as char,
        0x24E8 as char, 0x24CE as char, 0x24E9 as char, 0x24CF as char,
    ]
}

⍝ U+2600..U+27FF
micro unicode_case_upper_chunk_19() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2800..U+29FF
micro unicode_case_upper_chunk_20() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2A00..U+2BFF
micro unicode_case_upper_chunk_21() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+2C00..U+2DFF
micro unicode_case_upper_chunk_22() -> [char] {
    return [
        0x2C30 as char, 0x2C00 as char, 0x2C31 as char, 0x2C01 as char,
        0x2C32 as char, 0x2C02 as char, 0x2C33 as char, 0x2C03 as char,
        0x2C34 as char, 0x2C04 as char, 0x2C35 as char, 0x2C05 as char,
        0x2C36 as char, 0x2C06 as char, 0x2C37 as char, 0x2C07 as char,
        0x2C38 as char, 0x2C08 as char, 0x2C39 as char, 0x2C09 as char,
        0x2C3A as char, 0x2C0A as char, 0x2C3B as char, 0x2C0B as char,
        0x2C3C as char, 0x2C0C as char, 0x2C3D as char, 0x2C0D as char,
        0x2C3E as char, 0x2C0E as char, 0x2C3F as char, 0x2C0F as char,
        0x2C40 as char, 0x2C10 as char, 0x2C41 as char, 0x2C11 as char,
        0x2C42 as char, 0x2C12 as char, 0x2C43 as char, 0x2C13 as char,
        0x2C44 as char, 0x2C14 as char, 0x2C45 as char, 0x2C15 as char,
        0x2C46 as char, 0x2C16 as char, 0x2C47 as char, 0x2C17 as char,
        0x2C48 as char, 0x2C18 as char, 0x2C49 as char, 0x2C19 as char,
        0x2C4A as char, 0x2C1A as char, 0x2C4B as char, 0x2C1B as char,
        0x2C4C as char, 0x2C1C as char, 0x2C4D as char, 0x2C1D as char,
        0x2C4E as char, 0x2C1E as char, 0x2C4F as char, 0x2C1F as char,
        0x2C50 as char, 0x2C20 as char, 0x2C51 as char, 0x2C21 as char,
        0x2C52 as char, 0x2C22 as char, 0x2C53 as char, 0x2C23 as char,
        0x2C54 as char, 0x2C24 as char, 0x2C55 as char, 0x2C25 as char,
        0x2C56 as char, 0x2C26 as char, 0x2C57 as char, 0x2C27 as char,
        0x2C58 as char, 0x2C28 as char, 0x2C59 as char, 0x2C29 as char,
        0x2C5A as char, 0x2C2A as char, 0x2C5B as char, 0x2C2B as char,
        0x2C5C as char, 0x2C2C as char, 0x2C5D as char, 0x2C2D as char,
        0x2C5E as char, 0x2C2E as char, 0x2C5F as char, 0x2C2F as char,
        0x2C61 as char, 0x2C60 as char, 0x2C65 as char, 0x023A as char,
        0x2C66 as char, 0x023E as char, 0x2C68 as char, 0x2C67 as char,
        0x2C6A as char, 0x2C69 as char, 0x2C6C as char, 0x2C6B as char,
        0x2C73 as char, 0x2C72 as char, 0x2C76 as char, 0x2C75 as char,
        0x2C81 as char, 0x2C80 as char, 0x2C83 as char, 0x2C82 as char,
        0x2C85 as char, 0x2C84 as char, 0x2C87 as char, 0x2C86 as char,
        0x2C89 as char, 0x2C88 as char, 0x2C8B as char, 0x2C8A as char,
        0x2C8D as char, 0x2C8C as char, 0x2C8F as char, 0x2C8E as char,
        0x2C91 as char, 0x2C90 as char, 0x2C93 as char, 0x2C92 as char,
        0x2C95 as char, 0x2C94 as char, 0x2C97 as char, 0x2C96 as char,
        0x2C99 as char, 0x2C98 as char, 0x2C9B as char, 0x2C9A as char,
        0x2C9D as char, 0x2C9C as char, 0x2C9F as char, 0x2C9E as char,
        0x2CA1 as char, 0x2CA0 as char, 0x2CA3 as char, 0x2CA2 as char,
        0x2CA5 as char, 0x2CA4 as char, 0x2CA7 as char, 0x2CA6 as char,
        0x2CA9 as char, 0x2CA8 as char, 0x2CAB as char, 0x2CAA as char,
        0x2CAD as char, 0x2CAC as char, 0x2CAF as char, 0x2CAE as char,
        0x2CB1 as char, 0x2CB0 as char, 0x2CB3 as char, 0x2CB2 as char,
        0x2CB5 as char, 0x2CB4 as char, 0x2CB7 as char, 0x2CB6 as char,
        0x2CB9 as char, 0x2CB8 as char, 0x2CBB as char, 0x2CBA as char,
        0x2CBD as char, 0x2CBC as char, 0x2CBF as char, 0x2CBE as char,
        0x2CC1 as char, 0x2CC0 as char, 0x2CC3 as char, 0x2CC2 as char,
        0x2CC5 as char, 0x2CC4 as char, 0x2CC7 as char, 0x2CC6 as char,
        0x2CC9 as char, 0x2CC8 as char, 0x2CCB as char, 0x2CCA as char,
        0x2CCD as char, 0x2CCC as char, 0x2CCF as char, 0x2CCE as char,
        0x2CD1 as char, 0x2CD0 as char, 0x2CD3 as char, 0x2CD2 as char,
        0x2CD5 as char, 0x2CD4 as char, 0x2CD7 as char, 0x2CD6 as char,
        0x2CD9 as char, 0x2CD8 as char, 0x2CDB as char, 0x2CDA as char,
        0x2CDD as char, 0x2CDC as char, 0x2CDF as char, 0x2CDE as char,
        0x2CE1 as char, 0x2CE0 as char, 0x2CE3 as char, 0x2CE2 as char,
        0x2CEC as char, 0x2CEB as char, 0x2CEE as char, 0x2CED as char,
        0x2CF3 as char, 0x2CF2 as char, 0x2D00 as char, 0x10A0 as char,
        0x2D01 as char, 0x10A1 as char, 0x2D02 as char, 0x10A2 as char,
        0x2D03 as char, 0x10A3 as char, 0x2D04 as char, 0x10A4 as char,
        0x2D05 as char, 0x10A5 as char, 0x2D06 as char, 0x10A6 as char,
        0x2D07 as char, 0x10A7 as char, 0x2D08 as char, 0x10A8 as char,
        0x2D09 as char, 0x10A9 as char, 0x2D0A as char, 0x10AA as char,
        0x2D0B as char, 0x10AB as char, 0x2D0C as char, 0x10AC as char,
        0x2D0D as char, 0x10AD as char, 0x2D0E as char, 0x10AE as char,
        0x2D0F as char, 0x10AF as char, 0x2D10 as char, 0x10B0 as char,
        0x2D11 as char, 0x10B1 as char, 0x2D12 as char, 0x10B2 as char,
        0x2D13 as char, 0x10B3 as char, 0x2D14 as char, 0x10B4 as char,
        0x2D15 as char, 0x10B5 as char, 0x2D16 as char, 0x10B6 as char,
        0x2D17 as char, 0x10B7 as char, 0x2D18 as char, 0x10B8 as char,
        0x2D19 as char, 0x10B9 as char, 0x2D1A as char, 0x10BA as char,
        0x2D1B as char, 0x10BB as char, 0x2D1C as char, 0x10BC as char,
        0x2D1D as char, 0x10BD as char, 0x2D1E as char, 0x10BE as char,
        0x2D1F as char, 0x10BF as char, 0x2D20 as char, 0x10C0 as char,
        0x2D21 as char, 0x10C1 as char, 0x2D22 as char, 0x10C2 as char,
        0x2D23 as char, 0x10C3 as char, 0x2D24 as char, 0x10C4 as char,
        0x2D25 as char, 0x10C5 as char, 0x2D27 as char, 0x10C7 as char,
        0x2D2D as char, 0x10CD as char,
    ]
}

⍝ U+2E00..U+2FFF
micro unicode_case_upper_chunk_23() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3000..U+31FF
micro unicode_case_upper_chunk_24() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3200..U+33FF
micro unicode_case_upper_chunk_25() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3400..U+35FF
micro unicode_case_upper_chunk_26() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3600..U+37FF
micro unicode_case_upper_chunk_27() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3800..U+39FF
micro unicode_case_upper_chunk_28() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3A00..U+3BFF
micro unicode_case_upper_chunk_29() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3C00..U+3DFF
micro unicode_case_upper_chunk_30() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+3E00..U+3FFF
micro unicode_case_upper_chunk_31() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4000..U+41FF
micro unicode_case_upper_chunk_32() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4200..U+43FF
micro unicode_case_upper_chunk_33() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4400..U+45FF
micro unicode_case_upper_chunk_34() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4600..U+47FF
micro unicode_case_upper_chunk_35() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4800..U+49FF
micro unicode_case_upper_chunk_36() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4A00..U+4BFF
micro unicode_case_upper_chunk_37() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4C00..U+4DFF
micro unicode_case_upper_chunk_38() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+4E00..U+4FFF
micro unicode_case_upper_chunk_39() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5000..U+51FF
micro unicode_case_upper_chunk_40() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5200..U+53FF
micro unicode_case_upper_chunk_41() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5400..U+55FF
micro unicode_case_upper_chunk_42() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5600..U+57FF
micro unicode_case_upper_chunk_43() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5800..U+59FF
micro unicode_case_upper_chunk_44() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5A00..U+5BFF
micro unicode_case_upper_chunk_45() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5C00..U+5DFF
micro unicode_case_upper_chunk_46() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+5E00..U+5FFF
micro unicode_case_upper_chunk_47() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6000..U+61FF
micro unicode_case_upper_chunk_48() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6200..U+63FF
micro unicode_case_upper_chunk_49() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6400..U+65FF
micro unicode_case_upper_chunk_50() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6600..U+67FF
micro unicode_case_upper_chunk_51() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6800..U+69FF
micro unicode_case_upper_chunk_52() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6A00..U+6BFF
micro unicode_case_upper_chunk_53() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6C00..U+6DFF
micro unicode_case_upper_chunk_54() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+6E00..U+6FFF
micro unicode_case_upper_chunk_55() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7000..U+71FF
micro unicode_case_upper_chunk_56() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7200..U+73FF
micro unicode_case_upper_chunk_57() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7400..U+75FF
micro unicode_case_upper_chunk_58() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7600..U+77FF
micro unicode_case_upper_chunk_59() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7800..U+79FF
micro unicode_case_upper_chunk_60() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7A00..U+7BFF
micro unicode_case_upper_chunk_61() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7C00..U+7DFF
micro unicode_case_upper_chunk_62() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+7E00..U+7FFF
micro unicode_case_upper_chunk_63() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8000..U+81FF
micro unicode_case_upper_chunk_64() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8200..U+83FF
micro unicode_case_upper_chunk_65() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8400..U+85FF
micro unicode_case_upper_chunk_66() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8600..U+87FF
micro unicode_case_upper_chunk_67() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8800..U+89FF
micro unicode_case_upper_chunk_68() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8A00..U+8BFF
micro unicode_case_upper_chunk_69() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8C00..U+8DFF
micro unicode_case_upper_chunk_70() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+8E00..U+8FFF
micro unicode_case_upper_chunk_71() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9000..U+91FF
micro unicode_case_upper_chunk_72() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9200..U+93FF
micro unicode_case_upper_chunk_73() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9400..U+95FF
micro unicode_case_upper_chunk_74() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9600..U+97FF
micro unicode_case_upper_chunk_75() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9800..U+99FF
micro unicode_case_upper_chunk_76() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9A00..U+9BFF
micro unicode_case_upper_chunk_77() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9C00..U+9DFF
micro unicode_case_upper_chunk_78() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+9E00..U+9FFF
micro unicode_case_upper_chunk_79() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A000..U+A1FF
micro unicode_case_upper_chunk_80() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A200..U+A3FF
micro unicode_case_upper_chunk_81() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A400..U+A5FF
micro unicode_case_upper_chunk_82() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+A600..U+A7FF
micro unicode_case_upper_chunk_83() -> [char] {
    return [
        0xA641 as char, 0xA640 as char, 0xA643 as char, 0xA642 as char,
        0xA645 as char, 0xA644 as char, 0xA647 as char, 0xA646 as char,
        0xA649 as char, 0xA648 as char, 0xA64B as char, 0xA64A as char,
        0xA64D as char, 0xA64C as char, 0xA64F as char, 0xA64E as char,
        0xA651 as char, 0xA650 as char, 0xA653 as char, 0xA652 as char,
        0xA655 as char, 0xA654 as char, 0xA657 as char, 0xA656 as char,
        0xA659 as char, 0xA658 as char, 0xA65B as char, 0xA65A as char,
        0xA65D as char, 0xA65C as char, 0xA65F as char, 0xA65E as char,
        0xA661 as char, 0xA660 as char, 0xA663 as char, 0xA662 as char,
        0xA665 as char, 0xA664 as char, 0xA667 as char, 0xA666 as char,
        0xA669 as char, 0xA668 as char, 0xA66B as char, 0xA66A as char,
        0xA66D as char, 0xA66C as char, 0xA681 as char, 0xA680 as char,
        0xA683 as char, 0xA682 as char, 0xA685 as char, 0xA684 as char,
        0xA687 as char, 0xA686 as char, 0xA689 as char, 0xA688 as char,
        0xA68B as char, 0xA68A as char, 0xA68D as char, 0xA68C as char,
        0xA68F as char, 0xA68E as char, 0xA691 as char, 0xA690 as char,
        0xA693 as char, 0xA692 as char, 0xA695 as char, 0xA694 as char,
        0xA697 as char, 0xA696 as char, 0xA699 as char, 0xA698 as char,
        0xA69B as char, 0xA69A as char, 0xA723 as char, 0xA722 as char,
        0xA725 as char, 0xA724 as char, 0xA727 as char, 0xA726 as char,
        0xA729 as char, 0xA728 as char, 0xA72B as char, 0xA72A as char,
        0xA72D as char, 0xA72C as char, 0xA72F as char, 0xA72E as char,
        0xA733 as char, 0xA732 as char, 0xA735 as char, 0xA734 as char,
        0xA737 as char, 0xA736 as char, 0xA739 as char, 0xA738 as char,
        0xA73B as char, 0xA73A as char, 0xA73D as char, 0xA73C as char,
        0xA73F as char, 0xA73E as char, 0xA741 as char, 0xA740 as char,
        0xA743 as char, 0xA742 as char, 0xA745 as char, 0xA744 as char,
        0xA747 as char, 0xA746 as char, 0xA749 as char, 0xA748 as char,
        0xA74B as char, 0xA74A as char, 0xA74D as char, 0xA74C as char,
        0xA74F as char, 0xA74E as char, 0xA751 as char, 0xA750 as char,
        0xA753 as char, 0xA752 as char, 0xA755 as char, 0xA754 as char,
        0xA757 as char, 0xA756 as char, 0xA759 as char, 0xA758 as char,
        0xA75B as char, 0xA75A as char, 0xA75D as char, 0xA75C as char,
        0xA75F as char, 0xA75E as char, 0xA761 as char, 0xA760 as char,
        0xA763 as char, 0xA762 as char, 0xA765 as char, 0xA764 as char,
        0xA767 as char, 0xA766 as char, 0xA769 as char, 0xA768 as char,
        0xA76B as char, 0xA76A as char, 0xA76D as char, 0xA76C as char,
        0xA76F as char, 0xA76E as char, 0xA77A as char, 0xA779 as char,
        0xA77C as char, 0xA77B as char, 0xA77F as char, 0xA77E as char,
        0xA781 as char, 0xA780 as char, 0xA783 as char, 0xA782 as char,
        0xA785 as char, 0xA784 as char, 0xA787 as char, 0xA786 as char,
        0xA78C as char, 0xA78B as char, 0xA791 as char, 0xA790 as char,
        0xA793 as char, 0xA792 as char, 0xA794 as char, 0xA7C4 as char,
        0xA797 as char, 0xA796 as char, 0xA799 as char, 0xA798 as char,
        0xA79B as char, 0xA79A as char, 0xA79D as char, 0xA79C as char,
        0xA79F as char, 0xA79E as char, 0xA7A1 as char, 0xA7A0 as char,
        0xA7A3 as char, 0xA7A2 as char, 0xA7A5 as char, 0xA7A4 as char,
        0xA7A7 as char, 0xA7A6 as char, 0xA7A9 as char, 0xA7A8 as char,
        0xA7B5 as char, 0xA7B4 as char, 0xA7B7 as char, 0xA7B6 as char,
        0xA7B9 as char, 0xA7B8 as char, 0xA7BB as char, 0xA7BA as char,
        0xA7BD as char, 0xA7BC as char, 0xA7BF as char, 0xA7BE as char,
        0xA7C1 as char, 0xA7C0 as char, 0xA7C3 as char, 0xA7C2 as char,
        0xA7C8 as char, 0xA7C7 as char, 0xA7CA as char, 0xA7C9 as char,
        0xA7CD as char, 0xA7CC as char, 0xA7D1 as char, 0xA7D0 as char,
        0xA7D7 as char, 0xA7D6 as char, 0xA7D9 as char, 0xA7D8 as char,
        0xA7DB as char, 0xA7DA as char, 0xA7F6 as char, 0xA7F5 as char,
    ]
}

⍝ U+A800..U+A9FF
micro unicode_case_upper_chunk_84() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+AA00..U+ABFF
micro unicode_case_upper_chunk_85() -> [char] {
    return [
        0xAB53 as char, 0xA7B3 as char, 0xAB70 as char, 0x13A0 as char,
        0xAB71 as char, 0x13A1 as char, 0xAB72 as char, 0x13A2 as char,
        0xAB73 as char, 0x13A3 as char, 0xAB74 as char, 0x13A4 as char,
        0xAB75 as char, 0x13A5 as char, 0xAB76 as char, 0x13A6 as char,
        0xAB77 as char, 0x13A7 as char, 0xAB78 as char, 0x13A8 as char,
        0xAB79 as char, 0x13A9 as char, 0xAB7A as char, 0x13AA as char,
        0xAB7B as char, 0x13AB as char, 0xAB7C as char, 0x13AC as char,
        0xAB7D as char, 0x13AD as char, 0xAB7E as char, 0x13AE as char,
        0xAB7F as char, 0x13AF as char, 0xAB80 as char, 0x13B0 as char,
        0xAB81 as char, 0x13B1 as char, 0xAB82 as char, 0x13B2 as char,
        0xAB83 as char, 0x13B3 as char, 0xAB84 as char, 0x13B4 as char,
        0xAB85 as char, 0x13B5 as char, 0xAB86 as char, 0x13B6 as char,
        0xAB87 as char, 0x13B7 as char, 0xAB88 as char, 0x13B8 as char,
        0xAB89 as char, 0x13B9 as char, 0xAB8A as char, 0x13BA as char,
        0xAB8B as char, 0x13BB as char, 0xAB8C as char, 0x13BC as char,
        0xAB8D as char, 0x13BD as char, 0xAB8E as char, 0x13BE as char,
        0xAB8F as char, 0x13BF as char, 0xAB90 as char, 0x13C0 as char,
        0xAB91 as char, 0x13C1 as char, 0xAB92 as char, 0x13C2 as char,
        0xAB93 as char, 0x13C3 as char, 0xAB94 as char, 0x13C4 as char,
        0xAB95 as char, 0x13C5 as char, 0xAB96 as char, 0x13C6 as char,
        0xAB97 as char, 0x13C7 as char, 0xAB98 as char, 0x13C8 as char,
        0xAB99 as char, 0x13C9 as char, 0xAB9A as char, 0x13CA as char,
        0xAB9B as char, 0x13CB as char, 0xAB9C as char, 0x13CC as char,
        0xAB9D as char, 0x13CD as char, 0xAB9E as char, 0x13CE as char,
        0xAB9F as char, 0x13CF as char, 0xABA0 as char, 0x13D0 as char,
        0xABA1 as char, 0x13D1 as char, 0xABA2 as char, 0x13D2 as char,
        0xABA3 as char, 0x13D3 as char, 0xABA4 as char, 0x13D4 as char,
        0xABA5 as char, 0x13D5 as char, 0xABA6 as char, 0x13D6 as char,
        0xABA7 as char, 0x13D7 as char, 0xABA8 as char, 0x13D8 as char,
        0xABA9 as char, 0x13D9 as char, 0xABAA as char, 0x13DA as char,
        0xABAB as char, 0x13DB as char, 0xABAC as char, 0x13DC as char,
        0xABAD as char, 0x13DD as char, 0xABAE as char, 0x13DE as char,
        0xABAF as char, 0x13DF as char, 0xABB0 as char, 0x13E0 as char,
        0xABB1 as char, 0x13E1 as char, 0xABB2 as char, 0x13E2 as char,
        0xABB3 as char, 0x13E3 as char, 0xABB4 as char, 0x13E4 as char,
        0xABB5 as char, 0x13E5 as char, 0xABB6 as char, 0x13E6 as char,
        0xABB7 as char, 0x13E7 as char, 0xABB8 as char, 0x13E8 as char,
        0xABB9 as char, 0x13E9 as char, 0xABBA as char, 0x13EA as char,
        0xABBB as char, 0x13EB as char, 0xABBC as char, 0x13EC as char,
        0xABBD as char, 0x13ED as char, 0xABBE as char, 0x13EE as char,
        0xABBF as char, 0x13EF as char,
    ]
}

⍝ U+AC00..U+ADFF
micro unicode_case_upper_chunk_86() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+AE00..U+AFFF
micro unicode_case_upper_chunk_87() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B000..U+B1FF
micro unicode_case_upper_chunk_88() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B200..U+B3FF
micro unicode_case_upper_chunk_89() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B400..U+B5FF
micro unicode_case_upper_chunk_90() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B600..U+B7FF
micro unicode_case_upper_chunk_91() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+B800..U+B9FF
micro unicode_case_upper_chunk_92() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BA00..U+BBFF
micro unicode_case_upper_chunk_93() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BC00..U+BDFF
micro unicode_case_upper_chunk_94() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+BE00..U+BFFF
micro unicode_case_upper_chunk_95() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C000..U+C1FF
micro unicode_case_upper_chunk_96() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C200..U+C3FF
micro unicode_case_upper_chunk_97() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C400..U+C5FF
micro unicode_case_upper_chunk_98() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C600..U+C7FF
micro unicode_case_upper_chunk_99() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+C800..U+C9FF
micro unicode_case_upper_chunk_100() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CA00..U+CBFF
micro unicode_case_upper_chunk_101() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CC00..U+CDFF
micro unicode_case_upper_chunk_102() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+CE00..U+CFFF
micro unicode_case_upper_chunk_103() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D000..U+D1FF
micro unicode_case_upper_chunk_104() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D200..U+D3FF
micro unicode_case_upper_chunk_105() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D400..U+D5FF
micro unicode_case_upper_chunk_106() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D600..U+D7FF
micro unicode_case_upper_chunk_107() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+D800..U+D9FF
micro unicode_case_upper_chunk_108() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DA00..U+DBFF
micro unicode_case_upper_chunk_109() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DC00..U+DDFF
micro unicode_case_upper_chunk_110() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+DE00..U+DFFF
micro unicode_case_upper_chunk_111() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E000..U+E1FF
micro unicode_case_upper_chunk_112() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E200..U+E3FF
micro unicode_case_upper_chunk_113() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E400..U+E5FF
micro unicode_case_upper_chunk_114() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E600..U+E7FF
micro unicode_case_upper_chunk_115() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+E800..U+E9FF
micro unicode_case_upper_chunk_116() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EA00..U+EBFF
micro unicode_case_upper_chunk_117() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EC00..U+EDFF
micro unicode_case_upper_chunk_118() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+EE00..U+EFFF
micro unicode_case_upper_chunk_119() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F000..U+F1FF
micro unicode_case_upper_chunk_120() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F200..U+F3FF
micro unicode_case_upper_chunk_121() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F400..U+F5FF
micro unicode_case_upper_chunk_122() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F600..U+F7FF
micro unicode_case_upper_chunk_123() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+F800..U+F9FF
micro unicode_case_upper_chunk_124() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FA00..U+FBFF
micro unicode_case_upper_chunk_125() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FC00..U+FDFF
micro unicode_case_upper_chunk_126() -> [char] {
    let empty: [char] = []
    return empty
}

⍝ U+FE00..U+FFFF
micro unicode_case_upper_chunk_127() -> [char] {
    return [
        0xFF41 as char, 0xFF21 as char, 0xFF42 as char, 0xFF22 as char,
        0xFF43 as char, 0xFF23 as char, 0xFF44 as char, 0xFF24 as char,
        0xFF45 as char, 0xFF25 as char, 0xFF46 as char, 0xFF26 as char,
        0xFF47 as char, 0xFF27 as char, 0xFF48 as char, 0xFF28 as char,
        0xFF49 as char, 0xFF29 as char, 0xFF4A as char, 0xFF2A as char,
        0xFF4B as char, 0xFF2B as char, 0xFF4C as char, 0xFF2C as char,
        0xFF4D as char, 0xFF2D as char, 0xFF4E as char, 0xFF2E as char,
        0xFF4F as char, 0xFF2F as char, 0xFF50 as char, 0xFF30 as char,
        0xFF51 as char, 0xFF31 as char, 0xFF52 as char, 0xFF32 as char,
        0xFF53 as char, 0xFF33 as char, 0xFF54 as char, 0xFF34 as char,
        0xFF55 as char, 0xFF35 as char, 0xFF56 as char, 0xFF36 as char,
        0xFF57 as char, 0xFF37 as char, 0xFF58 as char, 0xFF38 as char,
        0xFF59 as char, 0xFF39 as char, 0xFF5A as char, 0xFF3A as char,
    ]
}
