// 書き出した Web 版を実際の Chrome（スマホ相当の画面）で開き、画面に何が描かれているかを調べる。
// 使い方: node browser_test.mjs <build/web のフォルダ>
// 失敗したら終了コード 1。ブラウザのコンソール出力（Godot の print / エラー）も全部表示する。
import { chromium, webkit } from 'playwright-core';
import { PNG } from 'pngjs';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2]);
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (p === '/') p = '/index.html';
  const file = path.join(root, path.normalize(p).replace(/^(\.\.[/\\])+/, ''));
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/index.html`;

// BROWSER=webkit で Safari と同じ系統のエンジン（WebKit）でも調べる。タッチのドラッグ（CDP）は Chrome のみ
const useWebkit = process.env.BROWSER === 'webkit';
const browser = useWebkit
  ? await webkit.launch({ headless: true })
  : await chromium.launch({
      executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome',
      headless: true,
      args: ['--no-sandbox', '--use-angle=swiftshader', '--use-gl=angle', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl'],
    });
console.log(`browser: ${useWebkit ? 'webkit' : 'chrome'}`);
const context = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
const page = await context.newPage();
const logs = [];
page.on('console', (m) => logs.push(`[${m.type()}] ${m.text()}`));
page.on('pageerror', (e) => logs.push(`[pageerror] ${e.message}`));

const failures = [];
function check(ok, message) {
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${message}`);
  if (!ok) failures.push(message);
}

// 画面の色を数える: 明るい画素（文字）、青（A）、橙（B）、暗い覆いの割合
function analyze(png) {
  const { width, height, data } = png;
  let bright = 0, blue = 0, orange = 0, sbx = 0, sby = 0, sox = 0, soy = 0;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      const r = data[i], g = data[i + 1], b = data[i + 2];
      if (r + g + b > 600) bright++;
      if (b > 200 && r < 120 && g > 110 && g < 200) { blue++; sbx += x; sby += y; }
      if (r > 200 && g > 110 && g < 190 && b < 100) { orange++; sox += x; soy += y; }
    }
  }
  return {
    width, height, bright, blue, orange,
    blueC: blue ? [Math.round(sbx / blue), Math.round(sby / blue)] : null,
    orangeC: orange ? [Math.round(sox / orange), Math.round(soy / orange)] : null,
    center: [...data.slice(((height >> 1) * width + (width >> 1)) * 4, ((height >> 1) * width + (width >> 1)) * 4 + 3)],
  };
}
async function shot(name) {
  const buf = await page.screenshot();
  fs.writeFileSync(`${useWebkit ? 'webkit-' : 'chrome-'}${name}.png`, buf);
  const a = analyze(PNG.sync.read(buf));
  console.log(`-- ${name}: ${JSON.stringify(a)}`);
  return a;
}

try {
  await page.goto(url);
  // 読み込みが終わって何かが描かれるまで最大 40 秒待つ
  let title = null;
  for (let t = 0; t < 20; t++) {
    await page.waitForTimeout(2000);
    title = await shot('title');
    if (title.bright > 500) break;
  }
  check(title.bright > 500, `title screen draws bright text (bright pixels: ${title.bright})`);

  // Enter で START（先頭のボタンにフォーカスがある）
  await page.keyboard.press('Enter');
  await page.waitForTimeout(2500);
  const game = await shot('game');
  check(game.blue > 200, `blue character A is drawn (blue pixels: ${game.blue})`);
  check(game.orange > 200, `orange character B is drawn (orange pixels: ${game.orange})`);

  // 左半分を左へドラッグ → A が B から離れる（ハブへ引き戻されながら）
  if (useWebkit) throw new Error('__skip_drag__');
  const cdp = await context.newCDPSession(page);
  const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points });
  await touch('touchStart', [{ x: 150, y: 600, id: 0 }]);
  for (let i = 1; i <= 10; i++) {
    await touch('touchMove', [{ x: 150 - i * 10, y: 600, id: 0 }]);
    await page.waitForTimeout(40);
  }
  await page.waitForTimeout(1200);
  const during = await shot('dragging');
  await touch('touchEnd', []);
  if (game.blueC && game.orangeC && during.blueC && during.orangeC) {
    const before = game.blueC[0] - game.orangeC[0];
    const after = during.blueC[0] - during.orangeC[0];
    check(after < before - 20, `dragging the left half moves A away from B (x gap ${before} -> ${after})`);
  } else {
    check(false, 'could not locate both characters to measure the drag');
  }
} catch (e) {
  if (e.message !== '__skip_drag__') check(false, `exception: ${e.message}`);
}

console.log('==== browser console ====');
for (const line of logs.slice(0, 160)) console.log(line);
await browser.close();
server.close();
process.exit(failures.length ? 1 : 0);
