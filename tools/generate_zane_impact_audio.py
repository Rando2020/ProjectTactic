#!/usr/bin/env python3
"""Author the original Zane impact pack with deterministic, local synthesis.

Python standard library only. No input audio files, network, combat RNG, or
runtime dependency. The named layers are physical sound-design analogues, not
claims of field recording: all pressure, friction and modes are synthesized.
"""
from array import array
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import wave

RATE = 48000
ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / 'godot/assets/audio/zane_impact_v1'
# duration, runtime gain, independent noise seed, source peak dBFS
CUES = {
    'step_a': (0.148, -10.0, 0x5A1E1101, -5.2),
    'step_b': (0.156, -10.0, 0x5A1E1102, -5.2),
    'sword_load': (0.172, -12.0, 0x5A1E2201, -5.8),
    'sword_release': (0.176, -7.0, 0x5A1E2202, -4.8),
    'sword_hit': (0.270, -5.0, 0x5A1E2203, -4.5),
    'fire_charge': (0.196, -10.0, 0x5A1E3301, -5.2),
    'fire_release': (0.250, -5.0, 0x5A1E3302, -4.5),
    'fire_hit': (0.460, -5.0, 0x5A1E3303, -4.5),
    'fire_miss': (0.248, -12.0, 0x5A1E3304, -5.8),
    'fire_immune': (0.268, -11.0, 0x5A1E3305, -5.8),
}


class Noise:
    """Specified xorshift32, so the stream does not depend on random versions."""
    def __init__(self, seed):
        self.state = seed

    def unit(self):
        value = self.state
        value ^= (value << 13) & 0xFFFFFFFF
        value ^= value >> 17
        value ^= (value << 5) & 0xFFFFFFFF
        self.state = value & 0xFFFFFFFF
        return self.state / 4294967296.0

    def samples(self, count):
        return [2.0 * self.unit() - 1.0 for _ in range(count)]


def lowpass(source, hz):
    alpha = 1.0 - math.exp(-2.0 * math.pi * hz / RATE)
    state = 0.0
    result = []
    for value in source:
        state += alpha * (value - state)
        result.append(state)
    return result


def band(source, lo, hi):
    high = lowpass(source, hi)
    low = lowpass(source, lo)
    return [h - l for h, l in zip(high, low)]


def env(time, attack, decay):
    if time < 0.0:
        return 0.0
    return (1.0 - math.exp(-time / attack)) * math.exp(-time / decay)


def modal(time, modes, decay, bend=0.0):
    """Short inharmonic resonances; bend is a decaying pressure displacement."""
    if time < 0.0:
        return 0.0
    return sum(amplitude * math.sin(2 * math.pi * (hz * time + bend * (1.0 - math.exp(-time / 0.022))) + phase)
               * math.exp(-time / (decay / (1.0 + index * 0.35)))
               for index, (hz, amplitude, phase) in enumerate(modes))


def grains(rng, count, events, lo, hi, span, length):
    """Seeded tiny noise contacts: uneven grit, leather rub or ember ticks."""
    result = [0.0] * count
    for _ in range(events):
        start = int(rng.unit() * span * RATE)
        size = max(12, int((0.35 + rng.unit()) * length * RATE))
        texture = band(rng.samples(size), lo, hi)
        amplitude = 0.25 + 0.75 * rng.unit()
        for j, value in enumerate(texture):
            if start + j >= count:
                break
            window = math.sin(math.pi * j / max(1, size - 1)) ** 2
            result[start + j] += value * amplitude * window
    return result


def synthesize(cue_id):
    duration, _, seed, peak_db = CUES[cue_id]
    count = round(duration * RATE)
    rng = Noise(seed)
    noise = rng.samples(count)
    air = band(noise, 850.0, 7200.0)
    warm = band(noise, 90.0, 1250.0)
    friction = band(noise, 450.0, 2600.0)
    result = []
    if cue_id.startswith('step_'):
        alternate = cue_id == 'step_b'
        grit = grains(rng, count, 17, 1900, 6500, 0.091, 0.006)
        leather = band(rng.samples(count), 270, 1200)
        for i in range(count):
            t = i / RATE
            heel = modal(t, [(91 + 8 * alternate, .69, .3), (157, .24, .9), (271, .10, .4)], .030, .20)
            sole = warm[i] * env(t - .010, .003, .028)
            creak = leather[i] * env(t - .021, .009, .038)
            # Two differently timed, textured plants, not pitch-shifted copies.
            result.append(.72 * heel * env(t, .003, .065) + 2.1 * sole + 1.9 * creak + .36 * grit[i])
    elif cue_id == 'sword_load':
        cloth = grains(rng, count, 13, 500, 3100, .118, .015)
        for i in range(count):
            t = i / RATE
            tension = math.sin(math.pi * min(1., t / duration)) ** 1.2
            steel = modal(t - .035, [(624, .10, .8), (1093, .05, .1), (2131, .025, .6)], .045)
            result.append(1.4 * friction[i] * tension * .40 + .80 * cloth[i] + steel)
    elif cue_id == 'sword_release':
        for i in range(count):
            t = i / RATE
            cut = env(t, .006, .022)
            wake = env(t - .018, .010, .038)
            # Broad air shear, a brief lower fabric/body swipe, no tonal whistle.
            result.append(3.7 * air[i] * cut + 2.5 * warm[i] * wake + .28 * friction[i] * env(t - .045, .007, .025))
    elif cue_id == 'sword_hit':
        grit = grains(rng, count, 9, 1100, 5600, .095, .006)
        for i in range(count):
            t = i / RATE
            body = modal(t, [(109, .75, .3), (186, .32, .5), (319, .11, .9)], .048, .30)
            edge = modal(t - .004, [(781, .19, .6), (1437, .11, .1), (2631, .07, .8), (3791, .03, .3)], .046)
            result.append(body * env(t, .002, .105) + edge * env(t - .004, .002, .080) + 2.9 * warm[i] * env(t, .002, .032) + .37 * grit[i])
    elif cue_id == 'fire_charge':
        ember = grains(rng, count, 12, 1600, 5800, .180, .008)
        pressure = lowpass(rng.samples(count), 40)
        for i in range(count):
            t = i / RATE
            rise = (t / duration) ** .80
            rough = .68 + 1.3 * abs(pressure[i])
            # Noise dominates two bent cavity modes: compressed breath, not a beep.
            cavity = modal(t, [(119, .28, .6), (207, .13, .9)], .4, -1.2)
            result.append(3.0 * warm[i] * rise * rough + .36 * air[i] * rise + .32 * cavity * rise + .40 * ember[i] * rise)
    elif cue_id == 'fire_release':
        ember = grains(rng, count, 15, 1300, 6500, .175, .007)
        for i in range(count):
            t = i / RATE
            breath = env(t, .010, .045)
            pressure = modal(t, [(104, .55, .2), (179, .20, .8), (293, .10, .4)], .057, .85)
            ignition = friction[i] * env(t - .009, .004, .024)
            result.append(3.6 * warm[i] * breath + 1.6 * air[i] * env(t, .008, .032) + .50 * pressure * env(t, .008, .14) + .85 * ignition + .37 * ember[i])
    elif cue_id == 'fire_hit':
        ember = grains(rng, count, 30, 1300, 6500, .340, .008)
        for i in range(count):
            t = i / RATE
            body = modal(t, [(93, .77, .3), (147, .36, .9), (229, .17, .5), (367, .05, .1)], .075, .70)
            flare = 3.3 * warm[i] * env(t, .007, .055)
            crack = 1.5 * friction[i] * env(t - .010, .003, .027)
            tail = .70 * air[i] * env(t - .038, .018, .075)
            result.append(.85 * body * env(t, .005, .16) + flare + crack + tail + .48 * ember[i] * math.exp(-t / .17))
    elif cue_id == 'fire_miss':
        ember = grains(rng, count, 8, 1900, 7000, .140, .009)
        for i in range(count):
            t = i / RATE
            result.append(2.2 * air[i] * env(t, .012, .047) + 1.7 * warm[i] * env(t, .012, .035) + .24 * ember[i] * math.exp(-t / .07))
    elif cue_id == 'fire_immune':
        shards = grains(rng, count, 16, 2100, 6800, .125, .008)
        for i in range(count):
            t = i / RATE
            brittle = modal(t, [(917, .12, .9), (1673, .10, .1), (2879, .05, .4)], .029)
            result.append(1.9 * friction[i] * env(t, .005, .034) + .68 * shards[i] * math.exp(-t / .085) + brittle * env(t, .003, .080) + .65 * air[i] * env(t - .035, .010, .040))
    else:
        raise ValueError(f'Unknown cue {cue_id}')

    # Mild body compression before a true fade and explicit DC removal.
    result = [math.tanh(1.35 * x) for x in result]
    window = [min(1.0, (1.0 - math.cos(math.pi * min(1.0, i / (RATE * .012)))) / 2.0)
              * min(1.0, (1.0 - math.cos(math.pi * min(1.0, (count - 1 - i) / (RATE * .020)))) / 2.0)
              for i in range(count)]
    result = [value * fade for value, fade in zip(result, window)]
    dc = sum(result) / sum(window)
    result = [value - dc * fade for value, fade in zip(result, window)]
    gain = 10 ** (peak_db / 20) / max(map(abs, result))
    return [value * gain for value in result]


def write_wav(path, samples):
    pcm = array('h', (round(max(-1., min(1., value)) * 32767) for value in samples))
    if sys.byteorder != 'little':
        pcm.byteswap()
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
        wav.writeframes(pcm.tobytes())


def write_previews(directory, sources):
    """Review-only source pack demos, never a recording of in-game behavior."""
    directory.mkdir(parents=True, exist_ok=True)
    events = [{'cue_id': 'fire_charge', 'start_s': .3},
              {'cue_id': 'fire_release', 'start_s': .5},
              {'cue_id': 'fire_hit', 'start_s': .72}]
    mix = [0.0] * int(RATE * 1.5)
    for event in events:
        cue_id = event['cue_id']
        start = round(event['start_s'] * RATE)
        gain = 10 ** (CUES[cue_id][1] / 20)
        for i, value in enumerate(sources[cue_id]):
            mix[start + i] += value * gain
    write_wav(directory / 'fire-sequence.wav', mix)
    # Every source cue, unity gain, separated by 350 ms of silence.
    audition = [0.0] * int(.3 * RATE)
    cue_times = []
    for cue_id, source in sources.items():
        cue_times.append({'cue_id': cue_id, 'start_s': len(audition) / RATE})
        audition.extend(source)
        audition.extend([0.0] * int(.35 * RATE))
    write_wav(directory / 'cue-audition.wav', audition)
    metadata = {'description': 'Synthetic source-only preview; not gameplay capture. One Fire action, three hypothetical recipients, exactly one outcome tail. Manifest gains applied to Fire sequence; cue audition is source unity gain.',
                'fire_recipient_count': 3, 'fire_sequence': events, 'cue_audition': cue_times}
    (directory / 'preview-events.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')


def generate(output, preview=None):
    output.mkdir(parents=True, exist_ok=True)
    manifest = {'schema_version': 1, 'profile_id': 'zane_impact_v1', 'cues': {}}
    sources = {}
    for cue_id, (duration, gain_db, _, _) in CUES.items():
        source = synthesize(cue_id)
        sources[cue_id] = source
        name = cue_id.replace('_', '-') + '.wav'
        path = output / name
        write_wav(path, source)
        manifest['cues'][cue_id] = {'path': f'res://assets/audio/zane_impact_v1/{name}',
                                    'gain_db': gain_db, 'duration_s': len(source) / RATE,
                                    'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    if preview is not None:
        write_previews(preview, sources)
    print(f'Generated {len(sources)} original cues; {sum(p.stat().st_size for p in output.glob("*.wav"))} WAV bytes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--preview-dir', type=Path, help='Optional review WAVs outside the runtime pack; no legacy source audio')
    args = parser.parse_args()
    generate(args.output_dir, args.preview_dir)


if __name__ == '__main__':
    main()
