#!/usr/bin/env python3
"""Stage an opt-in skill review project. Never edit a production project."""
import argparse
import hashlib
from pathlib import Path
import shutil

KIT = Path(__file__).resolve().parent
ROOT = KIT.parents[1]
SOURCE = ROOT / 'demos/isometric-2v2'
ART = ROOT / 'assets/source/haste-aura-candidate-2026-11-04/art/haste-application-aura-candidate.png'
ART_SHA = '3812f27c4f55e4217e22e31ea545896d68e28a8327ad0bd00aecc46e93f14235'


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f'Source contract changed; review before staging: {old}')
    return text.replace(old, new)


def stage(destination):
    destination = Path(destination).resolve()
    for input_root in (SOURCE, KIT):
        if destination == input_root or input_root in destination.parents or destination in input_root.parents:
            raise ValueError('Candidate must be separate from production and candidate inputs')
    if destination.exists():
        raise FileExistsError(f'Refusing to overwrite existing destination: {destination}')
    if hashlib.sha256(ART.read_bytes()).hexdigest() != ART_SHA:
        raise ValueError('Haste source hash changed; review required')
    project = (SOURCE / 'project.godot').read_text()
    project = replace_once(project, 'run/main_scene="res://prototypes/isometric/Skirmish.tscn"', 'run/main_scene="res://prototypes/blooming/BloomingBattle.tscn"')
    project = replace_once(project, 'config/custom_user_dir_name="ProjectTactic-IsometricProof"', 'config/custom_user_dir_name="ProjectTactic-HasteCandidate-20261110"')
    project = replace_once(project, 'VFX="*res://scripts/vfx/VFXManager.gd"', 'VFX="*res://candidate_skills/HasteVFX.gd"')
    scene = replace_once((SOURCE / 'prototypes/blooming/BloomingBattle.tscn').read_text(), 'res://prototypes/blooming/BloomingBattle.gd', 'res://candidate_skills/SkillBattle.gd')
    shutil.copytree(SOURCE, destination, ignore=shutil.ignore_patterns('.godot', '.git', 'build', 'exports', '__pycache__'))
    shutil.copytree(KIT / 'runtime', destination / 'candidate_skills')
    shutil.copytree(KIT / 'tests', destination / 'candidate_skills/tests', ignore=shutil.ignore_patterns('__pycache__', '*.py'))
    shutil.copyfile(ART, destination / 'candidate_skills/haste-aura.png')
    (destination / 'project.godot').write_text(project)
    (destination / 'prototypes/blooming/BloomingBattle.tscn').write_text(scene)
    return destination

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    print(stage(parser.parse_args().destination))
