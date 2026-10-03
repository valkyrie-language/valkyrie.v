import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import os from 'node:os';

import { AD_HOC_SCRIPT_ENTRIES, OFFICIAL_SCRIPT_ENTRIES, repoRootFrom, validateModuleSystem, resolveNodeEntry, resolveJvmEntry, resolveWasiEntry, validateCanonicalRunContract } from '../bootstrap-lib.mjs';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = repoRootFrom(path.join(SCRIPT_DIR, '..'));

describe('正式产物入口', () => {
    it('拒绝旧命名、旧 contract 和任意 WASI 文件', () => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'legion-entry-rejection-'));
        for (const file of ['legion_tools.mjs', 'legion_tools.wasm', 'legion_tools.jar', 'other.wasi', 'other.mjs', 'other.wasm']) {
            fs.writeFileSync(path.join(directory, file), 'fixture');
        }
        fs.writeFileSync(path.join(directory, 'run-contract.txt'), 'physical_entry: "other.mjs"');
        fs.writeFileSync(path.join(directory, 'run-contracts.txt'), 'physical_entry: "other.mjs"');
        assert.equal(resolveNodeEntry(directory).legionMjs, null);
        assert.equal(resolveJvmEntry(directory).legionJar, null);
        assert.equal(resolveWasiEntry(directory).legionWasm, null);
    });

    it('Node 入口必须具有完整文件对', () => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'legion-entry-pair-'));
        fs.writeFileSync(path.join(directory, 'legion.mjs'), 'fixture');
        assert.equal(resolveNodeEntry(directory).legionMjs, null);
        fs.writeFileSync(path.join(directory, 'legion.wasm'), 'fixture');
        assert.equal(resolveNodeEntry(directory).legionMjs, path.join(directory, 'legion.mjs'));
        assert.equal(resolveNodeEntry(directory).legionWasm, path.join(directory, 'legion.wasm'));
    });

    it('缺少正式 execution manifest 不能通过合同检查', () => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'legion-contract-missing-'));
        assert.equal(validateCanonicalRunContract(directory).valid, false);
        fs.writeFileSync(path.join(directory, 'run-contract.txt'), 'physical_entry: "legion.mjs"');
        assert.equal(validateCanonicalRunContract(directory).valid, false);
    });
});

describe('validateModuleSystem', () => {
    it('passes against the current valkyrie.v workspace layout', () => {
        const result = validateModuleSystem(ROOT_DIR, false);
        assert.equal(result.success, true, result.errors.join('; '));
    });

    it('resolves nyar manifest from projects/nyar._ nested layout', () => {
        const nyarManifest = path.join(ROOT_DIR, 'projects', 'nyar._', 'projects', 'nyar', 'legion.von');
        assert.equal(fs.existsSync(nyarManifest), true);
        const result = validateModuleSystem(ROOT_DIR, true);
        assert.equal(result.success, true);
    });
});

describe('bootstrap-clr.mjs module guard', () => {
    it('does not shadow bootstrap-lib validateModuleSystem with legacy nyar path', () => {
        const clrScript = fs.readFileSync(path.join(SCRIPT_DIR, '..', 'bootstrap-clr.mjs'), 'utf8');
        assert.equal(
            /function validateModuleSystem\s*\(/.test(clrScript),
            false,
            'bootstrap-clr.mjs must not define a local validateModuleSystem',
        );
        assert.equal(
            /validateModuleSystem\(ROOT_DIR/.test(clrScript),
            true,
            'bootstrap-clr.mjs must call validateModuleSystem(ROOT_DIR, ...)',
        );
        assert.equal(
            /projects['"],\s*['"]nyar['"],\s*['"]legion\.von/.test(clrScript),
            false,
            'bootstrap-clr.mjs must not hardcode projects/nyar/legion.von',
        );
    });
});

describe('gate schema', () => {
    it('defines four-target L2 and WASI witness profiles', async () => {
        const {
            BOOTSTRAP_TRACKS,
            L2_GATE_NAMES,
            WITNESS_GATE_NAMES,
            l2GateNamesForTrack,
        } = await import('../bootstrap-lib.mjs');
        assert.equal(Object.keys(BOOTSTRAP_TRACKS).length, 4);
        assert.equal(L2_GATE_NAMES.length, 7);
        assert.equal(WITNESS_GATE_NAMES.length, 6);
        assert.equal(l2GateNamesForTrack('node').at(-1), 'v1 / v2 比对');
    });
});

describe('scripts hygiene', () => {
    it('keeps ad hoc analyzers out of the scripts directory', () => {
        const scriptsDir = path.join(ROOT_DIR, 'scripts');
        const leaked = AD_HOC_SCRIPT_ENTRIES.filter((entry) => fs.existsSync(path.join(scriptsDir, entry)));
        assert.deepEqual(
            leaked,
            [],
            `temporary analyzers must not exist under scripts/: ${leaked.join(', ')}`,
        );
    });

    it('keeps scripts/ root on the official whitelist', () => {
        const scriptsDir = path.join(ROOT_DIR, 'scripts');
        const actual = fs.readdirSync(scriptsDir).sort();
        const expected = [...OFFICIAL_SCRIPT_ENTRIES].sort();
        assert.deepEqual(
            actual,
            expected,
            `scripts/ root drifted from whitelist; actual=${actual.join(', ')}`,
        );
    });
});
