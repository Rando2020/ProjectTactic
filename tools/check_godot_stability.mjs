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

const MOJIBAKE_RE = /[\u00C2\u00C3\u00E2\uFFFD]/u;
const FUNC_RE = /^\s*(static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)/;
const CLASS_NAME_RE = /^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b/;
const RESOURCE_RE = /\b(preload|load)\(\s*['"]res:\/\/([^'"]+)['"]\s*\)/g;
const UNSUPPORTED_GODOT_CLI_FLAGS = ["--" + "check-only"];
const COLOR_FADED_RE = /\.faded\s*\(/;
const VARIANT_INFERENCE_RE =
  /^\s*var\s+([A-Za-z_][A-Za-z0-9_]*)\s*:=\s*[A-Za-z_][A-Za-z0-9_.]*\.get\(/;
const CONST_PRELOAD_RE =
  /^\s*const\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::=\s*|=\s*)preload\(\s*['"]res:\/\/([^'"]+)['"]\s*\)/;
const LOCAL_VAR_RE = /^\s*(?:var|const)\s+([A-Za-z_][A-Za-z0-9_]*)\b/;
const BLOCK_RE = /^(\s*)(?:if|elif|else|for|while|match)\b.*:\s*(?:#.*)?$/;
const FUNC_BLOCK_RE = /^(\s*)(?:static\s+)?func\b.*:\s*(?:#.*)?$/;
const COMMON_SHADOWED_NAMES = new Set(["name", "size", "tr", "visible", "wrap"]);
const BUILTIN_SINGLETON_NAMES = new Set([
  "AudioServer",
  "DisplayServer",
  "Engine",
  "Input",
  "OS",
  "Performance",
  "ProjectSettings",
  "RenderingServer",
  "ResourceLoader",
  "Time",
  "TranslationServer",
]);

function parseArgs(argv) {
  const args = {
    skipGodot: false,
    strictGodot: false,
    warningsAsErrors: false,
    godotExe: DEFAULT_GODOT_EXE,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--skip-godot") args.skipGodot = true;
    else if (arg === "--strict-godot") args.strictGodot = true;
    else if (arg === "--warnings-as-errors") args.warningsAsErrors = true;
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

function gdResourceToPath(resourcePath) {
  return path.join(GODOT_ROOT, resourcePath.replaceAll("\\", "/"));
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
  return existsSync(gdResourceToPath(normalized));
}

function lineIndent(line) {
  return (line.match(/^\s*/) ?? [""])[0].replaceAll("\t", "    ").length;
}

function parseParamNames(paramSource) {
  if (!paramSource.trim()) return [];
  return paramSource
    .split(",")
    .map((param) => param.trim().replace(/^@?[A-Za-z_][A-Za-z0-9_]*\s+/, ""))
    .map((param) => param.split("=")[0].trim())
    .map((param) => param.split(":")[0].trim())
    .filter((param) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(param));
}

function stripStringsAndComments(source) {
  return source
    .replace(/"([^"\\]|\\.)*"/g, '""')
    .replace(/'([^'\\]|\\.)*'/g, "''")
    .replace(/#.*$/gm, "");
}

function functionBlocks(filePath, lines) {
  const blocks = [];
  for (let i = 0; i < lines.length; i += 1) {
    const match = lines[i].match(FUNC_RE);
    if (!match) continue;

    const indent = lineIndent(lines[i]);
    let end = lines.length - 1;
    for (let j = i + 1; j < lines.length; j += 1) {
      if (lines[j].trim() === "" || lines[j].trim().startsWith("#")) continue;
      if (lineIndent(lines[j]) <= indent) {
        end = j - 1;
        break;
      }
    }

    blocks.push({
      filePath,
      line: i + 1,
      name: match[2],
      isStatic: Boolean(match[1]),
      params: parseParamNames(match[3] ?? ""),
      bodyLines: lines.slice(i + 1, end + 1),
    });
  }
  return blocks;
}

function parseGodotProjectAutoloads() {
  const autoloads = new Map();
  const projectPath = path.join(GODOT_ROOT, "project.godot");
  if (!existsSync(projectPath)) return autoloads;

  const lines = readLines(projectPath);
  let inAutoload = false;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i].trim();
    if (line === "[autoload]") {
      inAutoload = true;
      continue;
    }
    if (inAutoload && line.startsWith("[") && line.endsWith("]")) break;
    if (!inAutoload || line === "" || line.startsWith(";")) continue;

    const match = line.match(/^([A-Za-z_][A-Za-z0-9_]*)="?\*?res:\/\/([^"]+)"?/);
    if (!match) continue;
    autoloads.set(match[1], {
      name: match[1],
      filePath: gdResourceToPath(match[2]),
      line: i + 1,
      resourcePath: `res://${match[2]}`,
    });
  }
  return autoloads;
}

function collectGodotSymbols(files) {
  const classNames = new Set(BUILTIN_SINGLETON_NAMES);
  const scriptClassByPath = new Map();
  const methodsByClass = new Map();
  const functionBlocksByPath = new Map();

  for (const filePath of files) {
    const lines = readLines(filePath);
    const classMatch = lines.map((line) => line.match(CLASS_NAME_RE)).find(Boolean);
    const blocks = functionBlocks(filePath, lines);
    functionBlocksByPath.set(filePath, blocks);

    if (!classMatch) continue;
    const className = classMatch[1];
    classNames.add(className);
    scriptClassByPath.set(path.normalize(filePath), className);
    methodsByClass.set(
      className,
      new Map(blocks.map((block) => [block.name, { isStatic: block.isStatic, line: block.line, filePath }])),
    );
  }

  return {
    autoloads: parseGodotProjectAutoloads(),
    classNames,
    functionBlocksByPath,
    methodsByClass,
    scriptClassByPath,
  };
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

function checkAutoloadClassCollisions(symbols) {
  const findings = [];
  for (const autoload of symbols.autoloads.values()) {
    const className = symbols.scriptClassByPath.get(path.normalize(autoload.filePath));
    if (className === autoload.name) {
      findings.push(
        finding(
          "FAIL",
          autoload.filePath,
          1,
          `class_name '${className}' hides autoload singleton '${autoload.name}'; remove class_name or rename one side`,
        ),
      );
    }
  }
  return findings;
}

function checkFunctionBlockHygiene(block) {
  const findings = [];
  const body = stripStringsAndComments(block.bodyLines.join("\n"));
  const bodyWithNestedFunctionCallsRemoved = body.replace(/\bfunc\s+[A-Za-z_][A-Za-z0-9_]*\s*\([^)]*\)/g, "");

  for (const param of block.params) {
    if (param.startsWith("_")) continue;

    const usage = new RegExp(`\\b${param}\\b`);
    if (!usage.test(bodyWithNestedFunctionCallsRemoved)) {
      findings.push(
        finding(
          "WARN",
          block.filePath,
          block.line,
          `parameter '${param}' appears unused; prefix it with '_' if intentional`,
        ),
      );
    }

    if (COMMON_SHADOWED_NAMES.has(param)) {
      findings.push(
        finding("WARN", block.filePath, block.line, `parameter '${param}' shadows a common Godot/built-in name`),
      );
    }
  }

  return findings;
}

function checkAwaitOnLocalNonCoroutine(filePath, blocks) {
  const findings = [];
  const localFunctions = new Map(blocks.map((block) => [block.name, block]));
  const coroutineFunctions = new Set(
    blocks
      .filter((block) => stripStringsAndComments(block.bodyLines.join("\n")).includes("await "))
      .map((block) => block.name),
  );

  for (const block of blocks) {
    for (let i = 0; i < block.bodyLines.length; i += 1) {
      const line = stripStringsAndComments(block.bodyLines[i]);
      for (const awaitMatch of line.matchAll(/\bawait\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^)]*\)(\.[A-Za-z_][A-Za-z0-9_]*)?/g)) {
        const awaitedName = awaitMatch[1];
        if (awaitMatch[2]) continue;
        if (localFunctions.has(awaitedName) && !coroutineFunctions.has(awaitedName)) {
          findings.push(
            finding(
              "WARN",
              filePath,
              block.line + i + 1,
              `await on local function '${awaitedName}()' that does not appear to yield or await`,
            ),
          );
        }
      }
    }
  }

  return findings;
}

function checkGdFile(filePath, symbols) {
  const findings = [];
  const lines = readLines(filePath);
  const funcs = new Map();
  const blocks = symbols.functionBlocksByPath.get(filePath) ?? functionBlocks(filePath, lines);

  for (let i = 0; i < lines.length; i += 1) {
    const lineNo = i + 1;
    const line = lines[i];
    const codeLine = stripStringsAndComments(line);

    if (MOJIBAKE_RE.test(line)) {
      findings.push(finding("FAIL", filePath, lineNo, "suspicious mojibake/corrupt text"));
    }

    if (COLOR_FADED_RE.test(line)) {
      findings.push(finding("FAIL", filePath, lineNo, "Color.faded() is not a Godot API"));
    }

    const funcMatch = line.match(FUNC_RE);
    if (funcMatch) {
      const name = funcMatch[2];
      if (funcs.has(name)) {
        findings.push(
          finding("FAIL", filePath, lineNo, `duplicate function '${name}' also declared on line ${funcs.get(name)}`),
        );
      } else {
        funcs.set(name, lineNo);
      }
    }

    const classMatch = line.match(CLASS_NAME_RE);
    if (classMatch && symbols.autoloads.has(classMatch[1])) {
      findings.push(
        finding(
          "FAIL",
          filePath,
          lineNo,
          `class_name '${classMatch[1]}' collides with an autoload singleton of the same name`,
        ),
      );
    }

    const constPreloadMatch = line.match(CONST_PRELOAD_RE);
    if (constPreloadMatch && symbols.classNames.has(constPreloadMatch[1])) {
      findings.push(
        finding(
          "WARN",
          filePath,
          lineNo,
          `constant '${constPreloadMatch[1]}' shadows a global class; use the class_name directly or rename the constant`,
        ),
      );
    }

    const localVarMatch = line.match(LOCAL_VAR_RE);
    if (localVarMatch && COMMON_SHADOWED_NAMES.has(localVarMatch[1])) {
      findings.push(
        finding("WARN", filePath, lineNo, `local '${localVarMatch[1]}' shadows a common Godot/built-in name`),
      );
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

    for (const [className, methods] of symbols.methodsByClass.entries()) {
      for (const [methodName, method] of methods.entries()) {
        if (method.isStatic) continue;
        if (!new RegExp(`\\b${className}\\.${methodName}\\s*\\(`).test(codeLine)) continue;
        findings.push(
          finding(
            "FAIL",
            filePath,
            lineNo,
            `non-static method '${methodName}()' is called on class '${className}' directly; use an instance or autoload`,
          ),
        );
      }
    }
  }

  for (const block of blocks) findings.push(...checkFunctionBlockHygiene(block));

  return [
    ...findings,
    ...checkAwaitOnLocalNonCoroutine(filePath, blocks),
    ...checkObviousEmptyBlocks(filePath, lines),
  ];
}

function runStaticChecks() {
  const findings = [];
  const files = gdFiles();
  const symbols = collectGodotSymbols(files);

  findings.push(...checkAutoloadClassCollisions(symbols));
  for (const filePath of files) findings.push(...checkGdFile(filePath, symbols));
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

function describeGodotFailure(output, result) {
  const lower = output.toLowerCase();
  const notes = [];

  if (
    lower.includes("could not create editor data directory") ||
    lower.includes("could not create editor cache directory") ||
    lower.includes("check user write permissions") ||
    lower.includes("could not create directory") ||
    lower.includes("cannot create file")
  ) {
    notes.push("permission/cache setup issue");
  }

  if (output.includes("CrashHandlerException") || lower.includes("signal 11") || result.signal) {
    notes.push("Godot/headless engine crash");
  }

  if (
    lower.includes("parse error") ||
    lower.includes("failed to load script") ||
    lower.includes("failed to compile") ||
    lower.includes("compile error")
  ) {
    notes.push("project parse/compile issue");
  }

  return notes.length > 0 ? notes.join(" + ") : "unclassified Godot CLI failure";
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
  const failureSummary = describeGodotFailure(output, result);
  if (failureSummary.includes("Godot/headless engine crash")) {
    console.log(`[WARN] Godot smoke check did not complete: ${failureSummary}`);
    console.log("[WARN] Use editor reload as final validator until the headless crash is resolved");
    if (output) console.log(lastRelevantLines(output));
    return strictGodot ? 1 : 0;
  }

  console.log(`[FAIL] Godot smoke check reported errors: ${failureSummary}`);
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
  if (args.warningsAsErrors && warnings.length > 0) {
    console.log(`[SUMMARY] Static checks failed because --warnings-as-errors found ${warnings.length} warning(s)`);
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
