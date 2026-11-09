#!/usr/bin/env python3
"""Copy the standalone demo to a new directory and opt into candidate actors there."""
import argparse, json, hashlib, shutil
from pathlib import Path
parser=argparse.ArgumentParser()
parser.add_argument('destination',type=Path)
a=parser.parse_args()
source=Path(__file__).resolve().parents[2]
dest=a.destination.resolve()
if dest.exists(): raise SystemExit('Destination must not exist; no existing project is overwritten.')
if source==dest or source in dest.parents: raise SystemExit('Stage outside the source project.')
fixtures=source/'tests/candidate_assets'
for row in json.loads((fixtures/'source-hashes.json').read_text()):
 path=fixtures/'sources'/row['role']/Path(row['file']).name
 if hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']: raise SystemExit('Source hash mismatch: '+str(path))
shutil.copytree(source,dest,ignore=shutil.ignore_patterns('.godot','*.import','__pycache__'))
p=dest/'prototypes/isometric/Unit.tscn'
s=p.read_text()
old='res://prototypes/isometric/Unit.gd'
if s.count(old)!=1: raise SystemExit('Unexpected actor scene; staging refused.')
p.write_text(s.replace(old,'res://tests/candidate_assets/CandidateUnit.gd'))
# Append review-only overrides to the staged HUD instead of introducing an
# extra inheritance level (Godot rejects the inherited selection signature).
p=dest/'prototypes/blooming/BloomingHUD.gd'
s=p.read_text()
old='func _refresh_appearance_control() -> void:'
if s.count(old)!=1: raise SystemExit('Unexpected HUD appearance hook; staging refused.')
s=s.replace(old,'func _refresh_baseline_appearance_control() -> void:')
p.write_text(s+'\n'+(fixtures/'CandidateHUD.gdinc').read_text())
p=dest/'project.godot'
s=p.read_text().replace('ProjectTactic-IsometricProof','ProjectTactic-CandidateReview')
p.write_text(s)
print('Candidate review staged at',dest)
