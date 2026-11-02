// media 驱动器：与 examples/std-data-drive 同一形态——绕过 legion test 的 wasm 产物
// 格式门禁缺陷（runner 把 .mjs 误判为非目标产物），直接以 callExport 调用会话产物
// 并按已知答案断言。
// 用法：node drive.mjs <session-dir>（session-dir 含 media_drive.mjs 与 wasm 字节）。
// 退出码：任一用例失败即 1。
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const sessionDir = process.argv[2];
if (!sessionDir) {
    console.error("usage: node drive.mjs <test-session-dir>");
    process.exit(2);
}

const moduleUrl = pathToFileURL(join(sessionDir, "media_drive.mjs")).href;
const session = await import(moduleUrl);

// i32 通道按无符号还原；i64 通道保留 BigInt 全宽。
const normalize = (raw) => (typeof raw === "bigint" ? raw : BigInt(raw >>> 0));

const cases = [
    // 图像模型
    ["drive_raster_geometry", 20212n],              // 宽2*10000 + 高2*100 + 缓冲12
    ["drive_raster_offset_and_bounds", 901n],       // 偏移9*100 + 越界报错1
    // 颜色转换
    ["drive_color_gray_to_rgb", 777n],              // 灰度7复制三通道
    ["drive_color_rgb_to_gray", 76n],               // (255*77)>>8
    // 管线
    ["drive_crop_right_column", 255255n],           // 绿通道255*1000 + 白红255
    ["drive_crop_out_of_bounds", 1n],
    ["drive_resize_nearest", 255255n],              // 角(3,3)白 + 边(2,0)绿
    // PPM
    ["drive_ppm_round_trip", 1023n],                // 往返一致1*1000 + 23字节
    ["drive_ppm_bad_magic", 1n],
    ["drive_ppm_truncated_keeps_prefix", 1255n],    // 截断诊断1*1000 + 前缀红255
    // BMP
    ["drive_bmp_round_trip", 1070n],                // 往返一致1*1000 + 70字节
    ["drive_bmp_pixel_order", 255255n],             // (0,0)红 + (0,1)蓝
    ["drive_bmp_top_down_rejected", 1n],
    // PNG
    ["drive_png_container_stops_at_inflate", 10111n], // inflate 未落地诊断1*10000 + 无crc误报1*100 + 宽1*10 + 高1
    ["drive_png_crc_mismatch", 1n],
    ["drive_png_bad_signature", 1n],
    ["drive_png_unfilter_sub", 1535n],              // 15*100 + 35
    ["drive_png_unfilter_average", 111621n],        // 11*10000 + 16*100 + 21
    ["drive_png_unfilter_paeth", 1535n],            // 15*100 + 35
    ["drive_png_unfilter_unknown_filter", 1n],
];

let failed = 0;
for (const [name, expected] of cases) {
    const actual = normalize(await session.callExport(name));
    const ok = actual === expected;
    console.log(`${ok ? "PASS" : "FAIL"} ${name}: got ${actual} (0x${actual.toString(16)}), want ${expected} (0x${expected.toString(16)})`);
    if (!ok) failed += 1;
}

if (failed > 0) {
    console.error(`${failed} case(s) failed`);
    process.exit(1);
}
console.log(`${cases.length} cases green`);
