#!/usr/bin/env node

/**
 * Unicode 大小写映射表生成器（`unicode.case`）
 *
 * 从 Unicode 官方 UCD 生成 V 源码数据表：
 *   - `UnicodeData.txt` 的 simple 大小写映射（字段 12 = uppercase、13 = lowercase），
 *     BMP 全量；非 BMP 源/目标跳过（本语言 `char` 是 u16）。
 *
 * 编码：每对「源码点、目标码点」占 2 个 `[char]` 槽位，按源码点严格递增。
 * 按 BMP 的 16 个 4096 码点区间切块，每块一个函数：OVM 单个函数代码上限 64KiB，
 * 整表放一个函数会超限，分块是硬约束而不是风格选择。
 *
 * 数据版本与输入哈希写死在生成文件头；同一份数据重跑得到逐字节相同的 V 文件。
 *
 * 用法：
 *   node scripts/gen-unicode-case.mjs [--data-dir <dir>] [--out <path>]
 *
 * 默认数据目录：<repo>/.cache/unicode/<version>（缺失时自动下载）
 * 默认输出：<repo>/projects/unicode._/unicode.case/source/generated_simple_case.v
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const VERSION = '16.0.0';
const UCD_BASE = `https://www.unicode.org/Public/${VERSION}/ucd`;
const DATA_FILE = 'UnicodeData.txt';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');
const DEFAULT_DATA_DIR = path.join(REPO_ROOT, '.cache', 'unicode', VERSION);
const DEFAULT_OUT = path.join(
    REPO_ROOT,
    'projects',
    'unicode._',
    'unicode.case',
    'source',
    'generated_simple_case.v',
);

const BMP_MAX = 0xffff;
const CHUNK_SIZE = 0x200;
const CHUNK_COUNT = 128;

function parseArgs(argv) {
    const options = { dataDir: DEFAULT_DATA_DIR, out: DEFAULT_OUT };
    for (let index = 0; index < argv.length; index += 1) {
        const arg = argv[index];
        if (arg === '--data-dir') {
            options.dataDir = path.resolve(argv[index + 1]);
            index += 1;
        } else if (arg === '--out') {
            options.out = path.resolve(argv[index + 1]);
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

async function ensureData(dataDir) {
    fs.mkdirSync(dataDir, { recursive: true });
    const target = path.join(dataDir, DATA_FILE);
    if (fs.existsSync(target)) {
        return;
    }
    const url = `${UCD_BASE}/${DATA_FILE}`;
    process.stderr.write(`下载 ${url}\n`);
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`下载失败 ${url}：HTTP ${response.status}`);
    }
    fs.writeFileSync(target, Buffer.from(await response.arrayBuffer()));
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

function main() {
    const options = parseArgs(process.argv.slice(2));
    const stats = { nonBmpSource: 0, nonBmpTarget: 0 };

    ensureData(options.dataDir).then(() => {
        const dataPath = path.join(options.dataDir, DATA_FILE);
        const lines = fs.readFileSync(dataPath, 'utf8').split('\n');
        const simple = parseSimpleMappings(lines, stats);

        // UCD 16.0.0 的 BMP simple 映射规模；同时钉住若干代表项。
        if (simple.lower.length !== 1178) {
            throw new Error(`simple 小写映射条数不符：${simple.lower.length}`);
        }
        if (simple.upper.length !== 1195) {
            throw new Error(`simple 大写映射条数不符：${simple.upper.length}`);
        }
        assertHas(simple.upper, 0x0061, 0x0041);
        assertHas(simple.lower, 0x0041, 0x0061);
        assertHas(simple.lower, 0x0391, 0x03b1);

        const output = [
            'namespace unicode.case;',
            '',
            '⍝ 自动生成，请勿手改：node scripts/gen-unicode-case.mjs',
            '⍝ 包版本：unicode.case 0.1.0',
            `⍝ 数据版本：Unicode ${VERSION}`,
            '⍝ 来源与输入哈希：',
            `⍝   ${UCD_BASE}/${DATA_FILE}`,
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

        fs.mkdirSync(path.dirname(options.out), { recursive: true });
        fs.writeFileSync(options.out, output, 'utf8');

        process.stderr.write(`已生成 ${options.out}\n`);
        process.stderr.write(
            `simple 小写 ${simple.lower.length} 条 / simple 大写 ${simple.upper.length} 条；`
            + `跳过非 BMP 源 ${stats.nonBmpSource} / 目标 ${stats.nonBmpTarget}\n`,
        );
    }).catch((error) => {
        process.stderr.write(`${error.stack || error.message}\n`);
        process.exit(1);
    });
}

main();
