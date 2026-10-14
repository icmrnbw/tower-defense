// Render SVGs to transparent PNGs with headless Chromium.
// Usage: node render.mjs <size> <out.png> <in.svg> [<out.png> <in.svg> ...]
import { createRequire } from 'module';
const { chromium } = createRequire(import.meta.url)(process.env.PLAYWRIGHT_MODULE || 'playwright');
import { readFileSync } from 'fs';

const [size, ...pairs] = process.argv.slice(2);
const px = Number(size);
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: px, height: px } });
for (let i = 0; i < pairs.length; i += 2) {
  const svg = readFileSync(pairs[i + 1], 'utf8')
    .replace(/width="512" height="512"/, `width="${px}" height="${px}"`);
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
  await page.screenshot({ path: pairs[i], omitBackground: true, clip: { x: 0, y: 0, width: px, height: px } });
}
await browser.close();
