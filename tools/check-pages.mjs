// Static GitHub Pages readiness check for Mars Arachnid Defense.
// Usage: node tools/check-pages.mjs
// Verifies the files Pages must serve, exact filename case, relative paths and
// the practical GitHub upload limits. No browser or network required.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const warnings = [];

function fail(message) { failures.push(message); }
function warn(message) { warnings.push(message); }

function stat(rel) {
  const file = path.join(ROOT, rel);
  return fs.existsSync(file) ? fs.statSync(file) : null;
}

// Windows is case-insensitive, GitHub Pages is not: walk each segment and
// require an exact-case match.
function exactFile(rel) {
  let current = ROOT;
  for (const part of rel.split(/[\\/]/)) {
    if (part === '' || part === '.') continue;
    let entries;
    try { entries = fs.readdirSync(current); } catch { return false; }
    if (!entries.includes(part)) return false;
    current = path.join(current, part);
  }
  try { return fs.statSync(current).isFile(); } catch { return false; }
}

function refsFrom(html) {
  const refs = new Set();
  for (const match of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
    const ref = match[1];
    if (/^(data:|https?:|#|mailto:)/.test(ref)) continue;
    refs.add(ref.split('?')[0].split('#')[0]);
  }
  return [...refs];
}

function checkRefs(htmlPath) {
  const abs = path.join(ROOT, htmlPath);
  if (!fs.existsSync(abs)) {
    fail(`Missing ${htmlPath}`);
    return;
  }
  const base = path.dirname(htmlPath);
  for (const ref of refsFrom(fs.readFileSync(abs, 'utf8'))) {
    const rel = path.posix.normalize(path.posix.join(base.split(path.sep).join('/'), ref));
    if (exactFile(rel)) {
      console.log(`  OK   ${htmlPath} -> ${ref}`);
    } else {
      fail(`${htmlPath} references a missing/mis-cased file: ${ref}`);
    }
  }
}

console.log('Required files');
const required = [
  'index.html',
  '.nojekyll',
  '.gitignore',
  'web/index.html',
  'web/index.js',
  'web/index.wasm',
  'web/index.pck',
  'web/index.icon.png',
  'web/index.png',
  'web/index.audio.worklet.js',
  'web/index.audio.position.worklet.js',
];
for (const rel of required) {
  if (exactFile(rel)) console.log(`  OK   ${rel}`);
  else fail(`Missing required file: ${rel}`);
}

console.log('Sizes and GitHub limits');
const wasm = stat('web/index.wasm');
const pck = stat('web/index.pck');
if (wasm) {
  const mb = wasm.size / 1024 / 1024;
  console.log(`  INFO web/index.wasm ${mb.toFixed(2)} MB`);
  if (wasm.size > 100 * 1024 * 1024) {
    fail('index.wasm exceeds GitHub\'s 100 MB per-file hard limit.');
  } else if (wasm.size > 25 * 1024 * 1024) {
    warn('index.wasm is over 25 MB: GitHub\'s browser uploader will reject it. Use git or GitHub Desktop.');
  }
  if (wasm.size < 1024 * 1024) fail('index.wasm looks truncated.');
}
if (pck) {
  console.log(`  INFO web/index.pck ${(pck.size / 1024).toFixed(1)} KB`);
  if (pck.size < 1024) fail('index.pck looks truncated.');
}

console.log('Relative paths and filename case');
for (const doc of ['index.html', path.join('web', 'index.html')]) checkRefs(doc);

const webIndexPath = path.join(ROOT, 'web', 'index.html');
if (!fs.existsSync(webIndexPath)) {
  fail('Missing web/index.html; cannot confirm the export mode.');
} else {
  const webIndex = fs.readFileSync(webIndexPath, 'utf8');
  if (/const GODOT_THREADS_ENABLED = false;/.test(webIndex)) {
    console.log('  OK   single-threaded export (no COOP/COEP needed)');
  } else {
    fail('Threaded export detected: GitHub Pages would need COOP/COEP headers.');
  }
}

console.log('GitHub Pages control files');
if (fs.existsSync(path.join(ROOT, '.nojekyll'))) {
  console.log('  OK   .nojekyll present');
} else {
  fail('.nojekyll is missing: Jekyll would process the site.');
}
const ignore = fs.existsSync(path.join(ROOT, '.gitignore'))
  ? fs.readFileSync(path.join(ROOT, '.gitignore'), 'utf8') : '';
for (const rule of ['.godot/', '*.log']) {
  if (ignore.includes(rule)) console.log(`  OK   .gitignore keeps ${rule}`);
  else fail(`.gitignore does not ignore ${rule}`);
}
for (const rel of ['web/index.wasm', 'web/index.pck', '.nojekyll']) {
  if (ignore.split(/\r?\n/).some((line) => line.trim() === rel)) {
    fail(`.gitignore would exclude deployable file: ${rel}`);
  }
}

console.log('Root layout');
if (!exactFile('index.html')) {
  fail('The repository root must contain index.html. Do not publish the parent Opencode folder.');
} else {
  console.log('  OK   index.html is at the repository root');
}

console.log('');
for (const message of warnings) console.log('WARN', message);
if (failures.length) {
  for (const message of failures) console.log('FAIL', message);
  console.log(`\nPages readiness: FAIL (${failures.length} problem(s))`);
  process.exit(1);
}
console.log('Pages readiness: PASS — the folder can be published from its root.');
