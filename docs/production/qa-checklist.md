# QA Checklist

## Local boot

- `npm install` completes.
- `npm run dev` starts Vite.
- Browser opens at `http://localhost:5173`.
- No missing module errors appear in console.
- Main battle screen renders.

## Battle flow

- Party units render with HP, MP, Temper, Ether, and Limit gauge.
- Enemy units render with HP, Temper, Ether, and statuses.
- Player actions can target valid enemies or allies.
- SURGE prompt appears during attacks/spells.
- DEFLECT prompt appears during enemy attacks.
- Damage numbers and combat log update.
- KO and victory states resolve.

## Systems smoke checks

- Temper reduces physical status pressure.
- Ether reduces magical status pressure.
- Wet plus Ice can trigger Freeze.
- Wet plus Thunder can trigger Electrify.
- Frozen plus Thunder can trigger Shatter.
- Guardian resonance window appears at the intended threshold.
- Limit Break gauge fills when characters take damage.

## Build

- `npm run build` completes.
- `dist/` is generated.
- `npm run preview` serves the built game.
