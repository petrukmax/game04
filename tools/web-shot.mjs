// Headless-Chrome smoke test and screenshot for the Web export.
// Usage: node tools/web-shot.mjs <url> <out.png> [width] [height] [waitMs]
// Prints browser console errors and whether the Godot canvas started.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const CHROME = process.env.CHROME_PATH
  || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const [url, out, width = '1600', height = '900', waitMsArg = '4000', setup = ''] = process.argv.slice(2);
if (!url || !out) {
  console.error('Usage: node tools/web-shot.mjs <url> <out.png> [width] [height] [waitMs]');
  process.exit(1);
}
const waitMs = Number(waitMsArg);
const port = 9700 + Math.floor(Math.random() * 200);
const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'mars-chrome-'));
const chrome = spawn(CHROME, [
  '--headless=new', '--enable-unsafe-swiftshader', '--use-gl=angle',
  '--hide-scrollbars', '--force-device-scale-factor=1', '--mute-audio',
  '--no-first-run', '--no-default-browser-check',
  '--window-size=' + width + ',' + height,
  '--user-data-dir=' + profile,
  '--remote-debugging-port=' + port,
  'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function target() {
  for (let i = 0; i < 120; i += 1) {
    try {
      const res = await fetch('http://127.0.0.1:' + port + '/json/list');
      const list = await res.json();
      const page = list.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
      if (page) return page;
    } catch { /* retry */ }
    await sleep(120);
  }
  throw new Error('Chrome DevTools target did not appear');
}

function connect(wsUrl) {
  const socket = new WebSocket(wsUrl);
  let nextId = 1;
  const pending = new Map();
  const events = [];
  socket.addEventListener('message', (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) reject(new Error(msg.error.message));
      else resolve(msg.result);
    } else if (msg.method) {
      events.push(msg);
    }
  });
  const ready = new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  const send = async (method, params = {}) => {
    await ready;
    const id = nextId++;
    const promise = new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
    socket.send(JSON.stringify({ id, method, params }));
    return promise;
  };
  return { send, events, close: () => socket.close() };
}

try {
  const page = await target();
  const cdp = connect(page.webSocketDebuggerUrl);
  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('Log.enable');
  await cdp.send('Page.navigate', { url });

  const state = { canvas: false, overlayGone: false };
  const probe = `(() => {
    const inside = () => {
      const own = document.querySelector('canvas#canvas, canvas');
      const list = [own];
      for (const f of document.querySelectorAll('iframe')) {
        try {
          const d = f.contentDocument;
          if (d) list.push(d.querySelector('canvas'));
        } catch (err) { /* cross-origin */ }
      }
      return list.find((c) => c && c.width > 0 && c.height > 0) || null;
    };
    const c = inside();
    const overlay = document.getElementById('status');
    return {
      canvas: !!c,
      size: c ? c.width + 'x' + c.height : 'none',
      overlay: overlay ? overlay.style.visibility : 'removed',
      notice: (document.getElementById('status-notice') || {}).textContent || ''
    };
  })()`;

  async function waitForCanvas(iterations) {
    for (let i = 0; i < iterations; i += 1) {
      const r = await cdp.send('Runtime.evaluate', { expression: probe, returnByValue: true });
      const v = r?.result?.value || {};
      state.canvas = Boolean(v.canvas);
      if (v.canvas) state.overlayGone = v.overlay === 'removed' || v.overlay === 'hidden';
      if (v.notice) state.notice = v.notice;
      if (state.canvas && state.overlayGone) break;
      await sleep(500);
    }
  }

  await waitForCanvas(120);

  if (setup) {
    const result = await cdp.send('Runtime.evaluate', {
      expression: setup,
      awaitPromise: true,
      returnByValue: true,
    });
    if (result?.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
    await waitForCanvas(120);
  }
  await sleep(waitMs);
  const shot = await cdp.send('Page.captureScreenshot', {
    format: 'png',
    captureBeyondViewport: false,
    clip: { x: 0, y: 0, width: Number(width), height: Number(height), scale: 1 },
  });
  fs.writeFileSync(out, Buffer.from(shot.data, 'base64'));

  const errors = cdp.events
    .filter((e) => e.method === 'Runtime.exceptionThrown'
      || (e.method === 'Runtime.consoleAPICalled' && e.params.type === 'error')
      || (e.method === 'Log.entryAdded' && e.params.entry.level === 'error'))
    .map((e) => JSON.stringify(e.params).slice(0, 400));

  console.log('canvas:', state.canvas, 'overlayGone:', state.overlayGone, 'notice:', state.notice || '-');
  const metrics = await cdp.send('Runtime.evaluate', {
    expression: `(() => {
      const c = document.querySelector('canvas');
      return {
        viewport: window.innerWidth + 'x' + window.innerHeight,
        dpr: window.devicePixelRatio,
        canvasPx: c ? c.width + 'x' + c.height : 'none',
        canvasCss: c ? Math.round(c.getBoundingClientRect().width) + 'x' + Math.round(c.getBoundingClientRect().height) : 'none'
      };
    })()`,
    returnByValue: true,
  });
  console.log('metrics:', JSON.stringify(metrics?.result?.value));
  console.log('console errors:', errors.length);
  errors.slice(0, 10).forEach((line) => console.log('  !', line));
  console.log('saved:', out);
  cdp.close();
  if (!state.canvas) process.exitCode = 2;
} catch (error) {
  console.error(error);
  process.exitCode = 1;
} finally {
  chrome.kill();
  await sleep(300);
  fs.rmSync(profile, { recursive: true, force: true });
}
