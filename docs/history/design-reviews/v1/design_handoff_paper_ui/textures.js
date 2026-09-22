// Seeded procedural textures. Each is a procedure (SwiftUI Canvas can redraw it), never a bitmap asset.
// LCG → uniform [0,1). Same shape as the app's GrainRandom.
export function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

// FELT NAP — the app's FeltView procedure verbatim: 4pt grid, jitter 0–4, 50% light #8CCC9E / 50% black, α .03–.11, dot Ø .8–1.6pt. 128pt tile @2x.
export function feltTile(seed = 12) {
  const c = document.createElement('canvas'); c.width = c.height = 256; const g = c.getContext('2d'); const r = rng(seed);
  for (let y = 0; y < 128; y += 4) for (let x = 0; x < 128; x += 4) {
    const cx = x + r() * 4, cy = y + r() * 4, light = r() < 0.5, a = 0.03 + r() * 0.08, d = 0.8 + r() * 0.8;
    g.fillStyle = light ? `rgba(140,204,158,${a.toFixed(3)})` : `rgba(0,0,0,${a.toFixed(3)})`;
    g.beginPath(); g.ellipse(cx * 2, cy * 2, d, d, 0, 0, Math.PI * 2); g.fill();
  }
  return c.toDataURL();
}

// BOARD CLOTH, plain weave. 64pt tile @2x. Weft rows every 2pt rgba(255,235,220,.05); warp columns every 2pt rgba(0,0,0,.07).
// Flecks on a 4pt grid, jitter 0–3: r<.10 light rgba(255,220,200,.04–.09); r<.16 dark rgba(0,0,0,.12).
export function clothTile(seed = 11) {
  const c = document.createElement('canvas'); c.width = c.height = 128; const g = c.getContext('2d'); const r = rng(seed);
  g.fillStyle = 'rgba(255,235,220,0.05)'; for (let y = 0; y < 64; y += 2) g.fillRect(0, y * 2, 128, 2);
  g.fillStyle = 'rgba(0,0,0,0.07)'; for (let x = 0; x < 64; x += 2) g.fillRect(x * 2, 0, 2, 128);
  flecks(g, r, 64, 4, 0.10, 0.16, 0.04, 0.09, 0.12);
  return c.toDataURL();
}

// BOARD CLOTH, twill. 48pt tile @2x. Diagonal ridges at 45°, 3pt pitch: 1pt light stroke rgba(255,235,220,.07) with a 1pt dark
// stroke rgba(0,0,0,.10) beside it; a fainter counter-diagonal every 6pt rgba(0,0,0,.04). Flecks as clothTile but denser (r<.14 / r<.24).
export function twillTile(seed = 13) {
  const N = 48, c = document.createElement('canvas'); c.width = c.height = N * 2; const g = c.getContext('2d'); const r = rng(seed);
  g.lineWidth = 2;
  for (let k = -N; k < N * 2; k += 3) {
    g.strokeStyle = 'rgba(255,235,220,0.07)'; g.beginPath(); g.moveTo(k * 2, 0); g.lineTo((k + N) * 2, N * 2); g.stroke();
    g.strokeStyle = 'rgba(0,0,0,0.10)'; g.beginPath(); g.moveTo((k + 1) * 2, 0); g.lineTo((k + 1 + N) * 2, N * 2); g.stroke();
  }
  g.strokeStyle = 'rgba(0,0,0,0.04)';
  for (let k = 0; k < N * 2; k += 6) { g.beginPath(); g.moveTo(k * 2, 0); g.lineTo((k - N) * 2, N * 2); g.stroke(); }
  flecks(g, r, N, 4, 0.14, 0.24, 0.04, 0.10, 0.14);
  return c.toDataURL();
}

// LEATHER, pebble grain. 40pt tile @2x. Cells on a 3pt grid, jitter 0–3: r<.35 a 1.5–2.5pt light pebble rgba(255,220,200,.05–.09) with a
// 1pt dark rim below rgba(0,0,0,.14–.22); r<.45 a lone dark pit rgba(0,0,0,.18) 1pt. Reads as grain at 1:1, as pebbles at 3:1.
export function leatherTile(seed = 17) {
  const N = 40, c = document.createElement('canvas'); c.width = c.height = N * 2; const g = c.getContext('2d'); const r = rng(seed);
  for (let y = 0; y < N; y += 3) for (let x = 0; x < N; x += 3) {
    const v = r(), cx = x + r() * 3, cy = y + r() * 3;
    if (v < 0.35) {
      const d = 1.5 + r();
      g.fillStyle = `rgba(0,0,0,${(0.14 + r() * 0.08).toFixed(3)})`; g.beginPath(); g.ellipse(cx * 2, (cy + 0.8) * 2, d, d * 0.8, 0, 0, 7); g.fill();
      g.fillStyle = `rgba(255,220,200,${(0.05 + r() * 0.04).toFixed(3)})`; g.beginPath(); g.ellipse(cx * 2, cy * 2, d, d * 0.8, 0, 0, 7); g.fill();
    } else if (v < 0.45) { g.fillStyle = 'rgba(0,0,0,0.18)'; g.fillRect(cx * 2, cy * 2, 2, 2); }
  }
  return c.toDataURL();
}

function flecks(g, r, N, step, pLight, pDark, aMin, aMax, aDark) {
  for (let y = 0; y < N; y += step) for (let x = 0; x < N; x += step) {
    const v = r(), jx = Math.floor(r() * 4), jy = Math.floor(r() * 4);
    if (v < pLight) g.fillStyle = `rgba(255,220,200,${(aMin + r() * (aMax - aMin)).toFixed(3)})`;
    else if (v < pDark) g.fillStyle = `rgba(0,0,0,${aDark})`;
    else continue;
    g.fillRect((x + jx) * 2, (y + jy) * 2, 2, 2);
  }
}

export function contrast(hexA, hexB) {
  const lum = h => { const n = parseInt(h.slice(1), 16); return [16, 8, 0].map(s => (n >> s & 255) / 255).map(v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)).reduce((a, v, i) => a + v * [0.2126, 0.7152, 0.0722][i], 0); };
  const a = lum(hexA), b = lum(hexB); return ((Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)).toFixed(2) + ':1';
}

// PORTRAITS — PortraitView.swift as a list of absolutely-positioned parts. Every measure is a fraction of size S.
const SKIN = { light: '#F5D9BD', tan: '#D9AD85', brown: '#9E704D', deep: '#61402B' };
const HAIR = { black: '#1F1A1A', brown: '#66432A', blond: '#CC9E52', silver: '#CCCCD1', red: '#B34D29' };
const SHIRT = { plum: '#6B335C', olive: '#667038', teal: '#296B70', rust: '#9E4D2E', navy: '#29386B', mustard: '#B8943B' };
const INK = '#333338', BLOSSOM = '#ED8C9E';
export const DISC = '#1A3D33';
export const CAST = {
  Hazel: { skin: 'light', hair: 'bob', hairColor: 'silver', feature: 'glasses', hat: 'none', shirt: 'plum' },
  Otto: { skin: 'tan', hair: 'short', hairColor: 'brown', feature: 'moustache', hat: 'cap', shirt: 'olive' },
  Rue: { skin: 'brown', hair: 'curly', hairColor: 'red', feature: 'freckles', hat: 'beanie', shirt: 'teal' },
  Connor: { skin: 'tan', hair: 'short', hairColor: 'black', feature: 'none', hat: 'none', shirt: 'navy' },
};
export function portraitParts(p, S) {
  const out = [];
  const add = (w, h, dx, dy, bg, r, sh) => out.push({ l: ((1 - w) / 2 + dx) * S, t: ((1 - h) / 2 + dy) * S, w: w * S, h: h * S, bg, r: r == null ? '50%' : r * S + 'px', sh: sh || 'none' });
  add(0.78, 0.5, 0, 0.5, SHIRT[p.shirt], 0.22);
  if (p.hair === 'bob') add(0.56, 0.6, 0, -0.02, HAIR[p.hairColor], 0.16);
  if (p.hair === 'curly') add(0.6, 0.6, 0, -0.06, HAIR[p.hairColor]);
  add(0.46, 0.54, 0, -0.02, SKIN[p.skin]);
  for (const s of [-1, 1]) { add(0.035, 0.035, s * 0.08, -0.06, INK); add(0.09, 0.014, s * 0.08, -0.115, INK); }
  add(0.14, 0.018, 0, 0.1, INK);
  if (p.feature === 'glasses') for (const s of [-1, 1]) add(0.15, 0.15, s * 0.085, -0.03, 'transparent', null, `inset 0 0 0 ${Math.max(1, S * 0.025)}px ${INK}`);
  if (p.feature === 'moustache') add(0.2, 0.05, 0, 0.05, HAIR[p.hairColor]);
  if (p.feature === 'freckles') for (const dx of [-0.07, 0, 0.07]) add(0.03, 0.03, dx, 0.05, 'rgba(51,51,56,.5)');
  if (p.hair === 'short') add(0.48, 0.24, 0, -0.24, HAIR[p.hairColor]);
  if (p.hat === 'beanie') add(0.5, 0.26, 0, -0.26, INK, 0.14);
  if (p.hat === 'cap') { add(0.5, 0.22, 0, -0.26, INK); add(0.62, 0.07, 0, -0.18, INK); }
  if (p.hat === 'flower') add(0.16, 0.16, 0.18, -0.24, BLOSSOM);
  return out;
}
