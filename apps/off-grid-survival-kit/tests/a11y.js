// axe-core accessibility audit (WCAG 2.0/2.1 A + AA rules) of every page in the Night, Day and Red themes.
// Run from the app folder with the app served on :8765:  npm i axe-core && node tests/a11y.js [dark,day,red]
const { chromium } = require('playwright');
const fs = require('fs');
const AXE = fs.readFileSync(process.env.AXE_PATH || require.resolve('axe-core/axe.min.js', { paths: [process.cwd(), __dirname] }), 'utf8');
const PAGES = (process.env.PAGES || 'index.html,map/index.html,compass/index.html,plan/index.html,search/index.html?q=bleeding,tools/index.html,water/index.html,firstaid/index.html,fireshelter/index.html,foraging/index.html,food/index.html,electricity/index.html,emergency/index.html').split(',');
const themes = (process.argv[2] || 'dark,day,red').split(',');
(async () => {
  const b = await chromium.launch();
  let total = 0;
  for (const theme of themes) {
    const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, serviceWorkers: 'block' });
    await ctx.addInitScript(t => { try { localStorage.setItem('ogsk.theme', t); } catch (e) {} }, theme);
    const p = await ctx.newPage();
    for (const pg of PAGES) {
      await p.goto('http://127.0.0.1:8765/' + pg); await p.waitForTimeout(pg.startsWith('map') ? 2500 : 700);
      await p.evaluate(() => document.querySelectorAll('details').forEach(d => d.open = true));
      await p.addScriptTag({ content: AXE });
      const r = await p.evaluate(async () => {
        const res = await axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'] }, resultTypes: ['violations'] });
        return res.violations.map(v => ({ id: v.id, impact: v.impact, n: v.nodes.length, help: v.help, eg: v.nodes.slice(0, 3).map(n => n.target.join(' ') + ' :: ' + (n.failureSummary || '').split('\n').slice(1, 2).join(' ').slice(0, 140)) }));
      });
      total += r.length;
      console.log(`[${theme}] ${pg}: ${r.length ? r.map(v => `${v.id}(${v.impact},${v.n})`).join(', ') : 'OK'}`);
      if (process.env.V) r.forEach(v => console.log('    ', v.id, '-', v.help, '\n       ', v.eg.join('\n        ')));
    }
    await ctx.close();
  }
  console.log('violation types total:', total);
  await b.close();
  process.exit(total ? 1 : 0);
})();
