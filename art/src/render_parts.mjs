// Render SVG files to transparent PNGs. Usage: node render_parts.mjs jobs.json
// jobs.json: [{"svg": path, "png": path, "w": px, "h": px}, ...]
import { createRequire } from 'module';
const { chromium } = createRequire(import.meta.url)(process.env.PLAYWRIGHT_MODULE || 'playwright');
import { readFileSync } from 'fs';

const jobs = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 64, height: 64 } });
for (const j of jobs) {
  await page.setViewportSize({ width: j.w, height: j.h });
  await page.setContent(`<html><body style="margin:0;background:transparent">${readFileSync(j.svg, 'utf8')}</body></html>`);
  await page.screenshot({ path: j.png, omitBackground: true, clip: { x: 0, y: 0, width: j.w, height: j.h } });
}
await browser.close();
