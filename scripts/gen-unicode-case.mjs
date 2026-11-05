#!/usr/bin/env node

/**
 * Unicode 大小写映射表生成器（`unicode.case` + `unicode.types` 的码点属性）
 *
 * 从 Unicode 官方 UCD 生成 V 源码数据表：
 *   - `UnicodeData.txt` 的 simple 大小写映射（字段 12 = uppercase、13 = lowercase），
 *     BMP 全量；非 BMP 源/目标跳过（本语言 `char` 是 u16）。
 *   - `SpecialCasing.txt` 的无条件 1→多映射（`ß→SS`、`İ→i̇`、`ŉ→ʼN`、`ǰ→J̌` 等），
 *     条件项（Final_Sigma / 土耳其语 / 立陶宛语）不进表，由实现按上下文处理。
 *   - `DerivedCoreProperties.txt` 的 `Cased` 与 `Case_Ignorable`，供 Final_Sigma 上下文判定。
 *
 * 数据版本与输入哈希写死在生成文件头；同一份数据重跑得到逐字节相同的 V 文件。
 *
 * 用法：
 *   node scripts/gen-unicode-case.mjs [--data-dir <dir>]
 *
 * 默认数据目录：<repo>/.cache/unicode/<version>（缺失时自动下载）
 * 默认输出：
 *   <repo>/projects/unicode._/unicode.case/source/generated_simple_case.v
 *   <repo>/projects/unicode._/unicode.case/source/generated_special_case.v
 *   <repo>/projects/unicode._/unicode.types/source/generated_case_properties.v
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const VERSION = '16.0.0';
const UCD_BASE = `https://www.unicode.org/Public/${VERSION}/ucd`;
const UNICODE_DATA = 'UnicodeData.txt';
const SPECIAL_CASING = 'SpecialCasing.txt';
const DERIVED_CORE = 'DerivedCoreProperties.txt';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');
const DEFAULT_DATA_DIR = path.join(REPO_ROOT, '.cache', 'unicode', VERSION);
const CASE_SOURCE = path.join(REPO_ROOT, 'projects', 'unicode._', 'unicode.case', 'source');
const TYPES_SOURCE = path.join(REPO_ROOT, 'projects', 'unicode._', 'unicode.types', 'source');

const BMP_MAX = 0xffff;
const CHUNK_SIZE = 0x200;
const CHUNK_COUNT = 128;

function parseArgs(argv) {
    const options = { dataDir: DEFAULT_DATA_DIR };
    for (let index = 0; index < argv.length; index += 1) {
        const arg = argv[index];
        if (arg === '--data-dir') {
            options.dataDir = path.resolve(argv[index + 1]);
            index += 1;
        } else {
            throw new Error(`未知参数：${arg}`);
        }
    }
    return options;
}

function sha256(filePath) {
    return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex').toUpperCase();
}

async function ensureData(dataDir, fileName) {
    fs.mkdirSync(dataDir, { recursive: true });
    const target = path.join(dataDir, fileName);
    if (fs.existsSync(target)) {
        return target;
    }
    const url = `${UCD_BASE}/${fileName}`;
    process.stderr.write(`下载 ${url}\n`);
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`下载失败 ${url}：HTTP ${response.status}`);
    }
    fs.writeFileSync(target, Buffer.from(await response.arrayBuffer()));
    return target;
}

function hex(value) {
    // 跨包数组元素用 `char`：本编译器对 `u32` 等原语是包内名义类型，`[u32]` 跨包会报
    // “`u32` 与 `u32` 不兼容”；`char` 是语言内建类型，可安全跨包传递。
    return `0x${value.toString(16).toUpperCase().padStart(4, '0')} as char`;
}

function parseSimpleMappings(lines, stats) {
    const upper = [];
    const lower = [];
    for (const line of lines) {
        if (!line.trim()) {
            continue;
        }
        const fields = line.split(';');
        const code = parseInt(fields[0], 16);
        if (code > BMP_MAX) {
            stats.nonBmpSource += 1;
            continue;
        }
        for (const [field, target] of [[12, upper], [13, lower]]) {
            const text = (fields[field] || '').trim();
            if (text === '') {
                continue;
            }
            const mapped = parseInt(text, 16);
            if (mapped > BMP_MAX) {
                stats.nonBmpTarget += 1;
                continue;
            }
            if (mapped !== code) {
                target.push([code, mapped]);
            }
        }
    }
    return { upper, lower };
}

/** 解析 `SpecialCasing.txt`：只收条件字段为空的无条件项，按方向拆成 1→多表。 */
function parseSpecialCasing(text) {
    const lower = [];
    const upper = [];
    for (const raw of text.split('\n')) {
        const line = raw.trim();
        if (!line || line.startsWith('#')) {
            continue;
        }
        const body = line.split('#')[0].trim();
        if (!body) {
            continue;
        }
        const fields = body.split(';').map((field) => field.trim());
        if (fields.length < 4) {
            throw new Error(`SpecialCasing 行字段不足：${raw}`);
        }
        const code = parseInt(fields[0], 16);
        const condition = fields[4] || '';
        if (condition !== '') {
            continue;
        }
        // 字段 1 = 小写、字段 3 = 大写；都是空格分隔的码点序列。
        const lowerSeq = fields[1] === '' ? [] : fields[1].split(/\s+/).map((item) => parseInt(item, 16));
        const upperSeq = fields[3] === '' ? [] : fields[3].split(/\s+/).map((item) => parseInt(item, 16));
        if (lowerSeq.length > 1) {
            lower.push([code, lowerSeq]);
        }
        if (upperSeq.length > 1) {
            upper.push([code, upperSeq]);
        }
    }
    lower.sort((left, right) => left[0] - right[0]);
    upper.sort((left, right) => left[0] - right[0]);
    return { lower, upper };
}

/** 解析 `DerivedCoreProperties.txt` 中某个属性，返回按起点递增的闭区间对。 */
function parseDerivedProperty(lines, property) {
    const ranges = [];
    for (const raw of lines) {
        const body = raw.split('#')[0].trim();
        if (!body) {
            continue;
        }
        const fields = body.split(';').map((field) => field.trim());
        if (fields.length < 2 || fields[1] !== property) {
            continue;
        }
        const [startText, endText] = fields[0].split('..');
        const start = parseInt(startText, 16);
        const end = endText === undefined ? start : parseInt(endText, 16);
        if (start > BMP_MAX) {
            continue;
        }
        ranges.push([start, Math.min(end, BMP_MAX)]);
    }
    ranges.sort((left, right) => left[0] - right[0]);
    return ranges;
}

function assertHas(pairs, code, expected) {
    const found = pairs.find(([source]) => source === code);
    if (!found) {
        throw new Error(`缺少 U+${code.toString(16).toUpperCase()} 的 simple 映射`);
    }
    if (found[1] !== expected) {
        throw new Error(
            `U+${code.toString(16).toUpperCase()} 映射不符：期望 U+${expected.toString(16).toUpperCase()}`,
        );
    }
}

function assertSpecial(table, code, expected) {
    const found = table.find(([source]) => source === code);
    if (!found) {
        throw new Error(`缺少 U+${code.toString(16).toUpperCase()} 的 1→多映射`);
    }
    if (found[1].join(',') !== expected.join(',')) {
        throw new Error(`U+${code.toString(16).toUpperCase()} 的 1→多映射不符`);
    }
}

function emitChunks(name, pairs) {
    const lines = [];
    for (let chunk = 0; chunk < CHUNK_COUNT; chunk += 1) {
        const start = chunk * CHUNK_SIZE;
        const end = start + CHUNK_SIZE - 1;
        const slice = pairs.filter(([source]) => source >= start && source <= end).flat();
        lines.push(`⍝ U+${start.toString(16).toUpperCase().padStart(4, '0')}..U+${end.toString(16).toUpperCase().padStart(4, '0')}`);
        lines.push(`micro ${name}_${chunk}() -> [char] {`);
        if (slice.length === 0) {
            // 空字面量 `[]` 无法独立推断元素类型（会报 “trait 约束未解析：LiteralSequence”），
            // 先落到带注解的局部变量再返回。
            lines.push('    let empty: [char] = []');
            lines.push('    return empty');
        } else {
            lines.push('    return [');
            for (let index = 0; index < slice.length; index += 4) {
                lines.push(`        ${slice.slice(index, index + 4).map(hex).join(', ')},`);
            }
            lines.push('    ]');
        }
        lines.push('}', '');
    }
    return lines.join('\n');
}

/** 分派器：按码点所在块调用对应块表，未命中返回原码点。 */
function emitDispatch(prefix, name) {
    const lines = [
        '⍝ 分派器：按码点所在块选表；查不到即返回原码点（大小写映射是局部函数，未命中即自身）。',
        `micro ${prefix}_simple(c: char) -> char {`,
        '    let code: u32 = c as u32',
        `    if code < 0x${CHUNK_SIZE.toString(16).toUpperCase()} {`,
        `        return simple_pair_lookup(${name}_0(), code)`,
        '    }',
        '',
    ];
    for (let chunk = 1; chunk < CHUNK_COUNT; chunk += 1) {
        const boundary = (chunk + 1) * CHUNK_SIZE;
        if (chunk === CHUNK_COUNT - 1) {
            lines.push(`    return simple_pair_lookup(${name}_${chunk}(), code)`);
        } else {
            lines.push(`    if code < 0x${boundary.toString(16).toUpperCase()} {`);
            lines.push(`        return simple_pair_lookup(${name}_${chunk}(), code)`);
            lines.push('    }');
            lines.push('');
        }
    }
    lines.push('}', '');
    return lines.join('\n');
}

/** 1→多表：每条记录固定 5 个槽位「源码点、长度、码点0、码点1、码点2」，按源码点递增。 */
const SPECIAL_STRIDE = 5;

function emitSpecial(name, entries) {
    const flat = [];
    for (const [code, sequence] of entries) {
        if (sequence.length > 3) {
            throw new Error(`U+${code.toString(16).toUpperCase()} 的 1→多长度 ${sequence.length} 超出 3`);
        }
        flat.push(hex(code), `0x${sequence.length.toString(16).toUpperCase()} as char`);
        for (let index = 0; index < 3; index += 1) {
            flat.push(hex(sequence[index] === undefined ? 0 : sequence[index]));
        }
    }
    const lines = [`micro ${name}() -> [char] {`];
    if (flat.length === 0) {
        lines.push('    let empty: [char] = []');
        lines.push('    return empty');
    } else {
        lines.push('    return [');
        for (let index = 0; index < flat.length; index += 5) {
            lines.push(`        ${flat.slice(index, index + 5).join(', ')},`);
        }
        lines.push('    ]');
    }
    lines.push('}', '');
    return lines.join('\n');
}

function emitRanges(name, ranges) {
    const flat = ranges.flat();
    const lines = [`micro ${name}() -> [char] {`];
    if (flat.length === 0) {
        lines.push('    let empty: [char] = []');
        lines.push('    return empty');
    } else {
        lines.push('    return [');
        for (let index = 0; index < flat.length; index += 4) {
            lines.push(`        ${flat.slice(index, index + 4).map(hex).join(', ')},`);
        }
        lines.push('    ]');
    }
    lines.push('}', '');
    return lines.join('\n');
}

async function main() {
    const options = parseArgs(process.argv.slice(2));
    const stats = { nonBmpSource: 0, nonBmpTarget: 0 };

    const dataPath = await ensureData(options.dataDir, UNICODE_DATA);
    const specialPath = await ensureData(options.dataDir, SPECIAL_CASING);
    const derivedPath = await ensureData(options.dataDir, DERIVED_CORE);

    const lines = fs.readFileSync(dataPath, 'utf8').split('\n');
    const simple = parseSimpleMappings(lines, stats);
    const special = parseSpecialCasing(fs.readFileSync(specialPath, 'utf8'));
    const derivedLines = fs.readFileSync(derivedPath, 'utf8').split('\n');
    const cased = parseDerivedProperty(derivedLines, 'Cased');
    const caseIgnorable = parseDerivedProperty(derivedLines, 'Case_Ignorable');

    // UCD 16.0.0 的规模；同时钉住若干代表项。
    if (simple.lower.length !== 1178) {
        throw new Error(`simple 小写映射条数不符：${simple.lower.length}`);
    }
    if (simple.upper.length !== 1195) {
        throw new Error(`simple 大写映射条数不符：${simple.upper.length}`);
    }
    assertHas(simple.upper, 0x0061, 0x0041);
    assertHas(simple.lower, 0x0041, 0x0061);
    assertHas(simple.lower, 0x0391, 0x03b1);
    if (special.lower.length === 0 || special.upper.length === 0) {
        throw new Error('SpecialCasing 无条件 1→多映射为空');
    }
    assertSpecial(special.upper, 0x00df, [0x0053, 0x0053]);
    assertSpecial(special.lower, 0x0130, [0x0069, 0x0307]);
    assertSpecial(special.upper, 0x0149, [0x02bc, 0x004e]);
    assertSpecial(special.upper, 0x01f0, [0x004a, 0x030c]);
    if (cased.length === 0 || caseIgnorable.length === 0) {
        throw new Error('DerivedCoreProperties 的 Cased / Case_Ignorable 为空');
    }

    const simpleOutput = [
        'namespace unicode.case;',
        '',
        '⍝ 自动生成，请勿手改：node scripts/gen-unicode-case.mjs',
        '⍝ 包版本：unicode.case 0.1.0',
        `⍝ 数据版本：Unicode ${VERSION}`,
        '⍝ 来源与输入哈希：',
        `⍝   ${UCD_BASE}/${UNICODE_DATA}`,
        `⍝     SHA-256 ${sha256(dataPath)}`,
        '⍝ 覆盖范围：',
        `⍝   simple 小写 ${simple.lower.length} 条 / simple 大写 ${simple.upper.length} 条（仅 BMP）`,
        `⍝   跳过非 BMP 源 ${stats.nonBmpSource} 条 / 非 BMP 目标 ${stats.nonBmpTarget} 条`,
        '⍝ 限制：`char` 是 u16，非 BMP 不能表达，直接不支持。',
        '⍝ 布局：每对「源码点、目标码点」占 2 个槽位，按源码点严格递增；',
        `⍝   按 ${CHUNK_SIZE} 码点切成 ${CHUNK_COUNT} 块，每块一个函数（OVM 单函数代码上限 64KiB）。`,
        '',
        '⍝ ────────── simple 小写 ──────────',
        emitDispatch('lower', 'unicode_case_lower_chunk'),
        emitChunks('unicode_case_lower_chunk', simple.lower),
        '⍝ ────────── simple 大写 ──────────',
        emitDispatch('upper', 'unicode_case_upper_chunk'),
        emitChunks('unicode_case_upper_chunk', simple.upper),
    ].join('\n');

    const specialOutput = [
        'namespace unicode.case;',
        '',
        '⍝ 自动生成，请勿手改：node scripts/gen-unicode-case.mjs',
        '⍝ 包版本：unicode.case 0.1.0',
        `⍝ 数据版本：Unicode ${VERSION}`,
        '⍝ 来源与输入哈希：',
        `⍝   ${UCD_BASE}/${SPECIAL_CASING}`,
        `⍝     SHA-256 ${sha256(specialPath)}`,
        '⍝ 覆盖范围：',
        `⍝   无条件 1→多：小写 ${special.lower.length} 条 / 大写 ${special.upper.length} 条`,
        '⍝   条件项（Final_Sigma、土耳其语、立陶宛语）不进表，由实现按上下文处理。',
        `⍝ 布局：每条记录固定 ${SPECIAL_STRIDE} 个槽位「源码点、长度、码点0、码点1、码点2」，按源码点递增。`,
        '',
        '⍝ ────────── 1→多 小写 ──────────',
        emitSpecial('unicode_case_lower_special', special.lower),
        '⍝ ────────── 1→多 大写 ──────────',
        emitSpecial('unicode_case_upper_special', special.upper),
    ].join('\n');

    const propertiesOutput = [
        'namespace unicode.types;',
        '',
        '⍝ 自动生成，请勿手改：node scripts/gen-unicode-case.mjs',
        '⍝ 包版本：unicode.types 0.1.0',
        `⍝ 数据版本：Unicode ${VERSION}`,
        '⍝ 来源与输入哈希：',
        `⍝   ${UCD_BASE}/${DERIVED_CORE}`,
        `⍝     SHA-256 ${sha256(derivedPath)}`,
        '⍝ 覆盖范围（仅 BMP）：',
        `⍝   Cased ${cased.length} 段，Case_Ignorable ${caseIgnorable.length} 段`,
        '⍝ 布局：偶数下标起点、奇数下标终点（含端点），按起点严格递增。',
        '',
        '⍝ ────────── Cased ──────────',
        emitRanges('unicode_cased_ranges', cased),
        '⍝ ────────── Case_Ignorable ──────────',
        emitRanges('unicode_case_ignorable_ranges', caseIgnorable),
    ].join('\n');

    fs.mkdirSync(CASE_SOURCE, { recursive: true });
    fs.mkdirSync(TYPES_SOURCE, { recursive: true });
    const outputs = [
        [path.join(CASE_SOURCE, 'generated_simple_case.v'), simpleOutput],
        [path.join(CASE_SOURCE, 'generated_special_case.v'), specialOutput],
        [path.join(TYPES_SOURCE, 'generated_case_properties.v'), propertiesOutput],
    ];
    for (const [file, content] of outputs) {
        fs.writeFileSync(file, content, 'utf8');
        process.stderr.write(`已生成 ${file}\n`);
    }
    process.stderr.write(
        `simple 小写 ${simple.lower.length} / 大写 ${simple.upper.length}；`
        + `1→多 小写 ${special.lower.length} / 大写 ${special.upper.length}；`
        + `Cased ${cased.length} 段 / Case_Ignorable ${caseIgnorable.length} 段\n`,
    );
}

main().catch((error) => {
    process.stderr.write(`${error.stack || error.message}\n`);
    process.exit(1);
});
