#!/usr/bin/env node

/**
 * JVM/CLR managed lane 最小可执行基线 harness
 *
 * 验证 `legion build --target jvm|clr` 能编译出可被真实 `java` / `dotnet` 执行的产物，
 * 并取回返回值。本 harness 只消费本仓 `examples/lane-managed-probe`（基线）与
 * `examples/lane-managed-container-probe`（容器，std HashMap/ArrayList 默认体）。
 *
 * 用法：
 *   node scripts/lane-managed-probe.mjs [--valkyrie-addon <path>]
 *
 * 退出码：
 *   0 — 基线两 lane 实跑退出码 42 通过；容器探针编译状态按文档记录（预期阻塞于原语层）。
 *   1 — 基线任一 lane 失败或容器探针状态偏离文档。
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');

function parseArgs() {
    const argv = process.argv.slice(2);
    const options = { valkyrieAddon: null };
    for (let i = 0; i < argv.length; i++) {
        if (argv[i] === '--valkyrie-addon' && argv[i + 1]) {
            options.valkyrieAddon = argv[++i];
        }
    }
    return options;
}

function resolveValkyrieAddon(explicit) {
    if (explicit && fs.existsSync(explicit)) return explicit;
    const env = process.env.VALKYRIE_ADDON;
    if (env && fs.existsSync(env)) return env;
    // 默认：本 worktree 的兄弟 nyar-vm.rs 平台包
    const candidates = [
        path.resolve(REPO_ROOT, '..', '..', 'nyar-vm.rs', 'projects', 'nyar.ts', 'platforms', 'valkyrie-win32-x64', 'lib', 'valkyrie.win32-x64-msvc.node'),
        path.resolve(REPO_ROOT, '..', 'nyar-vm.rs', 'projects', 'nyar.ts', 'platforms', 'valkyrie-win32-x64', 'lib', 'valkyrie.win32-x64-msvc.node'),
    ];
    for (const candidate of candidates) {
        if (fs.existsSync(candidate)) return candidate;
    }
    return null;
}

function rmrf(target) {
    if (fs.existsSync(target)) fs.rmSync(target, { recursive: true, force: true });
}

function buildProject(binding, projectDir, target, outputDir) {
    rmrf(outputDir);
    return binding.legionBuild({ projectDir, target, outputDir });
}

function runClrExe(exePath) {
    const result = spawnSync(exePath, [], { encoding: 'utf8', timeout: 15000, windowsHide: true });
    return { exitCode: result.status, stdout: result.stdout ?? '', stderr: result.stderr ?? '' };
}

function runJvmJar(jarPath, projectFunctionClass, staticMethod, workDir) {
    const launcherSource = `public class Launcher { public static void main(String[] a) throws Exception { Class<?> c = Class.forName("${projectFunctionClass}"); java.lang.reflect.Method m = c.getMethod("${staticMethod}"); System.exit(((Integer) m.invoke(null)).intValue()); } }\n`;
    const launcherFile = path.join(workDir, 'Launcher.java');
    fs.writeFileSync(launcherFile, launcherSource);
    const compile = spawnSync('javac', ['-cp', jarPath, launcherFile], { encoding: 'utf8', timeout: 30000, windowsHide: true });
    if (compile.status !== 0) {
        return { stage: 'javac', exitCode: compile.status, stderr: compile.stderr ?? '' };
    }
    const run = spawnSync('java', ['-cp', `${jarPath}${path.delimiter}.`, 'Launcher'], { cwd: workDir, encoding: 'utf8', timeout: 15000, windowsHide: true });
    return { stage: 'java', exitCode: run.status, stdout: run.stdout ?? '', stderr: run.stderr ?? '' };
}

function main() {
    const options = parseArgs();
    const addonPath = resolveValkyrieAddon(options.valkyrieAddon);
    if (!addonPath) {
        console.error('error: 找不到 valkyrie addon（设置 VALKYRIE_ADDON 或 --valkyrie-addon）');
        process.exit(1);
    }
    console.log(`addon: ${addonPath}`);

    let binding;
    try {
        const req = createRequire(import.meta.url);
        binding = req(addonPath);
    } catch (error) {
        console.error(`error: 加载 addon 失败: ${error.message}`);
        process.exit(1);
    }

    const baselineProject = path.join(REPO_ROOT, 'examples', 'lane-managed-probe');
    const containerProject = path.join(REPO_ROOT, 'examples', 'lane-managed-container-probe');
    const outRoot = path.join(REPO_ROOT, 'dist', 'lane-managed');

    let failures = 0;

    // ── 基线探针（必须两 lane 实跑退出码 42）────────────────────────────
    console.log('\n════ 基线探针（lane-managed-probe）════');
    for (const lane of ['clr', 'jvm']) {
        const outputDir = path.join(outRoot, `baseline-${lane}`);
        const result = buildProject(binding, baselineProject, lane, outputDir);
        if (!result.ok) {
            console.error(`  [${lane}] build 失败: ${result.error}`);
            failures++;
            continue;
        }
        const artifact = result.artifacts[0];
        console.log(`  [${lane}] build ok: ${path.basename(artifact)}`);
        let outcome;
        if (lane === 'clr') {
            outcome = runClrExe(artifact);
        } else {
            outcome = runJvmJar(artifact, 'nyar.lane_managed_probe_functions', 'lane_managed_probe__main', outputDir);
        }
        if (outcome.exitCode === 42) {
            console.log(`  [${lane}] run ok: exit 42`);
        } else {
            console.error(`  [${lane}] run 失败: exit=${outcome.exitCode} stderr=${outcome.stderr?.trim() ?? ''}`);
            failures++;
        }
    }

    // ── 容器探针（std HashMap/ArrayList 默认体；预期阻塞于原语/emitter 层）────
    // 基线 harness 提交时容器探针尚未加入；存在才检查，保证每个提交自洽。
    if (fs.existsSync(containerProject)) {
        console.log('\n════ 容器探针（lane-managed-container-probe）════');
        const expectedContainerBlockers = {
            clr: '__u64_rem',
            jvm: '__u64_rem',
        };
        for (const lane of ['clr', 'jvm']) {
            const outputDir = path.join(outRoot, `container-${lane}`);
            const result = buildProject(binding, containerProject, lane, outputDir);
            if (result.ok) {
                console.error(`  [${lane}] 意外成功 — 文档预期阻塞于原语层，请更新 harness`);
                failures++;
                continue;
            }
            const expected = expectedContainerBlockers[lane];
            if (result.error.includes(expected)) {
                console.log(`  [${lane}] 文档预期阻塞: ${expected}（managed lane 原语层未绑定）`);
            } else if (result.error.includes('List') || result.error.includes('hash_map_keys') || result.error.includes('hash_map_values') || result.error.includes('to_list')) {
                console.error(`  [${lane}] 回归: 冒充 provider 类型错误重现 — ${result.error}`);
                failures++;
            } else {
                console.log(`  [${lane}] 阻塞于其它原语/emitter 缺口: ${result.error}`);
            }
        }
    }

    console.log(`\n${failures === 0 ? 'PASS' : 'FAIL'}: failures=${failures}`);
    process.exit(failures === 0 ? 0 : 1);
}

main();
