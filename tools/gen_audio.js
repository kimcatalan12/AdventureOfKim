// Generates every WAV in audio/. Run: node tools/gen_audio.js
// Replace any file in audio/ with your own sound, keeping the same name.
const fs = require('fs');
const path = require('path');
const OUT = path.join(__dirname, '..', 'audio');
const RATE = 22050;

function writeWav(name, samples) {
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((s, i) => data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, s)) * 32000), i * 2));
  const head = Buffer.alloc(44);
  head.write('RIFF', 0); head.writeUInt32LE(36 + data.length, 4); head.write('WAVEfmt ', 8);
  head.writeUInt32LE(16, 16); head.writeUInt16LE(1, 20); head.writeUInt16LE(1, 22);
  head.writeUInt32LE(RATE, 24); head.writeUInt32LE(RATE * 2, 28); head.writeUInt16LE(2, 32); head.writeUInt16LE(16, 34);
  head.write('data', 36); head.writeUInt32LE(data.length, 40);
  fs.writeFileSync(path.join(OUT, name + '.wav'), Buffer.concat([head, data]));
}

const wave = {
  square: (t) => (t % 1 < 0.5 ? 1 : -1),
  triangle: (t) => 4 * Math.abs((t % 1) - 0.5) - 1,
  sine: (t) => Math.sin(2 * Math.PI * t),
};
const hz = (midi) => 440 * Math.pow(2, (midi - 69) / 12);

function tone(out, start, seconds, freq, type, volume) {
  const from = Math.floor(start * RATE);
  const count = Math.floor(seconds * RATE);
  for (let i = 0; i < count; i++) {
    const t = i / RATE;
    const env = Math.min(1, i / 120) * Math.min(1, (count - i) / (count * 0.35));
    const index = from + i;
    if (index < out.length) out[index] += wave[type](t * freq) * volume * env;
  }
}
function sfx(name, notes, type = 'square', volume = 0.35) {
  const end = Math.max(...notes.map(n => n[0] + n[1]));
  const out = new Float32Array(Math.ceil(end * RATE));
  notes.forEach(([start, len, midi]) => tone(out, start, len, hz(midi), type, volume));
  writeWav(name, out);
}

sfx('click', [[0, 0.05, 84]], 'triangle');
sfx('pickup', [[0, 0.08, 79], [0.07, 0.14, 86]]);
sfx('correct', [[0, 0.09, 72], [0.09, 0.09, 76], [0.18, 0.2, 79]]);
sfx('wrong', [[0, 0.14, 55], [0.13, 0.26, 49]]);
sfx('hit', [[0, 0.06, 50], [0.05, 0.12, 43]]);
sfx('win', [[0, 0.12, 72], [0.12, 0.12, 76], [0.24, 0.12, 79], [0.36, 0.42, 84]]);

// Cheerful 8-bar loop: C G Am F
const BEAT = 0.27;
const chords = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]];
const melody = [76, 79, 84, 79, 74, 79, 83, 79, 72, 76, 81, 76, 72, 77, 81, 84,
  76, 79, 84, 86, 83, 79, 74, 79, 81, 84, 81, 76, 77, 76, 74, 72];
const music = new Float32Array(Math.ceil(BEAT * 4 * 8 * RATE));
for (let bar = 0; bar < 8; bar++) {
  const chord = chords[bar % 4];
  for (let beat = 0; beat < 4; beat++) {
    const start = (bar * 4 + beat) * BEAT;
    tone(music, start, BEAT * 0.9, hz(chord[0] - 12), 'triangle', 0.22);
    tone(music, start, BEAT * 0.4, hz(chord[beat % 3]), 'triangle', 0.1);
    tone(music, start, BEAT * 0.8, hz(melody[(bar * 4 + beat) % melody.length]), 'square', 0.055);
  }
}
writeWav('music', music);
console.log('Audio generated:', fs.readdirSync(OUT).filter(f => f.endsWith('.wav')).join(', '));
