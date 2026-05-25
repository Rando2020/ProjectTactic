// audio.js — synthesized SFX for The Appointed UI kit.
//
// Inspired by FFT's restrained menu palette: tactile ticks for navigation,
// a warm chime for confirms, a paper-rustle for page turns, and a sacred
// bell chord that swells under tier 4+ parchment unfurls.
//
// No audio files. Everything is built from Web Audio oscillators + noise
// + filters, so the bundle stays small and copyright-clean.

(function () {
  let ctx = null;
  let master = null;
  let muted = JSON.parse(localStorage.getItem('appointed.audio.muted') ?? 'false');

  // --- Init lazy (browsers block AudioContext before user gesture) ----
  function ensure() {
    if (ctx) return ctx;
    try {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain();
      master.gain.value = 0.6;
      // Soft master reverb tail via convolution-less feedback delay
      const dry = ctx.createGain(); dry.gain.value = 0.85;
      const wet = ctx.createGain(); wet.gain.value = 0.18;
      const delay = ctx.createDelay(0.5);
      delay.delayTime.value = 0.18;
      const feedback = ctx.createGain(); feedback.gain.value = 0.32;
      const damp = ctx.createBiquadFilter(); damp.type = 'lowpass'; damp.frequency.value = 2400;
      master.connect(dry); dry.connect(ctx.destination);
      master.connect(damp); damp.connect(delay); delay.connect(feedback); feedback.connect(delay);
      delay.connect(wet); wet.connect(ctx.destination);
    } catch (e) {
      ctx = null;
    }
    return ctx;
  }

  // --- Envelope helper -----------------------------------------------
  function env(gain, t0, peak, attack, hold, release) {
    gain.gain.setValueAtTime(0.0001, t0);
    gain.gain.exponentialRampToValueAtTime(Math.max(0.0001, peak), t0 + attack);
    gain.gain.setValueAtTime(Math.max(0.0001, peak), t0 + attack + hold);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + attack + hold + release);
  }

  function setFilter(f, opts) {
    // BiquadFilter frequency/Q/gain are AudioParams, not writable props.
    // Object.assign(f, opts) silently fails for these in production browsers
    // and throws in OfflineAudioContext — always set via .value.
    if (opts.type) f.type = opts.type;
    if (opts.frequency != null) f.frequency.value = opts.frequency;
    if (opts.Q != null) f.Q.value = opts.Q;
    if (opts.gain != null) f.gain.value = opts.gain;
  }

  function tone(freq, type, t0, peak, attack, hold, release, filter) {
    const o = ctx.createOscillator();
    o.type = type;
    o.frequency.value = freq;
    const g = ctx.createGain();
    let node = o.connect(g);
    if (filter) {
      const f = ctx.createBiquadFilter();
      setFilter(f, filter);
      g.connect(f); f.connect(master);
    } else {
      g.connect(master);
    }
    env(g, t0, peak, attack, hold, release);
    o.start(t0);
    o.stop(t0 + attack + hold + release + 0.05);
    return o;
  }

  function noiseBurst(t0, peak, attack, hold, release, filterFreq, q) {
    const buffer = ctx.createBuffer(1, ctx.sampleRate * 0.5, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    const filt = ctx.createBiquadFilter();
    setFilter(filt, { type: 'bandpass', frequency: filterFreq, Q: q });
    const g = ctx.createGain();
    src.connect(filt); filt.connect(g); g.connect(master);
    env(g, t0, peak, attack, hold, release);
    src.start(t0);
    src.stop(t0 + attack + hold + release + 0.05);
  }

  // --- The SFX vocabulary --------------------------------------------
  const SFX = {

    // tactile tick — nav button, hover (subdued)
    nav() {
      const t = ctx.currentTime;
      tone(1200, 'triangle', t, 0.08, 0.002, 0.005, 0.06, { type: 'highpass', frequency: 600 });
    },

    // warm select — party card / codex item
    select() {
      const t = ctx.currentTime;
      tone(523.25, 'sine',     t, 0.10, 0.005, 0.04, 0.18, { type: 'lowpass', frequency: 2200 });
      tone(659.25, 'triangle', t + 0.02, 0.07, 0.005, 0.04, 0.18, { type: 'lowpass', frequency: 2400 });
    },

    // confirm — sacred CTA (begin descent / begin chapter)
    confirm() {
      const t = ctx.currentTime;
      // C major triad swell, soft bell-ish
      tone(523.25, 'sine',     t,        0.14, 0.02, 0.10, 0.45, { type: 'lowpass', frequency: 3200 });
      tone(659.25, 'sine',     t + 0.03, 0.11, 0.02, 0.10, 0.45, { type: 'lowpass', frequency: 3200 });
      tone(783.99, 'sine',     t + 0.06, 0.09, 0.02, 0.10, 0.55, { type: 'lowpass', frequency: 3600 });
    },

    // cancel — soft descending blip
    cancel() {
      const t = ctx.currentTime;
      const o = ctx.createOscillator();
      o.type = 'triangle';
      o.frequency.setValueAtTime(440, t);
      o.frequency.exponentialRampToValueAtTime(220, t + 0.18);
      const g = ctx.createGain();
      o.connect(g); g.connect(master);
      env(g, t, 0.09, 0.005, 0.02, 0.18);
      o.start(t); o.stop(t + 0.22);
    },

    // page — paper rustle / location open
    page() {
      const t = ctx.currentTime;
      noiseBurst(t,        0.08, 0.005, 0.02, 0.18, 1800, 1.4);
      noiseBurst(t + 0.04, 0.05, 0.005, 0.02, 0.14, 2600, 1.8);
    },

    // sacred — sustained bell chord for parchment unfurl (tier 4+)
    // Major-7 voicing: E G# B D — open, suspended, sacred.
    sacred() {
      const t = ctx.currentTime;
      const partials = [
        [329.63, 0, 0.12, 0.04, 0.30, 1.20],   // E4
        [415.30, 0.06, 0.10, 0.04, 0.30, 1.20], // G#4
        [493.88, 0.12, 0.10, 0.04, 0.40, 1.30], // B4
        [587.33, 0.20, 0.08, 0.04, 0.50, 1.40], // D5  (the 7th — gives the suspension)
        [987.77, 0.30, 0.04, 0.02, 0.30, 1.20], // B5 (bell shimmer)
      ];
      for (const [f, dt, peak, atk, hold, rel] of partials) {
        tone(f, 'sine', t + dt, peak, atk, hold, rel, { type: 'lowpass', frequency: 3000 });
      }
    },

    // tick — tactical battle click / command select
    tick() {
      const t = ctx.currentTime;
      noiseBurst(t, 0.10, 0.002, 0.004, 0.04, 2400, 5);
    },

    // crack — tier shift moment (when player advances tier)
    crack() {
      const t = ctx.currentTime;
      noiseBurst(t, 0.12, 0.002, 0.005, 0.35, 600, 2);
      tone(146.83, 'sawtooth', t, 0.08, 0.005, 0.10, 0.40, { type: 'lowpass', frequency: 800 });
    },
  };

  // --- Public API ----------------------------------------------------
  // Exposed as window.Sfx so we don't collide with the built-in
  // window.Audio constructor.
  const Sfx = {
    play(name) {
      if (muted) return;
      ensure();
      if (!ctx) return;
      if (ctx.state === 'suspended') ctx.resume();
      const fn = SFX[name];
      if (fn) try { fn(); } catch (e) { /* swallow */ }
    },
    setMuted(v) {
      muted = !!v;
      localStorage.setItem('appointed.audio.muted', JSON.stringify(muted));
    },
    isMuted() { return muted; },
  };

  window.Sfx = Sfx;
})();
