// Generates every SVG in art/. Run: node tools/gen_art.js
// You can also ignore this script and edit or replace any file in art/ by hand,
// as long as the file name stays the same.
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, '..', 'art');

const P = {
  h: '#5b3a29', H: '#7a5236', s: '#f6c9a0', S: '#e0a97c', k: '#2a2438', m: '#c96a5a',
  t: '#1fb5a6', T: '#158a80', y: '#ffd166', d: '#31406e', D: '#253158', w: '#f7f7f2', W: '#c9c9c0',
  o: '#f28c38', O: '#c96d22', g: '#dfe6f2', b: '#1d1a2b', n: '#6d4c8f', N: '#4f3570', p: '#ff9fb2',
  r: '#e4484d', R: '#a92f3a', c: '#fff4d6', e: '#9aa3b5', E: '#6f788c', a: '#f5b82e', A: '#d18f16', l: '#ffe9a8',
  v: '#8a5cd1', V: '#6a42a8', u: '#55c271', U: '#3a9a54', x: '#b98a5e', X: '#94683f', z: '#7b5335', i: '#4aa8e8',
};

function pixels(rows, unit = 3) {
  const w = Math.max(...rows.map(r => r.length));
  let rects = '';
  rows.forEach((row, y) => {
    [...row].forEach((ch, x) => {
      if (ch === '.') return;
      if (!P[ch]) throw new Error('Unknown colour ' + ch);
      rects += `<rect x="${x * unit}" y="${y * unit}" width="${unit}" height="${unit}" fill="${P[ch]}"/>`;
    });
  });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w * unit}" height="${rows.length * unit}" viewBox="0 0 ${w * unit} ${rows.length * unit}" shape-rendering="crispEdges">${rects}</svg>\n`;
}
function save(name, svg) { fs.writeFileSync(path.join(OUT, name + '.svg'), svg); }
function sprite(name, rows, unit) { save(name, pixels(rows, unit)); }

// ---------- Kim ----------
const kimFront = [
  '....hhhhhhhh....',
  '...hHHHHHHHHh...',
  '..hHhhhhhhhhHh..',
  '..hhsssssssshh..',
  '..hssssssssssh..',
  '..ssskssssksss..',
  '..ssskssssksss..',
  '..ssssssssssss..',
  '...sssmmmmsss...',
  '....ssssssss....',
];
const kimBack = [
  '....hhhhhhhh....',
  '...hHHHHHHHHh...',
  '..hHhhhhhhhhHh..',
  '..hhhhhhhhhhhh..',
  '..hhhHHHHHHhhh..',
  '..hhhhhhhhhhhh..',
  '..hhhhhhhhhhhh..',
  '..shhhhhhhhhhs..',
  '...ssssssssss...',
  '....ssssssss....',
];
const kimSide = [
  '....hhhhhhhh....',
  '...hHHHHHHHHh...',
  '..hHhhhhhhhhHh..',
  '..hhhhsssssss...',
  '..hhhsssssssss..',
  '..hhssssssksss..',
  '..hhssssssksss..',
  '..hsssssssssss..',
  '...sssssssmmm...',
  '....ssssssss....',
];
const bodyFront = [
  '....tttttttt....',
  '..tttttttttttt..',
  '.sTttttyyttttTs.',
  '.sTttttyyttttTs.',
  '.sTttttttttttTs.',
  '..sTTTTTTTTTTs..',
];
const bodyBack = [
  '....tttttttt....',
  '..tttttttttttt..',
  '.sTttttttttttTs.',
  '.sTttttttttttTs.',
  '.sTttttttttttTs.',
  '..sTTTTTTTTTTs..',
];
const bodySide = [
  '.....tttttt.....',
  '....tttttttt....',
  '....ttttTttt....',
  '....ttttTttt....',
  '....tttsTttt....',
  '.....TTTTTT.....',
];
const legs = {
  frontA: ['...dddddddddd...', '...dddd..dddd...', '...ddd....ddd...', '...ddd....ddd...', '...www....www...'],
  frontB: ['...dddddddddd...', '...dddd..dddd...', '...ddd....ddd...', '...www....ddd...', '..........www...'],
  frontC: ['...dddddddddd...', '...dddd..dddd...', '...ddd....ddd...', '...ddd....www...', '...www..........'],
  sideA: ['.....dddddd.....', '.....dddddd.....', '.....dddddd.....', '.....dddddd.....', '.....wwwwwww....'],
  sideB: ['.....dddddd.....', '....ddddddddd...', '...ddd....dddd..', '..www.......ddd.', '...........www..'],
};
sprite('kim_down_1', [...kimFront, ...bodyFront, ...legs.frontA]);
sprite('kim_down_2', [...kimFront, ...bodyFront, ...legs.frontB]);
sprite('kim_down_3', [...kimFront, ...bodyFront, ...legs.frontC]);
sprite('kim_up_1', [...kimBack, ...bodyBack, ...legs.frontA]);
sprite('kim_up_2', [...kimBack, ...bodyBack, ...legs.frontB]);
sprite('kim_up_3', [...kimBack, ...bodyBack, ...legs.frontC]);
sprite('kim_side_1', [...kimSide, ...bodySide, ...legs.sideA]);
sprite('kim_side_2', [...kimSide, ...bodySide, ...legs.sideB]);

// ---------- Vince ----------
sprite('vince', [
  '....bbbbbbbb....',
  '...bbbbbbbbbb...',
  '..bbbbbbbbbbbb..',
  '..bbSSSSSSSSbb..',
  '..bSSSSSSSSSSb..',
  '..SkkkkSSkkkkS..',
  '..SkgkSSSSkgkS..',
  '..SSSSSSSSSSSS..',
  '...SSSmmmmSSS...',
  '....SSSSSSSS....',
  '....oowwwwoo....',
  '..oooowwwwoooo..',
  '.SOoooowwooooOS.',
  '.SOoooowwooooOS.',
  '.SOoooooooooOOS.',
  '..SOOOOOOOOOOS..',
  '...dddddddddd...',
  '...dddd..dddd...',
  '...ddd....ddd...',
  '...ddd....ddd...',
  '...www....www...',
]);

// ---------- Enemies ----------
sprite('rabbit_1', [
  '...ww....ww.....',
  '...wp....pw.....',
  '...wp....pw.....',
  '...ww....ww.....',
  '..wwwwwwwwww....',
  '.wwkwwwwwwkww...',
  '.wwwwwppwwwwww..',
  '..wwwwwwwwwwwWW.',
  '..WwwwwwwwwwwWWw',
  '..WwwwwwwwwwwWWw',
  '...WW......WW...',
]);
sprite('rabbit_2', [
  '................',
  '..ww......ww....',
  '...wp....pw.....',
  '...wp....pw.....',
  '..wwwwwwwwww....',
  '.wwkwwwwwwkww...',
  '.wwwwwppwwwwww..',
  '..wwwwwwwwwwwWW.',
  '.WwwwwwwwwwwwwWw',
  'WW............WW',
  '................',
]);
sprite('bat_1', [
  '...n........n...',
  '..nnn.nNNn.nnn..',
  '.nnnnnNNNNnnnnn.',
  'nnnnNNrNNrNNnnnn',
  'nnn.NNNNNNNN.nnn',
  'n....NwNNwN....n',
  '......NNNN......',
]);
sprite('bat_2', [
  '................',
  '......nNNn......',
  '.....nNNNNn.....',
  '..nnNNrNNrNNnn..',
  '.nnnnNNNNNNnnnn.',
  'nnn..NwNNwN..nnn',
  'n.....NNNN.....n',
]);

// ---------- Collectibles and icons ----------
sprite('book', [
  '................',
  '..rrrrrrrrrrrr..',
  '.rRyyrrrrrrrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRrrryyyyyrrrr.',
  '.rRrrryyyyyrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRrrrrrrrrrrrr.',
  '.rRccccccccccccR',
  '.rRcWWWWWWWWWWcR',
  '..RRRRRRRRRRRRR.',
  '................',
  '................',
]);
sprite('pencil', [
  '................',
  '............pp..',
  '...........pppp.',
  '..........ggppp.',
  '.........aagggp.',
  '........aaaagg..',
  '.......aaaAAa...',
  '......aaaAAa....',
  '.....aaaAAa.....',
  '....aaaAAa......',
  '...aaaAAa.......',
  '..xxaAAa........',
  '..xxxAa.........',
  '..bxxx..........',
  '..bb............',
  '................',
]);
sprite('heart', [
  '................',
  '...rrr....rrr...',
  '..rrrrr..rrrrr..',
  '.rrcrrrrrrrrrrr.',
  '.rcrrrrrrrrrrrr.',
  '.rrrrrrrrrrrrRr.',
  '.rrrrrrrrrrrRRr.',
  '..rrrrrrrrrRRr..',
  '...rrrrrrrRRr...',
  '....rrrrrRRr....',
  '.....rrrRRr.....',
  '......rRRr......',
  '.......Rr.......',
  '................',
  '................',
  '................',
]);
sprite('heart_empty', [
  '................',
  '...EEE....EEE...',
  '..E...E..E...E..',
  '.E.....EE.....E.',
  '.E............E.',
  '.E............E.',
  '.E............E.',
  '..E..........E..',
  '...E........E...',
  '....E......E....',
  '.....E....E.....',
  '......E..E......',
  '.......EE.......',
  '................',
  '................',
  '................',
]);
sprite('star', [
  '................',
  '.......aa.......',
  '.......aa.......',
  '......alla......',
  '......alla......',
  'aaaaaaallaaaaaaa',
  '.aallllllllllaa.',
  '..aallllllllaa..',
  '...aallllllaa...',
  '...aallllllaa...',
  '..aalllaalllaa..',
  '..aallaaaallaa..',
  '.aaaaa....aaaaa.',
  '.aa..........aa.',
  '................',
  '................',
]);

// ---------- Map tiles ----------
function tile(base, accent, spots) {
  const rows = Array.from({ length: 16 }, () => Array(16).fill(base));
  spots.forEach(([x, y]) => { rows[y][x] = accent; });
  return rows.map(r => r.join(''));
}
const line = (y) => Array.from({ length: 16 }, (_, x) => [x, y]);
sprite('floor_wood', tile('x', 'X', [...line(7), ...line(15), [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [11, 8], [11, 9], [11, 10], [11, 11], [11, 12], [11, 13], [11, 14]]));
sprite('floor_stone', tile('e', 'E', [...line(15), [15, 0], [15, 1], [15, 2], [15, 3], [15, 4], [15, 5], [15, 6], [15, 7], [15, 8], [15, 9], [15, 10], [15, 11], [15, 12], [15, 13], [15, 14], [5, 4], [6, 4], [10, 10], [11, 10]]));
sprite('floor_grass', tile('u', 'U', [[2, 3], [3, 2], [9, 5], [10, 4], [5, 11], [6, 10], [13, 12], [12, 13], [14, 2]]));
sprite('wall_library', [
  'zzzzzzzzzzzzzzzz', 'zXXXXXXXXXXXXXXz', 'zXzzzzzzzzzzzzXz', 'zXzrriiyyuuppzXz', 'zXzrriiyyuuppzXz',
  'zXzrriiyyuuppzXz', 'zXzzzzzzzzzzzzXz', 'zXXXXXXXXXXXXXXz', 'zXzzzzzzzzzzzzXz', 'zXzyyuurriippzXz',
  'zXzyyuurriippzXz', 'zXzyyuurriippzXz', 'zXzzzzzzzzzzzzXz', 'zXXXXXXXXXXXXXXz', 'zzzzzzzzzzzzzzzz', 'zzzzzzzzzzzzzzzz',
]);
sprite('wall_stone', [
  'EEEEEEEEEEEEEEEE', 'EggggggEEggggggE', 'EggggggEEggggggE', 'EgeeeeeEEgeeeeeE', 'EEEEEEEEEEEEEEEE', 'gggEEggggggEEggg',
  'gggEEggggggEEggg', 'eeeEEgeeeeeEEgee', 'EEEEEEEEEEEEEEEE', 'EggggggEEggggggE', 'EggggggEEggggggE', 'EgeeeeeEEgeeeeeE',
  'EEEEEEEEEEEEEEEE', 'gggEEggggggEEggg', 'gggEEggggggEEggg', 'EEEEEEEEEEEEEEEE',
]);
sprite('wall_hedge', [
  '.UUUUuuUUUUuuUU.', 'UUuuuuuuuuuuuuUU', 'UuuuUuuuuuUuuuuU', 'UuuuuuuUuuuuuuuU', 'UUuuuuuuuuuuuuUU', 'UuuUuuuuuuuuUuuU',
  'UuuuuuuuUuuuuuuU', 'UUuuuuuuuuuuuuUU', 'UuuuuUuuuuuuuuuU', 'UuuuuuuuuuUuuuuU', 'UUuuuuuuuuuuuuUU', 'UuuuUuuuuuuUuuuU',
  'UUuuuuuuuuuuuuUU', 'zUUUUUUUUUUUUUUz', 'zzzzzzzzzzzzzzzz', '.zzzzzzzzzzzzzz.',
]);
sprite('table', [
  '................', '................', '.XXXXXXXXXXXXXX.', 'XxxxxxxxxxxxxxxX', 'XxxxxxxxxxxxxxxX', 'XxxxxxgggxxxxxxX',
  'XxxxxxgggxxxxxxX', 'XxxxxxxxxxxxxxxX', 'XxxxxxxxxxxxxxxX', 'XXXXXXXXXXXXXXXX', 'zzzzzzzzzzzzzzzz', '.zz..........zz.',
  '.zz..........zz.', '.zz..........zz.', '.zz..........zz.', '................',
]);
sprite('crate', [
  'zzzzzzzzzzzzzzzz', 'zxxxxxxxxxxxxxxz', 'zxXxxxxxxxxxxXxz', 'zxxXxxxxxxxxXxxz', 'zxxxXxxxxxxXxxxz', 'zxxxxXxxxxXxxxxz',
  'zxxxxxXxxXxxxxxz', 'zxxxxxxXXxxxxxxz', 'zxxxxxxXXxxxxxxz', 'zxxxxxXxxXxxxxxz', 'zxxxxXxxxxXxxxxz', 'zxxxXxxxxxxXxxxz',
  'zxxXxxxxxxxxXxxz', 'zxXxxxxxxxxxxXxz', 'zxxxxxxxxxxxxxxz', 'zzzzzzzzzzzzzzzz',
]);
sprite('tree', [
  '.....UUUUUU.....', '...UUuuuuuuUU...', '..UuuuuuuuuuuuU.', '.UuuuuUuuuuuuuuU', '.UuuuuuuuuuUuuuU', 'UuuUuuuuuuuuuuuU',
  'UuuuuuuuUuuuuuuU', 'UuuuuuuuuuuuUuuU', '.UuuuUuuuuuuuuU.', '.UUuuuuuuuuuuUU.', '...UUUuuuuUUU...', '......zzzz......',
  '......zXXz......', '......zXXz......', '.....zzzzzz.....', '................',
]);

// ---------- Vector pictures ----------
function school() {
  const windows = [];
  for (let row = 0; row < 3; row++) for (let col = 0; col < 8; col++) {
    if (col === 3 || col === 4) { if (row === 2) continue; }
    windows.push(`<rect x="${258 + col * 58}" y="${176 + row * 52}" width="36" height="34" rx="3" fill="#8fd8f2"/><rect x="${258 + col * 58}" y="${176 + row * 52}" width="36" height="9" fill="#d8f3fb"/>`);
  }
  const clouds = [[120, 80, 1], [760, 60, 1.25], [460, 44, 0.8]].map(([x, y, s]) =>
    `<g transform="translate(${x} ${y}) scale(${s})" fill="#fff" opacity=".9"><ellipse cx="0" cy="0" rx="48" ry="19"/><ellipse cx="-22" cy="-10" rx="24" ry="18"/><ellipse cx="20" cy="-14" rx="28" ry="23"/></g>`).join('');
  const tree = (x, s) => `<g transform="translate(${x} 410) scale(${s})"><rect x="-10" y="-20" width="20" height="62" fill="#7b5335"/><circle cx="0" cy="-58" r="58" fill="#3a9a54"/><circle cx="-36" cy="-30" r="38" fill="#55c271"/><circle cx="34" cy="-34" r="40" fill="#46b064"/></g>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540" viewBox="0 0 960 540">
<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3bb3e6"/><stop offset="1" stop-color="#c7f0ef"/></linearGradient></defs>
<rect width="960" height="540" fill="url(#sky)"/>${clouds}
<rect x="236" y="150" width="488" height="256" fill="#fff4d6"/><rect x="236" y="150" width="488" height="16" fill="#f28c38"/>
<polygon points="400,150 480,86 560,150" fill="#e4484d"/><circle cx="480" cy="124" r="15" fill="#fff4d6"/>
<text x="480" y="130" font-family="sans-serif" font-size="18" font-weight="bold" text-anchor="middle" fill="#2a2438">½</text>
${windows.join('')}
<rect x="440" y="310" width="80" height="96" rx="4" fill="#31406e"/><rect x="478" y="310" width="4" height="96" fill="#1d1a2b"/>
<rect y="400" width="960" height="140" fill="#55c271"/><polygon points="430,400 530,400 640,540 320,540" fill="#f1dfb8"/>
${tree(120, 1)}${tree(842, 1.1)}${tree(40, .7)}${tree(930, .65)}
</svg>\n`;
}
save('bg_school', school());

function classroom() {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540" viewBox="0 0 960 540">
<rect width="960" height="540" fill="#ffe7b8"/><rect y="400" width="960" height="140" fill="#b98a5e"/><rect y="394" width="960" height="8" fill="#7b5335"/>
<rect x="210" y="60" width="540" height="250" rx="8" fill="#7b5335"/><rect x="224" y="74" width="512" height="222" fill="#22574f"/>
<g font-family="sans-serif" font-size="34" fill="#f7f7f2" opacity=".85"><text x="260" y="130">0.5 = ½</text><text x="510" y="130">¾ = 0.75</text><text x="260" y="210">0.25 + 0.5</text><text x="520" y="210">⅓ + ⅓</text><text x="300" y="272" font-size="24">Math Club — Math Month!</text></g>
<rect x="60" y="110" width="106" height="130" fill="#8fd8f2" stroke="#fff4d6" stroke-width="8"/><rect x="794" y="110" width="106" height="130" fill="#8fd8f2" stroke="#fff4d6" stroke-width="8"/>
</svg>\n`;
}
save('bg_classroom', classroom());

save('certificate', `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="440" viewBox="0 0 720 440">
<rect width="720" height="440" rx="10" fill="#fff4d6"/><rect x="14" y="14" width="692" height="412" rx="6" fill="none" stroke="#d18f16" stroke-width="8"/><rect x="28" y="28" width="664" height="384" rx="4" fill="none" stroke="#f5b82e" stroke-width="2"/>
<circle cx="618" cy="346" r="42" fill="#e4484d"/><circle cx="618" cy="346" r="30" fill="#ffd166"/><polygon points="600,384 590,420 618,402 646,420 636,384" fill="#e4484d"/>
</svg>\n`);

save('icon', `<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="24" fill="#1fb5a6"/><text x="64" y="58" font-family="sans-serif" font-size="46" font-weight="bold" text-anchor="middle" fill="#fff4d6">½</text><text x="64" y="108" font-family="sans-serif" font-size="40" font-weight="bold" text-anchor="middle" fill="#ffd166">0.5</text></svg>\n`);

console.log('Art generated:', fs.readdirSync(OUT).filter(f => f.endsWith('.svg')).length, 'files');
