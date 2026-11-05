#!/usr/bin/env node

/**
 * Unicode `White_Space` 属性表生成器（`unicode.types`）
 *
 * 从 Unicode 官方 UCD `PropList.txt` 生成 V 源码数据表：
 *   - `White_Space` 属性区间（含端点），供 std 的 `Utf8Text::is_whitespace_code_point` 二分查表。
 *
 * 数据版本与输入哈希写死在生成文件头；同一份数据重跑得到逐字节相同的 V 文件。
 *
 * 用法：
 *   node scripts/gen-unicode-types.mjs [--data-dir <dir>] [--out <path>]
 *
 * 默认数据目录：<repo>/.cache/unicode/<version>（缺失时自动下载）
 * 默认输出：<repo>/projects/unicode._/unicode.types/source/generated_white_space.v
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const VERSION = '16.0.0';
const UCD_BASE = `https://www.unicode.org/Public/${VERSION}/ucd`;
const DATA_FILE = 'PropList.txt';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');
const DEFAULT_DATA_DIR = path.join(REPO_ROOT, '.cache', 'unicode', VERSION);
const DEFAULT_OUT = path.join(
    REPO_ROOT,
    'projects',
    'unicode._',
    'unicode.types',
    'source',
    'generated_white_space.v',
);

const BMP_MAX = 0xffff;

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

function parsePropertyRanges(lines, property, stats) {
    const ranges = [];
    for (const line of lines) {
        const body = line.split('#')[0].trim();
        if (body === '') {
            continue;
        }
        const fields = body.split(';').map((field) => field.trim());
        if (fields.length < 2 || fields[1] !== property) {
            continue;
        }
        const [startText, endText] = fields[0].split('..');
        const start = parseInt(startText, 16);
        const end = endText ? parseInt(endText, 16) : start;
        if (start > BMP_MAX) {
            stats.nonBmpRanges += 1;
            continue;
        }
        ranges.push([start, Math.min(end, BMP_MAX)]);
    }
    return ranges;
}

function mergeRanges(ranges) {
    const sorted = ranges.slice().sort((left, right) => left[0] - right[0] || left[1] - right[1]);
    const merged = [];
    for (const [start, end] of sorted) {
        const last = merged[merged.length - 1];
        if (last && start <= last[1] + 1) {
            last[1] = Math.max(last[1], end);
        } else {
            merged.push([start, end]);
        }
    }
    return merged;
}

function rangeCount(ranges) {
    return ranges.reduce((total, [start, end]) => total + (end - start + 1), 0);
}

function contains(ranges, code) {
    return ranges.some(([start, end]) => code >= start && code <= end);
}

function assertHas(ranges, code, expected) {
    if (contains(ranges, code) !== expected) {
        throw new Error(`U+${code.toString(16).toUpperCase()} 的 White_Space 判定不符：期望 ${expected}`);
    }
}

function emitArray(name, values) {
    const lines = [`micro ${name}() -> [char] {`, '    return ['];
    for (let index = 0; index < values.length; index += 4) {
        lines.push(`        ${values.slice(index, index + 4).map(hex).join(', ')},`);
    }
    lines.push('    ]', '}', '');
    return lines.join('\n');
}

function main() {
    const options = parseArgs(process.argv.slice(2));
    const stats = { nonBmpRanges: 0 };

    ensureData(options.dataDir).then(() => {
        const dataPath = path.join(options.dataDir, DATA_FILE);
        const lines = fs.readFileSync(dataPath, 'utf8').split('\n');
        const ranges = mergeRanges(parsePropertyRanges(lines, 'White_Space', stats));
        const codePoints = rangeCount(ranges);

        // UCD 16.0.0 的 White_Space 为 25 个码点、10 段；以下断言同时钉住关键语义：
        // U+0085 是空白，U+200B / U+FEFF 不是空白。
        if (codePoints !== 25) {
            throw new Error(`White_Space 码点总数不符：${codePoints}`);
        }
        if (ranges.length !== 10) {
            throw new Error(`White_Space 区间段数不符：${ranges.length}`);
        }
        assertHas(ranges, 0x0009, true);
        assertHas(ranges, 0x0085, true);
        assertHas(ranges, 0x3000, true);
        assertHas(ranges, 0x200b, false);
        assertHas(ranges, 0xfeff, false);

        const output = [
            'namespace unicode.types;',
            '',
            '⍝ 自动生成，请勿手改：node scripts/gen-unicode-types.mjs',
            `⍝ 包版本：unicode.types 0.1.0`,
            `⍝ 数据版本：Unicode ${VERSION}`,
            '⍝ 来源与输入哈希：',
            `⍝   ${UCD_BASE}/${DATA_FILE}`,
            `⍝     SHA-256 ${sha256(dataPath)}`,
            '⍝ 覆盖范围：',
            `⍝   White_Space ${ranges.length} 段 / ${codePoints} 个码点（含 U+0085，不含 U+200B/U+FEFF）`,
            '⍝ 限制：`char` 是 u16，仅 BMP；White_Space 全部位于 BMP，无截断。',
            `⍝   非 BMP 区间跳过 ${stats.nonBmpRanges} 段。`,
            '',
            '⍝ `White_Space` 区间：偶数下标起点、奇数下标终点（含端点），按起点严格递增。',
            emitArray('unicode_white_space_ranges', ranges.flat()),
        ].join('\n');

        fs.mkdirSync(path.dirname(options.out), { recursive: true });
        fs.writeFileSync(options.out, output, 'utf8');

        process.stderr.write(`已生成 ${options.out}\n`);
        process.stderr.write(`White_Space ${ranges.length} 段 / ${codePoints} 个码点\n`);
    }).catch((error) => {
        process.stderr.write(`${error.stack || error.message}\n`);
        process.exit(1);
    });
}

main();
