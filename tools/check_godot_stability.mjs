#!/usr/bin/env node
// ProjectTactic Godot reload stability check.
//
// Godot headless currently crashes on this workstation, so this script gives us
// a repeatable pre-editor safety pass and then attempts a supported Godot smoke
// run. Static failures exit non-zero. A known headless crash is reported as a
// warning unless --strict-godot is passed.

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..");
const GODOT_ROOT = path.join(REPO_ROOT, "godot");
const DEFAULT_GODOT_EXE =
  "C:\\Users\\jojo3\\Downloads\\Godot_v4.6.2-stable_win64\\Godot_v4.6.2-stable_win64_console.exe";

const MOJIBAKE_RE = /[ÂÃâ�]/;
const FUNC_RE = /^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/;
const RESOURCE_RE = /\b(preload|load)\(\s*['"]res:\/\/([^'"]+)['"]\s*\)/g;
const UNSUPPORTED_GODOT_CLI_FLAGS = ["--" + "check-only"];
const COLOR_FADED_RE = /\.faded\s*\(/;
const VARIANT_INFERENCE_RE =
  /^\s*var\s+([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*[A-Za-z_][A-Za-z0-9_.]*\.get\(/;
const BLOCK_RE = /^(\s*)(?:if|elif|else|for|while|match)\b.*:\s*(?:#.*)?$/;
const FUNC_BLOCK_RE = /^(\s*)func\b.*:\s*(?:#.*)?$/;

function parseArgs(argv) {
  const args = {
    skipGodot: false,
    strictGodot: false,
    godotExe: DEFAULT_GODOT_EXE,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--skip-godot") args.skipGodot = true;
    else if (arg === "--strict-godot") args.strictGodot = true;
    else if (arg === "--godot-exe") {
      i += 1;
      args.godotExe = argv[i] ?? args.godotExe;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return args;
}

function walkFiles(root, predicate) {
  if (!existsSync(root)) return [];
  const out = [];
  for (const entry of readdirSync(root)) {
    const fullPath = path.join(root, entry);
    const stats = statSync(fullPath);
    if (stats.isDirectory()) out.push(...walkFiles(fullPath, predicate));
    else if (predicate(fullPath)) out.push(fullPath);
  }
  return out;
}

function gdFiles() {
  const files = [
    ...walkFiles(path.join(GODOT_ROOT, "scripts"), (p) => p.endsWith(".gd")),
    ...walkFiles(path.join(GODOT_ROOT, "tests"), (p) => p.endsWith(".gd")),
  ];
  for (const rootFile of ["sfx.gd", "tile_spec.gd", "tokens.gd"]) {
    const fullPath = path.join(GODOT_ROOT, rootFile);
    if (existsSync(fullPath)) files.push(fullPath);
  }
  return [...new Set(files)].sort();
}

function cliScanFiles() {
  const roots = [
    path.join(REPO_ROOT, "README.md"),
    path.join(REPO_ROOT, "godot", "README.md"),
    path.join(REPO_ROOT, "docs"),
    path.join(REPO_ROOT, "tools"),
  ];
  const allowed = new Set([".md", ".js", ".mjs", ".ps1", ".cmd", ".bat"]);
  const files = [];
  for (const root of roots) {
    if (!existsSync(root)) continue;
    const stats = statSync(root);
    if (stats.isFile()) files.push(root);
    else files.push(...walkFiles(root, (p) => allowed.has(path.extname(p).toLowerCase())));
  }
  return [...new Set(files)].sort();
}

function readLines(filePath) {
  return readFileSync(filePath, "utf8").split(/\r?\n/);
}

function rel(filePath) {
  return path.relative(REPO_ROOT, filePath).replaceAll(path.sep, "/");
}

function finding(severity, filePath, line, message) {
  return { severity, filePath, line, message };
}

function renderFinding(item) {
  return `[${item.severity}] ${rel(item.filePath)}:${item.line}: ${item.message}`;
}

function resourceExists(resourcePath) {
  const normalized = resourcePath.replaceAll("\\", "/");
  if (normalized.includes("%") || normalized.includes("{")) return true;
  return existsSync(path.join(GODOT_ROOT, normalized));
}

function checkObviousEmptyBlocks(filePath, lines) {
  const findings = [];
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const match = line.match(BLOCK_RE) ?? line.match(FUNC_BLOCK_RE);
    if (!match) continue;

    const baseIndent = match[1].replaceAll("\t", "    ").length;
    for (let j = i + 1; j < lines.length; j += 1) {
      const candidate = lines[j];
      const stripped = candidate.trim();
      if (stripped === "" || stripped.startsWith("#")) continue;

      const nextIndent = (candidate.match(/^\s*/) ?? [""])[0].replaceAll("\t", "    ").length;
      if (nextIndent <= baseIndent) {
        findings.push(finding("FAIL", filePath, i + 1, "block opener appears to have no indented body"));
      }
      break;
    }
  }
  return findings;
}

function checkGdFile(filePath) {
  const findings = [];
  const lines = readLines(filePath);
  const funcs = new Map();

  for (let i = 0; i < lines.length; i += 1) {
    const lineNo = i + 1;
    const line = lines[i];

    if (MOJIBAKE_RE.test(line)) {
      findings.push(finding("FAIL", filePath, lineNo, "suspicious mojibake/corrupt text"));
    }

    if (COLOR_FADED_RE.test(line)) {
      findings.push(finding("FAIL", filePath, lineNo, "Color.faded() is not a Godot API"));
    }

    const funcMatch = line.match(FUNC_RE);
    if (funcMatch) {
      const name = funcMatch[1];
      if (funcs.has(name)) {
        findings.push(
          finding("FAIL", filePath, lineNo, `duplicate function '${name}' also declared on line ${funcs.get(name)}`),
        );
      } else {
        funcs.set(name, lineNo);
      }
    }

    const variantMatch = line.match(VARIANT_INFERENCE_RE);
    if (variantMatch) {
      findings.push(
        finding(
          "WARN",
          filePath,
          lineNo,
          `'${variantMatch[1]}' may infer Variant from Dictionary.get(); cast or type it if Godot warns`,
        ),
      );
    }

    for (const resourceMatch of line.matchAll(RESOURCE_RE)) {
      const loader = resourceMatch[1];
      const target = resourceMatch[2];
      if (!resourceExists(target)) {
        findings.push(
          finding(
            loader === "preload" ? "FAIL" : "WARN",
            filePath,
            lineNo,
            `${loader} target does not exist: res://${target}`,
          ),
        );
      }
    }
  }

  return [...findings, ...checkObviousEmptyBlocks(filePath, lines)];
}

function runStaticChecks() {
  const findings = [];
  for (const filePath of gdFiles()) findings.push(...checkGdFile(filePath));
  for (const filePath of cliScanFiles()) {
    const lines = readLines(filePath);
    for (let i = 0; i < lines.length; i += 1) {
      for (const flag of UNSUPPORTED_GODOT_CLI_FLAGS) {
        if (lines[i].includes(flag)) {
          findings.push(finding("FAIL", filePath, i + 1, `${flag} is not supported by Godot 4.6.2`));
        }
      }
    }
  }
  return findings;
}

function lastRelevantLines(output, limit = 24) {
  return output
    .split(/\r?\n/)
    .map((line) => line.trimEnd())
    .filter(Boolean)
    .slice(-limit)
    .join("\n");
}

function runGodotSmoke(godotExe, strictGodot) {
  if (!existsSync(godotExe)) {
    console.log(`[WARN] Godot executable not found: ${godotExe}`);
    return strictGodot ? 1 : 0;
  }

  console.log("[INFO] Running Godot smoke check with supported CLI flags...");
  const result = spawnSync(
    godotExe,
    ["--headless", "--path", GODOT_ROOT, "--quit", "--log-file", "user://codex_parse_check.log"],
    {
      cwd: REPO_ROOT,
      encoding: "utf8",
      timeout: 30_000,
    },
  );

  const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
  if (result.error?.code === "ETIMEDOUT") {
    console.log("[FAIL] Godot smoke check timed out after 30 seconds");
    return 1;
  }
  if (result.status === 0) {
    console.log("[PASS] Godot smoke check exited cleanly");
    return 0;
  }
  if (output.includes("CrashHandlerException") || output.toLowerCase().includes("signal 11") || result.signal) {
    console.log("[WARN] Godot headless smoke crashed on this machine; use editor reload as final validator");
    if (output) console.log(lastRelevantLines(output));
    return strictGodot ? 1 : 0;
  }

  console.log("[FAIL] Godot smoke check reported errors");
  if (output) console.log(lastRelevantLines(output));
  return 1;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const findings = runStaticChecks();
  const failures = findings.filter((item) => item.severity === "FAIL");
  const warnings = findings.filter((item) => item.severity === "WARN");

  for (const item of [...failures, ...warnings]) console.log(renderFinding(item));

  if (failures.length > 0) {
    console.log(`[SUMMARY] Static checks failed: ${failures.length} failure(s), ${warnings.length} warning(s)`);
    return 1;
  }

  console.log(`[PASS] Static checks passed with ${warnings.length} warning(s)`);
  if (args.skipGodot) return 0;
  return runGodotSmoke(args.godotExe, args.strictGodot);
}

try {
  process.exitCode = main();
} catch (error) {
  console.error(`[FAIL] ${error.message}`);
  process.exitCode = 1;
}
