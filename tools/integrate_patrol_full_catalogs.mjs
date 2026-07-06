import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

const repoRoot = process.cwd();
const sourceRoot = "/Users/shrybnhshymbnmrzwqbnhwyd/Documents/Codex/2026-07-02/new-chat-2/outputs/كتلوجات الباترول الشامله";
const manifestPath = path.join(repoRoot, "data/patrol_catalog_manifest.json");
const iosWebRoot = path.join(repoRoot, "ios/BatalAlDroob/BatalAlDroob/Web");
const targetRoot = path.join(iosWebRoot, "catalog/patrol_full_unique");
const targetDataPath = path.join(iosWebRoot, "data/patrol_full_catalog_files.json");

const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const uniqueFiles = manifest.files.filter((file) => !file.duplicate_of);
const seenHashes = new Set();
const copied = [];
const skippedDuplicates = [];

function safeSegment(value, fallback) {
  const text = String(value || fallback).trim();
  return text
    .replace(/[\\/:*?"<>|]/g, "_")
    .replace(/\s+/g, "_")
    .replace(/_+/g, "_");
}

for (const file of uniqueFiles) {
  if (seenHashes.has(file.sha256)) {
    skippedDuplicates.push({
      id: file.id,
      duplicate_of_sha256: file.sha256,
      relative_path: file.relative_path
    });
    continue;
  }

  const generation = safeSegment(file.generation, "unknown");
  const year = safeSegment(file.years?.[0], "unknown");
  const source = path.join(sourceRoot, file.relative_path);
  const fileName = `${file.id}__${safeSegment(file.file_name, "catalog.pdf")}`;
  const targetRelativePath = path.join("catalog/patrol_full_unique", generation, year, fileName);
  const target = path.join(iosWebRoot, targetRelativePath);

  if (!existsSync(source)) {
    throw new Error(`Missing source file: ${source}`);
  }

  mkdirSync(path.dirname(target), { recursive: true });
  if (!existsSync(target)) {
    copyFileSync(source, target);
  }

  seenHashes.add(file.sha256);
  copied.push({
    ...file,
    app_path: targetRelativePath,
    sorted_generation: generation,
    sorted_year: year
  });
}

const output = {
  generated_at: new Date().toISOString(),
  source_root: sourceRoot,
  target_root: "catalog/patrol_full_unique",
  total_manifest_files: manifest.files.length,
  unique_files_integrated: copied.length,
  skipped_duplicate_hashes: skippedDuplicates.length,
  summary: manifest.summary,
  files: copied,
  skipped_duplicates: skippedDuplicates
};

mkdirSync(path.dirname(targetDataPath), { recursive: true });
writeFileSync(targetDataPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");

console.log(JSON.stringify({
  unique_files_integrated: copied.length,
  skipped_duplicate_hashes: skippedDuplicates.length,
  target_root: output.target_root,
  index: path.relative(repoRoot, targetDataPath)
}, null, 2));
