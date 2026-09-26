// Catch 5 — motion spec film. One tree, rendered from authored time T. Coordinates are the phone's (393×852), scaled to 1080×1920.
const { useComposition, CompositionStage, Captions, Easing, animate, clamp, TweaksPanel, useTweaks, TweakSection, TweakToggle } = window;
const h = window.React.createElement, Frag = window.React.Fragment;

// ---- procedural textures (same procedures as textures.js / FeltView) ----
function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }
function feltTile() { const c = document.createElement('canvas'); c.width = c.height = 256; const g = c.getContext('2d'); const r = rng(12);
  for (let y = 0; y < 128; y += 4) for (let x = 0; x < 128; x += 4) { const cx = x + r() * 4, cy = y + r() * 4, light = r() < .5, a = .03 + r() * .08, d = .8 + r() * .8;
    g.fillStyle = light ? `rgba(140,204,158,${a.toFixed(3)})` : `rgba(0,0,0,${a.toFixed(3)})`; g.beginPath(); g.ellipse(cx * 2, cy * 2, d, d, 0, 0, 7); g.fill(); } return c.toDataURL(); }
function clothTile() { const c = document.createElement('canvas'); c.width = c.height = 128; const g = c.getContext('2d'); const r = rng(11);
  g.fillStyle = 'rgba(255,235,220,0.05)'; for (let y = 0; y < 64; y += 2) g.fillRect(0, y * 2, 128, 2);
  g.fillStyle = 'rgba(0,0,0,0.07)'; for (let x = 0; x < 64; x += 2) g.fillRect(x * 2, 0, 2, 128);
  for (let y = 0; y < 64; y += 4) for (let x = 0; x < 64; x += 4) { const v = r(), jx = Math.floor(r() * 4), jy = Math.floor(r() * 4);
    if (v < .10) g.fillStyle = `rgba(255,220,200,${(.04 + r() * .05).toFixed(3)})`; else if (v < .16) g.fillStyle = 'rgba(0,0,0,0.12)'; else continue; g.fillRect((x + jx) * 2, (y + jy) * 2, 2, 2); } return c.toDataURL(); }
const FELT = feltTile(), CLOTH = clothTile();

// ---- portraits (PortraitView recipe) ----
const SKIN = { light: '#F5D9BD', tan: '#D9AD85', brown: '#9E704D', deep: '#61402B' }, HAIR = { black: '#1F1A1A', brown: '#66432A', blond: '#CC9E52', silver: '#CCCCD1', red: '#B34D29' };
const SHIRT = { plum: '#6B335C', olive: '#667038', teal: '#296B70', rust: '#9E4D2E', navy: '#29386B', mustard: '#B8943B' }, INK = '#333338';
const CAST = { Hazel: { skin: 'light', hair: 'bob', hairColor: 'silver', feature: 'glasses', hat: 'none', shirt: 'plum' }, Otto: { skin: 'tan', hair: 'short', hairColor: 'brown', feature: 'moustache', hat: 'cap', shirt: 'olive' }, Rue: { skin: 'brown', hair: 'curly', hairColor: 'red', feature: 'freckles', hat: 'beanie', shirt: 'teal' }, Connor: { skin: 'tan', hair: 'short', hairColor: 'black', feature: 'none', hat: 'none', shirt: 'navy' } };
function portraitParts(p, S) { const out = []; const add = (w, hh, dx, dy, bg, r, sh) => out.push({ l: ((1 - w) / 2 + dx) * S, t: ((1 - hh) / 2 + dy) * S, w: w * S, h: hh * S, bg, r: r == null ? '50%' : r * S + 'px', sh: sh || 'none' });
  add(.78, .5, 0, .5, SHIRT[p.shirt], .22); if (p.hair === 'bob') add(.56, .6, 0, -.02, HAIR[p.hairColor], .16); if (p.hair === 'curly') add(.6, .6, 0, -.06, HAIR[p.hairColor]);
  add(.46, .54, 0, -.02, SKIN[p.skin]); for (const s of [-1, 1]) { add(.035, .035, s * .08, -.06, INK); add(.09, .014, s * .08, -.115, INK); } add(.14, .018, 0, .1, INK);
  if (p.feature === 'glasses') for (const s of [-1, 1]) add(.15, .15, s * .085, -.03, 'transparent', null, `inset 0 0 0 ${Math.max(1, S * .025)}px ${INK}`);
  if (p.feature === 'moustache') add(.2, .05, 0, .05, HAIR[p.hairColor]); if (p.feature === 'freckles') for (const dx of [-.07, 0, .07]) add(.03, .03, dx, .05, 'rgba(51,51,56,.5)');
  if (p.hair === 'short') add(.48, .24, 0, -.24, HAIR[p.hairColor]); if (p.hat === 'beanie') add(.5, .26, 0, -.26, INK, .14); if (p.hat === 'cap') { add(.5, .22, 0, -.26, INK); add(.62, .07, 0, -.18, INK); } return out; }
const PARTS = { Otto: portraitParts(CAST.Otto, 68), Hazel: portraitParts(CAST.Hazel, 68), Rue: portraitParts(CAST.Rue, 68), Connor: portraitParts(CAST.Connor, 64) };

// ---- the three motion helpers ----
const MOTION = {
  enter: (from, to, start, dur) => animate({ from, to, start, end: start + dur, ease: Easing.easeOutCubic }),   // fades, slides, lid
  fly:   (from, to, start, dur) => animate({ from, to, start, end: start + dur, ease: Easing.easeOutQuart }),   // card flights (spring, bounce 0)
  pop:   (from, to, start, dur) => animate({ from, to, start, end: start + dur, ease: Easing.easeOutBack }),    // chips, pulses
};
const SERIF = "'New York','Iowan Old Style',Palatino,Georgia,serif", MONO = "'SF Mono',Menlo,ui-monospace,monospace", SANS = "-apple-system,'SF Pro Text',system-ui,sans-serif";
const IVORY = '#FAF5E3', GOLD = '#E8BF6B', RED = '#B31F2E';
const ink = s => (s === '♥' || s === '♦') ? RED : '#000';
const lerp = (a, b, t) => a + (b - a) * t;
const fanPos = (n, i) => { const t = n > 1 ? i / (n - 1) : .5; return { x: (393 - (58 + (n - 1) * 50)) / 2 + i * 50, y: 690 + Math.pow((t - .5) * 2, 2) * 6, rot: (t - .5) * 16 }; };
const DECK = { x: 339, y: 156 }, DISC = { x: 16, y: 156 }, PILE = { N: { x: 165.5, y: 263.5, rot: -4 }, W: { x: 117.5, y: 309.5, rot: -9 }, E: { x: 213.5, y: 309.5, rot: 7 }, S: { x: 165.5, y: 347.5, rot: 3 } };
const SEAT = { Otto: { x: 138.5, y: 129 }, Hazel: { x: 16, y: 290 }, Rue: { x: 261, y: 290 } };

// ---- atoms ----
function CardFace({ r, s, w, hh, style }) { const k = w / 58; return h('div', { style: Object.assign({ position: 'absolute', width: w, height: hh, borderRadius: w * .06, background: IVORY, color: ink(s), fontFamily: SERIF, boxShadow: 'inset 0 0 0 1px rgba(0,0,0,.15), 0 3px 3px rgba(0,0,0,.25)' }, style) },
  h('div', { style: { position: 'absolute', left: 5 * k, top: 4 * k, display: 'flex', flexDirection: 'column', alignItems: 'center', fontWeight: 700, fontSize: 13 * k, lineHeight: 1 } }, r, h('span', { style: { fontSize: 12 * k } }, s)),
  h('div', { style: { position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' } }, h('div', { style: { fontWeight: 700, fontSize: 24 * k, lineHeight: 1.1 } }, r), h('div', { style: { fontSize: 27 * k, lineHeight: 1.05 } }, s))); }
function CardBack({ w, hh, style }) { return h('div', { style: Object.assign({ position: 'absolute', width: w, height: hh, borderRadius: w * .06, background: '#0F382E', boxShadow: 'inset 0 0 0 1.5px rgba(250,245,227,.7), inset 0 0 0 5px #0F382E, inset 0 0 0 6px rgba(250,245,227,.35), 0 2px 3px rgba(0,0,0,.3)' }, style) }); }
function Portrait({ name, size }) { return h('div', { style: { position: 'relative', width: size, height: size, borderRadius: '50%', background: '#1A3D33', overflow: 'hidden', boxShadow: 'inset 0 0 0 2px rgba(250,245,227,.7)' } }, PARTS[name].map((q, i) => h('div', { key: i, style: { position: 'absolute', left: q.l, top: q.t, width: q.w, height: q.h, borderRadius: q.r, background: q.bg, boxShadow: q.sh } }))); }
function Tap({ x, y, at, T }) { const p = clamp((T - at) / .35, 0, 1); if (p <= 0 || p >= 1) return null; return h('div', { style: { position: 'absolute', left: x - 22, top: y - 22, width: 44, height: 44, borderRadius: '50%', background: 'rgba(250,245,227,.35)', boxShadow: '0 0 0 2px rgba(250,245,227,.6)', transform: `scale(${lerp(.6, 1.3, p)})`, opacity: 1 - p, pointerEvents: 'none' } }); }
const btn = (label, primary, extra) => h('div', { style: Object.assign({ minHeight: 56, borderRadius: 14, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 21, fontWeight: 600, padding: '14px 20px', color: IVORY, position: 'relative', overflow: 'hidden',
  background: primary ? 'radial-gradient(ellipse at 50% 30%,#295742,#1A4030)' : '#4A161F',
  boxShadow: primary ? 'inset 0 2px 5px rgba(0,0,0,.55), inset 0 0 0 1px rgba(0,0,0,.5), 0 1px 0 rgba(255,225,205,.16)' : 'inset 0 2px 4px rgba(0,0,0,.55), inset 0 0 0 1px rgba(0,0,0,.35), 0 1px 0 rgba(255,225,205,.14)' }, extra) },
  primary ? h('div', { style: { position: 'absolute', inset: 0, backgroundImage: `url(${FELT})`, backgroundSize: '128px 128px' } }) : null, h('span', { style: { position: 'relative' } }, label));

// ---- the piece ----
function Piece({ tweaks }) {
  const { T, CUES } = useComposition();
  const C = CUES, L = C.Lift, D = C.Deal, B = C.Bid, R = C.Trump, K = C.Trick, P = C.Pause;
  const win = (a, b) => T >= a && T < b;

  // lid position and layer opacities
  let lidY = 0;
  if (T >= L + .6) lidY = MOTION.enter(0, -739, L + .6, .45)(T);
  if (T >= P + .4) lidY = MOTION.enter(-739, -470, P + .4, .5)(T);
  if (T >= P + 2.3) lidY = MOTION.enter(-470, 0, P + 2.3, .6)(T);
  let menuOp = T < L + .4 ? 1 : MOTION.enter(1, 0, L + .4, .3)(T); if (T >= P + 2.4) menuOp = MOTION.enter(0, 1, P + 2.4, .45)(T);
  let pauseOp = T < P + .5 ? 0 : MOTION.enter(0, 1, P + .5, .4)(T); if (T >= P + 2.2) pauseOp = MOTION.enter(1, 0, P + 2.2, .3)(T);
  let bandOp = T < L + .9 ? 0 : MOTION.enter(0, 1, L + .9, .3)(T); if (T >= P + 2.3) bandOp = MOTION.enter(1, 0, P + 2.3, .3)(T);
  let dim = T < P + .4 ? 0 : MOTION.enter(0, .55, P + .4, .4)(T); if (T >= P + 2.3) dim = MOTION.enter(.55, 0, P + 2.3, .5)(T);
  const pressScale = win(L + .3, L + .55) ? (T < L + .42 ? lerp(1, .97, (T - L - .3) / .12) : lerp(.97, 1, (T - L - .42) / .13)) : 1;
  const lightDrift = Math.sin(T * .6) * 6; // the closed box is never a still frame

  // seat to act
  const halo = win(B, B + .5) ? 'Otto' : win(B + .9, B + 1.6) ? 'Rue' : win(B + 3.8, B + 4.4) ? 'Hazel' : win(B + 4.8, R + .4) ? 'Rue' : win(K, K + .4) ? 'Otto' : win(K + .5, K + 1.1) ? 'Hazel' : win(K + 1.2, K + 1.7) ? 'Rue' : T >= K + 3 ? 'Rue' : null;
  const pulse = win(B + 4.8, B + 5.15) ? MOTION.pop(1, 1.05, B + 4.8, .35)(T) : 1;

  // deal: 24 flights, seat order Otto, Rue, Connor, Hazel; stagger .07, flight .25
  const dealOrder = ['Otto', 'Rue', 'Connor', 'Hazel'];
  const dealStart = i => D + .3 + i * .07;
  const dealt = name => { let n = 0; for (let i = 0; i < 24; i++) if (dealOrder[i % 4] === name && T >= dealStart(i) + .25) n++; return n; };
  const dealFlights = []; for (let i = 0; i < 24; i++) { const name = dealOrder[i % 4]; if (name === 'Connor') continue; const s0 = dealStart(i), p = clamp((T - s0) / .25, 0, 1); if (p <= 0 || p >= 1) continue;
    const seat = SEAT[name], tx = seat.x + 58 - 7 + Math.floor(i / 4) * 0, ty = seat.y + 78 + 26; const e = Easing.easeOutQuart(p);
    dealFlights.push(h(CardBack, { key: 'df' + i, w: lerp(38, 14, e), hh: lerp(57, 21, e), style: { left: lerp(DECK.x, tx, e), top: lerp(DECK.y, ty, e), transform: `rotate(${lerp(0, name === 'Hazel' ? -12 : name === 'Rue' ? 12 : 0, e)}deg)` } })); }
  const flipAt = dealStart(23) + .5;

  // hand: six slots; initial cards, two discards, two refills
  const slots = [{ c: ['10', '♥'] }, { c: ['5', '♥'] }, { c: ['4', '♥'] }, { c: ['3', '♥'] }, { c: ['9', '♣'], out: true, re: ['4', '♦'] }, { c: ['Q', '♦'], out: true, re: ['K', '♠'] }];
  const handEls = [], discardEls = [];
  const yourTurn = win(K + 1.8, K + 2.3);
  slots.forEach((sl, j) => {
    const ds = dealStart(4 * j + 2); if (T < ds) return;
    const flat = { x: fanPos(6, j).x, y: 700, rot: 0 };
    let card = sl.c, x, y, rot, scale = 1, op = 1, flip = 1, faceUp = false, veil = 0;
    if (T < ds + .25) { const e = Easing.easeOutQuart((T - ds) / .25); x = lerp(DECK.x, flat.x, e); y = lerp(DECK.y, flat.y, e); rot = 0; scale = lerp(38 / 58, 1, e); }
    else if (T < flipAt) { x = flat.x; y = flat.y; rot = 0; }
    else { const f6 = fanPos(6, j); const p = clamp((T - flipAt) / .4, 0, 1), e = Easing.easeOutCubic(p); x = lerp(flat.x, f6.x, e); y = lerp(flat.y, f6.y, e); rot = lerp(0, f6.rot, e); flip = Math.abs(1 - 2 * p); faceUp = p >= .5; }
    // trump: discards leave, the four close up, then the refill opens the fan again
    if (sl.out) { const t0 = R + .8 + (j - 4) * .05;
      if (T >= t0) { const p = clamp((T - t0) / .5, 0, 1), e = Easing.easeOutQuart(p); const f6 = fanPos(6, j); x = lerp(f6.x, DISC.x, e); y = lerp(f6.y, DISC.y, e); rot = lerp(f6.rot, 5 - (j - 4) * 5, e); scale = lerp(1, .55, e); op = 1 - p; faceUp = true; flip = 1;
        if (p >= 1) { discardEls.push(h(CardBack, { key: 'disc' + j, w: 32, hh: 48, style: { left: DISC.x + (j - 4) * 1.5, top: DISC.y - (j - 4) * 1.5, transform: `rotate(${5 - (j - 4) * 5}deg)`, opacity: .8 } })); op = 0; } }
      const rs = R + 1.9 + .35 + (j - 4) * .09; // refill from the dealer's seat
      if (T >= rs) { card = sl.re; faceUp = true; flip = 1; const p = clamp((T - rs) / .45, 0, 1), e = Easing.easeOutQuart(p); const f6 = fanPos(6, j); x = lerp(SEAT.Hazel.x + 58, f6.x, e); y = lerp(SEAT.Hazel.y + 34, f6.y, e); rot = lerp(-10, f6.rot, e); scale = lerp(.6, 1, e); op = p; }
    } else if (T >= R + 1.4) { const f6 = fanPos(6, j), f4 = fanPos(4, j); const a = Easing.easeOutCubic(clamp((T - R - 1.4) / .35, 0, 1)), b = Easing.easeOutCubic(clamp((T - R - 1.9) / .45, 0, 1)); const mx = lerp(f6.x, f4.x, a), my = lerp(f6.y, f4.y, a), mr = lerp(f6.rot, f4.rot, a); x = lerp(mx, f6.x, b); y = lerp(my, f6.y, b); rot = lerp(mr, f6.rot, b); }
    // Connor's turn: the legal card lifts, the rest sit in shadow; then K♠ flies to the pile and collapses with it
    if (yourTurn) { if (j === 5) y -= 6; else veil = .38; }
    if (j === 5 && T >= K + 2.3) { const p = clamp((T - K - 2.3) / .45, 0, 1), e = Easing.easeOutQuart(p); const f6 = fanPos(6, 5); x = lerp(f6.x, PILE.S.x, e); y = lerp(f6.y, PILE.S.y, e); rot = lerp(f6.rot, PILE.S.rot, e); scale = lerp(1, 62 / 58, e);
      if (T >= K + 3.5) { const q = clamp((T - K - 3.5) / .5, 0, 1), e2 = Easing.easeOutCubic(q); x += 236 * e2; scale *= lerp(1, .5, e2); op = 1 - q; } }
    if (op <= 0) return;
    const face = faceUp && flip !== undefined; const w = 58, hh = 87;
    handEls.push(h('div', { key: 'h' + j, style: { position: 'absolute', left: x, top: y, width: w, height: hh, transform: `rotate(${rot}deg) scale(${scale}) scaleX(${flip})`, transformOrigin: faceUp ? '50% 100%' : '50% 50%', opacity: op, zIndex: j } },
      face ? h(CardFace, { r: card[0], s: card[1], w, hh, style: { left: 0, top: 0, filter: veil ? `saturate(.35)` : 'none' } }) : h(CardBack, { w, hh, style: { left: 0, top: 0 } }),
      veil ? h('div', { style: { position: 'absolute', inset: 0, borderRadius: w * .06, background: `rgba(0,0,0,${veil})` } }) : null));
  });

  // opponents' pile cards: fly in from their seat, then collapse toward the winner (E)
  const pileEls = [[K + .2, 'N', 'Q', '♠'], [K + .9, 'W', '9', '♠'], [K + 1.5, 'E', '7', '♥']].map(([t0, dir, r, s], i) => { if (T < t0) return null; const p = clamp((T - t0) / .45, 0, 1), e = Easing.easeOutQuart(p); const P0 = PILE[dir]; const ox = dir === 'W' ? -236 : dir === 'E' ? 236 : 0, oy = dir === 'N' ? -466 : 0;
    let x = P0.x + ox * (1 - e), y = P0.y + oy * (1 - e), scale = 1, op = Math.min(1, p * 2), rot = P0.rot; const ring = dir === 'E' && T >= K + 2.75 ? 3 : 0;
    if (T >= K + 3.5) { const q = clamp((T - K - 3.5) / .5, 0, 1), e2 = Easing.easeOutCubic(q); x += 236 * e2; scale = lerp(1, .5, e2); op = 1 - q; }
    return h(CardFace, { key: 'p' + i, r, s, w: 62, hh: 93, style: { left: x, top: y, transform: `rotate(${rot}deg) scale(${scale})`, opacity: op, boxShadow: `inset 0 0 0 1px rgba(0,0,0,.15), 0 0 0 ${ring}px ${GOLD}, 0 3px 3px rgba(0,0,0,.25)` } }); });

  // bid chips: fly from the pile's centre to the bidder's badge
  const chip = (t0, name, label) => { if (T < t0 || T >= R) return null; const p = clamp((T - t0) / .35, 0, 1), e = Easing.easeOutBack(p); const seat = SEAT[name]; const tx = seat.x + 58, ty = seat.y + 78 + 26 + 11;
    return h('div', { key: 'chip' + name, style: { position: 'absolute', left: lerp(196.5, tx, e) - 18, top: lerp(352, ty, e) - 11, padding: '2px 8px', borderRadius: 11, background: '#1F130A', color: IVORY, fontFamily: MONO, fontSize: 15, fontWeight: 600, lineHeight: '18px', transform: `scale(${lerp(1.3, 1, e)})`, opacity: label === 'Pass' ? .7 : 1 } }, label); };
  const badgeOp = (t0) => T < t0 ? 0 : MOTION.enter(0, .7, t0, .3)(T);

  // status line
  const st = (() => {
    if (T < D + .2) return ['Hazel deals', false, ''];
    if (T < B + .9) return ['Otto is bidding · high bid none', false, ''];
    if (T < B + 2) return ['Rue is bidding · high bid 3', false, ''];
    if (T < B + 3.8) return ['Your bid', true, ' · high bid 4'];
    if (T < B + 4.8) return ['Hazel is bidding · high bid 4', false, ''];
    if (T < R + .4) return ['Rue is choosing trump', false, ''];
    if (T < K) return ['Rue names hearts', false, ''];
    if (T < K + .5) return ['Otto is thinking', false, ''];
    if (T < K + 1.2) return ['Hazel is thinking', false, ''];
    if (T < K + 1.8) return ['Rue is thinking', false, ''];
    if (T < K + 2.75) return ['Your turn', true, ' · follow ♠'];
    if (T < K + 3.6) return ['Rue takes the trick', false, ''];
    return ['Rue is thinking', false, ''];
  })();
  const inAuction = win(B + 2, B + 3.8); const pillsOp = inAuction ? Math.min(MOTION.enter(0, 1, B + 2, .3)(T), 1) : T >= B + 3.8 ? Math.max(0, 1 - (T - B - 3.8) / .3) : 0;
  const statusY = pillsOp > 0 ? lerp(586, 646, pillsOp) : 586;
  const showContract = T >= B + 5.2, showSuit = T >= R + .3, contractPop = MOTION.pop(.6, 1, B + 5.2, .35)(T), suitPop = MOTION.pop(0, 1, R + .3, .3)(T);

  const seatEl = (name) => { const s = SEAT[name]; const backs = Math.min(3, Math.max(0, dealt(name) - (name === 'Rue' && T >= K + 1.5 ? 1 : name === 'Otto' && T >= K + .2 ? 1 : name === 'Hazel' && T >= K + .9 ? 1 : 0) * 0));
    const isHalo = halo === name, hazelDim = name === 'Hazel' && T >= B + 4.4 && T < B + 5.2 ? .85 : 1;
    return h('div', { key: name, style: { position: 'absolute', left: s.x, top: s.y, width: 116, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, color: IVORY, fontFamily: SANS, opacity: hazelDim } },
      h('div', { style: { position: 'relative', margin: '3px 0', transform: `scale(${isHalo ? pulse : 1})` } }, h(Portrait, { name, size: 68 }), h('div', { style: { position: 'absolute', inset: -3, borderRadius: '50%', boxShadow: `0 0 0 3px ${GOLD}`, opacity: isHalo ? 1 : 0, transition: 'none' } })),
      h('div', { style: { fontSize: 21, fontWeight: 600, lineHeight: '26px' } }, name),
      h('div', { style: { display: 'flex', alignItems: 'center', gap: 6, height: 23, fontFamily: MONO, fontSize: 15 } },
        backs > 0 && !inAuctionPhase(T, B, R) ? h('div', { style: { position: 'relative', width: 20, height: 21, marginRight: 6 } }, [0, 1, 2].slice(0, backs).map(i => h('div', { key: i, style: { position: 'absolute', left: i * 3, top: 0, width: 14, height: 21, borderRadius: 1, background: '#0F382E', boxShadow: 'inset 0 0 0 1px rgba(250,245,227,.7)' } }))) : null,
        name === 'Otto' && T >= B + .85 && T < R ? h('span', { style: { padding: '2px 8px', borderRadius: 11, background: '#1F130A', fontWeight: 600 } }, '3') : null,
        name === 'Rue' && T >= B + 1.95 && T < R ? h('span', { style: { padding: '2px 8px', borderRadius: 11, background: '#1F130A', fontWeight: 600 } }, '4') : null,
        name === 'Hazel' && T >= B + 4.4 && T < R ? h('span', { style: { padding: '2px 8px', borderRadius: 11, background: '#1F130A', fontWeight: 600, opacity: badgeOp(B + 4.4) } }, 'Pass') : null,
        name === 'Hazel' ? h('span', { style: { color: GOLD } }, 'DEALER') : null,
        name === 'Rue' && T >= R ? h('span', { style: { opacity: .7 } }, 'BIDDER') : null));
  };
  function inAuctionPhase(T, B, R) { return T >= B && T < R + .4; }

  const pill = (label, dimmed, wide) => h('div', { style: { flex: 1, height: 64, borderRadius: 14, background: '#1F130A', boxShadow: 'inset 0 0 0 1px rgba(250,245,227,.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: IVORY, fontSize: wide ? 21 : 24, fontWeight: 600, opacity: dimmed ? .35 : 1 } }, label);

  return h('div', { 'data-screen-label': `t=${T.toFixed(1)}s`, style: { position: 'relative', width: 1080, height: 1920, background: '#1c1a1c', overflow: 'hidden', fontFamily: SANS } },
    h('div', { style: { position: 'absolute', left: 540 - 393 * 1.9 / 2, top: 0, width: 393, height: 852, transform: 'scale(1.9)', transformOrigin: '0 0', overflow: 'hidden', borderRadius: 52, background: '#1A4030', color: IVORY } },
      // ===== TABLE (felt, untouched) =====
      h('div', { style: { position: 'absolute', inset: 0, background: 'radial-gradient(circle at 50% 45%, #295742 40px, #1A4030 380px, #0A211A 720px)' } }),
      h('div', { style: { position: 'absolute', inset: 0, backgroundImage: `url(${FELT})`, backgroundSize: '128px 128px' } }),
      [0, 1, 2, 3].map(i => h(CardBack, { key: 'deck' + i, w: 38, hh: 57, style: { left: DECK.x - i * 2, top: DECK.y - i * 2, opacity: T < D + .3 + 20 * .07 ? 1 : i < 2 ? 1 : 0 } })),
      discardEls,
      ['Otto', 'Hazel', 'Rue'].map(seatEl),
      dealFlights,
      pileEls,
      chip(B + .5, 'Otto', '3'), chip(B + 1.6, 'Rue', '4'),
      T >= D && T < B ? h('div', { style: { position: 'absolute', left: 0, right: 0, top: 344, textAlign: 'center', fontSize: 15, opacity: 0 } }, '') : null,
      // auction pills
      h('div', { style: { position: 'absolute', left: 16, right: 16, top: 425, display: 'flex', flexDirection: 'column', gap: 6, opacity: pillsOp, transform: `translateY(${(1 - pillsOp) * 12}px)` } },
        h('div', { style: { display: 'flex', gap: 6 } }, pill('2', true), pill('3', true), pill('4', true), pill('5', false)),
        h('div', { style: { display: 'flex', gap: 6 } }, pill('6', false), pill('7', false), pill('8', false), pill('9', false)),
        h('div', { style: { display: 'flex', gap: 6 } }, pill('Pass', false, true), pill('9 and out', true, true))),
      // status
      h('div', { style: { position: 'absolute', left: 16, right: 16, top: statusY, height: 44, display: 'flex', alignItems: 'center', gap: 8, opacity: T >= D ? 1 : 0 } },
        h('div', { style: { width: 44, flex: 'none' } }), h('div', { style: { flex: 1, textAlign: 'center', fontSize: 24, lineHeight: '30px', fontWeight: 500, whiteSpace: 'nowrap' } }, h('span', { style: { color: st[1] ? GOLD : IVORY } }, st[0]), st[2]), h('div', { style: { width: 44, flex: 'none' } })),
      T >= K + 3.6 ? h('div', { style: { position: 'absolute', left: 24, right: 24, top: 636, textAlign: 'center', fontSize: 17, color: 'rgba(250,245,227,.7)', opacity: MOTION.enter(0, 1, K + 3.6, .3)(T) } }, 'Tap a card on the table to see why it was played') : null,
      // hand
      handEls,
      h('div', { style: { position: 'absolute', left: 0, right: 0, top: 797, textAlign: 'center', fontFamily: MONO, fontSize: 15, letterSpacing: 1, opacity: T >= flipAt ? .7 : 0, display: 'flex', justifyContent: 'center', gap: 8 } }, 'YOUR HAND', T >= B + 3.7 && T < R ? h('span', { style: { opacity: badgeOp(B + 3.7), color: IVORY } }, '· PASS') : null),
      // pause dim
      h('div', { style: { position: 'absolute', inset: 0, background: '#000', opacity: dim, zIndex: 9 } }),
      // ===== THE LID (box 2b): menu when closed, header band when open, pause card when lowered =====
      h('div', { style: { position: 'absolute', left: 0, top: 0, width: 393, height: 852, zIndex: 10, transform: `translateY(${lidY}px)`, clipPath: "path('M0 0H393V852Q196.5 816 0 852Z')", background: '#5C1F2A', filter: 'drop-shadow(0 4px 10px rgba(0,0,0,.45))' } },
        h('div', { style: { position: 'absolute', inset: 0, background: 'linear-gradient(135deg,#7A2E3A 0%,#5C1F2A 45%,#3D111A 100%)' } }),
        h('div', { style: { position: 'absolute', inset: 0, backgroundImage: `url(${CLOTH})`, backgroundSize: '64px 64px' } }),
        h('div', { style: { position: 'absolute', inset: 0, background: `linear-gradient(${180 + lightDrift}deg, rgba(255,255,255,.05), rgba(0,0,0,.14))` } }),
        // lip along the frown edge
        h('svg', { width: 393, height: 852, viewBox: '0 0 393 852', style: { position: 'absolute', left: 0, top: 0 } },
          h('path', { d: 'M0 845Q196.5 809 393 845', fill: 'none', stroke: 'rgba(0,0,0,.28)', strokeWidth: 6 }),
          h('path', { d: 'M0 842.5Q196.5 806.5 393 842.5', fill: 'none', stroke: 'rgba(255,225,205,.22)', strokeWidth: 1.5 }),
          h('path', { d: 'M0 851Q196.5 815 393 851', fill: 'none', stroke: 'rgba(0,0,0,.6)', strokeWidth: 2 })),
        // menu content
        h('div', { style: { position: 'absolute', inset: 0, opacity: menuOp } },
          h('div', { style: { position: 'absolute', left: 14, right: 14, top: 14, bottom: 128, borderRadius: 40, boxShadow: 'inset 0 8px 18px rgba(0,0,0,.55), inset 0 -2px 5px rgba(255,225,205,.08), 0 0 0 1px rgba(255,225,205,.18), 0 0 0 2px rgba(0,0,0,.35)' } }),
          h('div', { style: { position: 'absolute', right: 12, top: 60, width: 44, height: 44, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 5 } }, [0, 1, 2].map(i => h('div', { key: i, style: { width: 22, height: 2, background: IVORY, borderRadius: 1 } }))),
          h('div', { style: { position: 'absolute', left: 30, right: 30, top: 136, display: 'flex', flexDirection: 'column', gap: 28 } },
            h('div', { style: { display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 } },
              h('div', { style: { fontFamily: SERIF, fontWeight: 700, fontSize: 64, lineHeight: '66px', letterSpacing: '.02em', color: '#3D111A', textShadow: '1px 1px 0 rgba(255,225,205,.26), -1px -1px 1px rgba(0,0,0,.75), 0 0 1px rgba(0,0,0,.4)' } }, 'CATCH 5'),
              h('div', { style: { fontFamily: MONO, fontSize: 14, letterSpacing: '.32em', color: '#D9C7C0', paddingLeft: '.32em' } }, 'MAIN MENU')),
            h('div', { style: { position: 'relative', display: 'flex', alignItems: 'center', gap: 16, padding: 16, borderRadius: 16, background: 'radial-gradient(ellipse at 50% 30%,#295742,#1A4030 70%,#0A211A)', boxShadow: 'inset 0 3px 6px rgba(0,0,0,.65), inset 0 0 0 1px rgba(0,0,0,.5), 0 1px 0 rgba(255,225,205,.16)', overflow: 'hidden' } },
              h('div', { style: { position: 'absolute', inset: 0, backgroundImage: `url(${FELT})`, backgroundSize: '128px 128px' } }),
              h('div', { style: { position: 'relative', flex: 'none' } }, h(Portrait, { name: 'Connor', size: 64 })),
              h('div', { style: { position: 'relative', display: 'flex', flexDirection: 'column', gap: 3 } }, h('div', { style: { fontFamily: SERIF, fontWeight: 600, fontSize: 24, lineHeight: '28px' } }, 'Connor'), h('div', { style: { fontSize: 17, lineHeight: '22px', opacity: .75 } }, 'Standard opponents'), h('div', { style: { fontSize: 17, lineHeight: '22px' } }, 'Hand 3 · Your team 21, their team 14 · trick 4'))),
            h('div', { style: { display: 'flex', flexDirection: 'column', gap: 6 } },
              h('div', { style: { display: 'flex', alignItems: 'center', justifyContent: 'space-between', minHeight: 44 } }, h('div', { style: { fontSize: 21, fontWeight: 600 } }, 'Beginner mode'), h('div', { style: { width: 51, height: 31, borderRadius: 16, background: '#295742', position: 'relative', boxShadow: 'inset 0 1px 2px rgba(0,0,0,.4)' } }, h('div', { style: { position: 'absolute', right: 2, top: 2, width: 27, height: 27, borderRadius: '50%', background: IVORY, boxShadow: '0 2px 4px rgba(0,0,0,.4)' } }))),
              h('div', { style: { fontSize: 17, color: '#D9C7C0' } }, 'Hints and guided play')),
            h('div', { style: { display: 'flex', flexDirection: 'column', gap: 12 } }, btn('Continue game', true, { transform: `scale(${pressScale})` }), btn('New match', false), btn('How to play', false)))),
        // pause card content (the lid lowered halfway)
        h('div', { style: { position: 'absolute', left: 30, right: 30, top: 540, display: 'flex', flexDirection: 'column', gap: 8, opacity: pauseOp } },
          h('div', { style: { textAlign: 'center', fontFamily: SERIF, fontWeight: 600, fontSize: 28, lineHeight: '32px', marginBottom: 2 } }, 'Paused'),
          btn('Continue game', true, { minHeight: 44, padding: '8px 20px' }), btn('New match', false, { minHeight: 44, padding: '8px 20px' }), btn('Main menu', false, { minHeight: 44, padding: '8px 20px' })),
        // header band content (bottom 113 of the lid)
        h('div', { style: { position: 'absolute', left: 0, right: 0, top: 739, height: 113, opacity: bandOp } },
          h('div', { style: { position: 'absolute', left: 16, right: 16, top: 61, height: 44, display: 'flex', alignItems: 'center', gap: 10 } },
            h('div', { style: { flex: 'none', display: 'flex', alignItems: 'baseline', gap: 4, fontSize: 19, fontWeight: 600, whiteSpace: 'nowrap' } }, h('span', { style: { opacity: .7 } }, 'Us'), h('span', { style: { fontFamily: SERIF, fontSize: 24 } }, '21'), h('span', { style: { opacity: .5 } }, '·'), h('span', { style: { opacity: .7 } }, 'Them'), h('span', { style: { fontFamily: SERIF, fontSize: 24 } }, '14')),
            h('div', { style: { flex: 1, display: 'flex', justifyContent: 'center' } }, showContract ? h('div', { style: { height: 36, padding: '0 14px', borderRadius: 12, background: 'radial-gradient(ellipse at 50% 40%, #295742, #1A4030)', boxShadow: 'inset 0 1px 3px rgba(0,0,0,.6), 0 0 0 1px rgba(0,0,0,.35), 0 1px 0 rgba(255,225,205,.12)', display: 'flex', alignItems: 'center', gap: 5, fontFamily: SERIF, fontWeight: 600, fontSize: 24, color: GOLD, whiteSpace: 'nowrap', transform: `scale(${contractPop})` } }, showSuit ? h('span', { style: { color: '#DB2E38', display: 'inline-block', transform: `scale(${suitPop})` } }, '♥') : null, h('span', null, '4'), h('span', { style: { opacity: .6 } }, '—'), h('span', null, 'Rue')) : null),
            h('div', { style: { flex: 'none', width: 44, height: 44, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'flex-end', gap: 5 } }, [0, 1, 2].map(i => h('div', { key: i, style: { width: 22, height: 2, background: IVORY, borderRadius: 1 } })))))),
      // the phone's own status bar sits above everything
      h('div', { style: { position: 'absolute', left: 0, right: 0, top: 0, height: 59, zIndex: 30, pointerEvents: 'none' } },
        h('div', { style: { position: 'absolute', left: 38, top: 16, fontSize: 17, fontWeight: 600, color: IVORY } }, '2:38'),
        h('div', { style: { position: 'absolute', left: 131, top: 11, width: 131, height: 37, borderRadius: 19, background: '#000' } })),
      // ghost taps (phone coordinates; lid taps follow the lid)
      tweaks.taps ? h('div', { style: { position: 'absolute', inset: 0, zIndex: 20, pointerEvents: 'none' } }, h(Tap, { key: 't1', x: 196.5, y: 630 + lidY, at: L + .3, T }), h(Tap, { key: 't2', x: 110, y: 597, at: B + 3.5, T }), h(Tap, { key: 't3', x: 359, y: 83, at: P + .15, T }), h(Tap, { key: 't4', x: 196.5, y: 700 + lidY, at: P + 2.05, T })) : null),
    tweaks.captions ? h(Captions, { style: { top: 1660, bottom: 'auto', left: 80, right: 80, font: `500 30px/1.35 ${SANS}`, color: '#eee', textShadow: 'none', textWrap: 'pretty' }, items: [
      { at: 0, text: 'Launch. The box is closed: letterpress title, felt-lined wells, no gold on the box.' },
      { at: L, text: 'Continue game lifts the lid: spring 0.45 s, bounce 0. Its bottom edge stays as the header band.' },
      { at: D, text: 'The deal: 24 flights from the deck, 250 ms each, 70 ms apart, in seat order from the dealer\'s left. Any tap skips to the end. Yours flip and fan together.' },
      { at: B, text: 'Bidding, each ≤ 350 ms: a chip flies to the bidder, a pass fades in muted, the winner pulses once. The contract lands in the band\'s felt window.' },
      { at: R, text: 'Trump named: non-trumps rise to the discards, 50 ms apart; the refill deals in from the dealer 350 ms later, 90 ms apart.' },
      { at: K, text: 'A trick: cards toss in with up to 11° of turn; the taker\'s card is ringed and held 1.4 s; the trick collapses toward the taker.' },
      { at: P, text: 'Pause lowers the lid halfway; Main menu closes it. Reduce Motion: every flight becomes a 0.2 s crossfade.' }] }) : null);
}

function Catch5Motion() {
  const [t, setTweak] = useTweaks(window.TWEAK_DEFAULTS);
  return h(Frag, null,
    h(CompositionStage, { width: 1080, height: 1920, scenes: window.OM_SCENES, playback: window.OM_PLAYBACK, bg: '#1c1a1c' }, h(Piece, { tweaks: t })),
    h(TweaksPanel, null, h(TweakSection, { label: 'Film' }), h(TweakToggle, { label: 'Captions', value: t.captions, onChange: v => setTweak('captions', v) }), h(TweakToggle, { label: 'Ghost taps', value: t.taps, onChange: v => setTweak('taps', v) }), h(TweakSection, { label: 'Editor' }), h(TweakToggle, { label: 'Motion editor', value: t.motionEditor, onChange: v => setTweak('motionEditor', v) })));
}
window.Catch5Motion = Catch5Motion;
