// database.conformance 执行 runner（media-drive 同形态）：
// 绕过 legion test 的产物门禁，直接以 callExport 调用会话产物逐条验收。
// 用法：node run.mjs <test-session-dir>（session-dir 含本会话产生的 conformance mjs 与 wasm 字节；
// 产物由 `legion test --target wasm` 在本包下生成于 .cache/test/wasm32-unknown-unknown-wasm）。
// 退出码：任一用例失败即 1；全部 0 即全绿。
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const sessionDir = process.argv[2];
if (!sessionDir) {
    console.error("usage: node run.mjs <test-session-dir>");
    process.exit(2);
}

const moduleUrl = pathToFileURL(join(sessionDir, "database_conformance.mjs")).href;
const session = await import(moduleUrl);

// i64 通道按 BigInt 全宽比较。
const normalize = (raw) => (typeof raw === "bigint" ? raw : BigInt(raw >>> 0));

const cases = [
    ["conformance_memory_c01", 0n],
    ["conformance_memory_c02", 0n],
    ["conformance_memory_c03", 0n],
    ["conformance_memory_c04", 0n],
    ["conformance_memory_c05", 0n],
    ["conformance_memory_c06", 0n],
    ["conformance_memory_c07", 0n],
    ["conformance_memory_c08", 0n],
    ["conformance_memory_c09", 0n],
    ["conformance_memory_c10", 0n],
    ["conformance_memory_c11", 0n],
    ["conformance_memory_c12", 0n],
    ["conformance_memory_c13", 0n],
    ["conformance_memory_c14", 0n],
    ["conformance_memory_c15", 0n],
    ["conformance_memory_c16", 0n],
];

let failed = 0;
for (const [name, expected] of cases) {
    const actual = normalize(await session.callExport(name));
    const ok = actual === expected;
    console.log(`${ok ? "PASS" : "FAIL"} ${name}: got ${actual}, want ${expected}`);
    if (!ok) failed += 1;
}

if (failed > 0) {
    console.error(`${failed} case(s) failed`);
    process.exit(1);
}
console.log(`${cases.length} case(s) green`);
