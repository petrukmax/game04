// Minimal local static server for testing the Web export.
// Usage: node tools/serve.mjs [port] [root] [--open]
// Serves the repository root (or a custom root) so both the landing page and
// web/ build work. Pass the parent folder to test a /<repo>/ sub-path.
// --open launches the default browser once the server is listening.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const PROJECT_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const CLI_ARGS = process.argv.slice(2);
const OPEN = CLI_ARGS.includes('--open');
const POSITIONAL = CLI_ARGS.filter((arg) => !arg.startsWith('--'));
const PORT = Number(POSITIONAL[0] || 8787);
const ROOT = path.resolve(POSITIONAL[1] || PROJECT_ROOT);
const MAX_PORT_ATTEMPTS = 20;


const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wav': 'audio/wav',
  '.md': 'text/markdown; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
};

function serveFile(req, res) {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);
  let filePath = path.join(ROOT, url === '/' ? 'index.html' : url);
  const relative = path.relative(ROOT, path.resolve(filePath));
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    res.writeHead(403).end('Forbidden');
    return;
  }
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end('Not found: ' + url);
      return;
    }
    res.writeHead(200, {
      'Content-Type': MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-cache',
      // Harmless for the single-threaded build and required if a threaded
      // export is substituted later.
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Resource-Policy': 'cross-origin',
    });
    res.end(data);
  });
}

function openBrowser(url) {
  const command = process.platform === 'win32'
    ? 'cmd'
    : process.platform === 'darwin' ? 'open' : 'xdg-open';
  const args = process.platform === 'win32'
    ? ['/c', 'start', '', url]
    : [url];
  try {
    spawn(command, args, { stdio: 'ignore', detached: true }).unref();
  } catch (error) {
    console.warn('Could not open the browser automatically:', error.message);
  }
}

// If the requested port belongs to another program, move to the next free one
// instead of silently showing a different project. This is common on machines
// where an old dev server is still running.
function startServer(port, attempt = 0) {
  const server = http.createServer(serveFile);
  server.once('error', (error) => {
    if (error.code === 'EADDRINUSE' && attempt < MAX_PORT_ATTEMPTS) {
      console.warn(`Port ${port} is already in use; trying ${port + 1}...`);
      startServer(port + 1, attempt + 1);
      return;
    }
    console.error(`Cannot start the server on port ${port}: ${error.message}`);
    process.exit(1);
  });
  server.listen(port, '127.0.0.1', () => {
    const url = `http://127.0.0.1:${port}/`;
    console.log('Mars Arachnid Defense - local server');
    console.log(`  Launcher:  ${url}`);
    console.log(`  Web build: ${url}web/index.html`);
    if (port !== PORT) {
      console.log(`  Note: port ${PORT} was busy, using ${port} instead.`);
    }
    if (OPEN) openBrowser(url);
  });
}

startServer(PORT);

