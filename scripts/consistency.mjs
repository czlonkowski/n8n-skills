import assert from "node:assert/strict";
import { mkdtemp, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const retired = ["get_node_essentials", "get_node_info"];
const ignoredDirectories = new Set([".git", "node_modules"]);

const scanRetired = (text) =>
  text
    .split(/\r?\n/)
    .flatMap((line, index) =>
      retired.filter((name) => line.includes(name)).map((name) => ({ line: index + 1, name })),
    );

async function walk(directory, extensions) {
  const files = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory() && !ignoredDirectories.has(entry.name))
      files.push(...(await walk(path, extensions)));
    else if (extensions.has(entry.name.slice(entry.name.lastIndexOf(".")))) files.push(path);
  }
  return files;
}

const sameMembers = (left, right) =>
  left.length === right.length && [...left].sort().every((value, index) => value === [...right].sort()[index]);

async function selfTest() {
  const directory = await mkdtemp(join(tmpdir(), "n8n-f017-"));
  const fixture = join(directory, "canary.md");
  try {
    await writeFile(fixture, "use get_node\nF017_CANARY_get_node_essentials\nthen get_node_info\n", "utf8");
    const hits = scanRetired(await readFile(fixture, "utf8"));
    assert.deepEqual(hits, [
      { line: 2, name: "get_node_essentials" },
      { line: 3, name: "get_node_info" },
    ]);
    assert.deepEqual(scanRetired("use get_node only\n"), []);
    assert.deepEqual(scanRetired(JSON.stringify(JSON.parse('{"call":"get_node_\\u0069nfo"}'))), [
      { line: 1, name: "get_node_info" },
    ]);
  } finally {
    if (!basename(directory).startsWith("n8n-f017-")) throw new Error(`unsafe self-test path: ${directory}`);
    await rm(directory, { recursive: true, force: true });
  }
  console.log("F017_SELF_TEST_OK red=3 green=1");
}

await selfTest();
if (process.argv.includes("--self-test")) process.exit(0);

const errors = [];
const plugin = JSON.parse(await readFile(join(root, ".claude-plugin", "plugin.json"), "utf8"));
const marketplace = JSON.parse(await readFile(join(root, ".claude-plugin", "marketplace.json"), "utf8"));
const marketPlugin = marketplace.plugins?.find((entry) => entry.name === plugin.name);
const build = await readFile(join(root, "build.sh"), "utf8");
const buildVersion = build.match(/^VERSION="([^"]+)"/m)?.[1];

if (typeof plugin.version !== "string" || !plugin.version) errors.push("plugin.json requires a version");
if (!marketPlugin) errors.push(`marketplace is missing plugin ${plugin.name}`);
if (marketPlugin?.version !== plugin.version)
  errors.push(`marketplace version ${marketPlugin?.version ?? "missing"} != plugin version ${plugin.version}`);
if (buildVersion !== plugin.version)
  errors.push(`build.sh version ${buildVersion ?? "missing"} != plugin version ${plugin.version}`);

const skillRoot = join(root, "skills");
const skillNames = [];
for (const entry of await readdir(skillRoot, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  try {
    if ((await stat(join(skillRoot, entry.name, "SKILL.md"))).isFile()) skillNames.push(entry.name);
  } catch {
    errors.push(`skills/${entry.name} is missing SKILL.md`);
  }
}

const marketplaceSkills = Array.isArray(marketPlugin?.skills)
  ? marketPlugin.skills.map((path) => path.replace(/^\.\/skills\//, ""))
  : [];
if (!Array.isArray(marketPlugin?.skills)) errors.push("marketplace plugin requires skills[]");
if (!sameMembers(skillNames, marketplaceSkills))
  errors.push(`marketplace skills differ from tree: tree=[${skillNames.sort()}] marketplace=[${marketplaceSkills.sort()}]`);

const buildBlock = build.match(/SKILLS=\(([^]*?)\n\)/)?.[1] ?? "";
const buildSkills = [...buildBlock.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
if (!sameMembers(skillNames, buildSkills))
  errors.push(`build.sh skills differ from tree: tree=[${skillNames.sort()}] build=[${buildSkills.sort()}]`);

const evalFiles = await walk(join(root, "evaluations"), new Set([".json"]));
for (const path of evalFiles) {
  const relative = path.slice(root.length).replaceAll("\\", "/");
  let evaluation;
  try {
    evaluation = JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    errors.push(`${relative}: invalid JSON (${error.message})`);
    continue;
  }
  if (typeof evaluation.id !== "string" || !evaluation.id) errors.push(`${relative}: non-empty id required`);
  if (typeof evaluation.query !== "string" || !evaluation.query.trim()) errors.push(`${relative}: non-empty query required`);
  if (!Array.isArray(evaluation.expected_behavior) || evaluation.expected_behavior.length === 0)
    errors.push(`${relative}: non-empty expected_behavior[] required`);
  const references = evaluation.skills ?? (evaluation.skill ? [evaluation.skill] : []);
  if (!Array.isArray(references) || references.length === 0) errors.push(`${relative}: skill or skills[] required`);
  else {
    for (const reference of references) {
      if (!skillNames.includes(reference)) errors.push(`${relative}: unknown skill ${reference}`);
    }
  }
  for (const hit of scanRetired(JSON.stringify(evaluation)))
    errors.push(`${relative}:${hit.line}: retired tool ${hit.name}`);
}

for (const path of await walk(root, new Set([".md"]))) {
  const relative = path.slice(root.length).replaceAll("\\", "/");
  for (const hit of scanRetired(await readFile(path, "utf8")))
    errors.push(`${relative}:${hit.line}: retired tool ${hit.name}`);
}

if (errors.length > 0) {
  console.error(errors.join("\n"));
  console.error(`F017_CONSISTENCY_RED errors=${errors.length} skills=${skillNames.length} evals=${evalFiles.length}`);
  process.exit(1);
}

console.log(`F017_CONSISTENCY_GREEN version=${plugin.version} skills=${skillNames.length} evals=${evalFiles.length}`);
