# Ashvale 3D Runtime Kit

This folder contains the first checked-in modular 3D environment kit for ProjectTactic.

## Runtime contract

- One tactical tile is `2m x 2m`.
- One elevation step is `1m`.
- Godot uses Y-up meshes.
- Runtime prototype meshes are text `.obj` files with one shared `ashvale-materials.mtl` palette.
- The tactical grid remains authoritative for movement, height, collision, targeting, and combat rules. These meshes are presentation assets unless a later system explicitly maps them to tactical data.

## Art source

`source-art/blender/generate_ashvale_kit.py` is the canonical procedural source for the kit. A local Blender art pass may regenerate/refine the pieces and export `.glb` assets after visual acceptance. The checked-in OBJ format is deliberately used for the current prototype because it is small, diff-safe, connector-safe, and reliable in CI without Git LFS binary upload handling.

## First authored scene

`res://scenes/dev/Ashvale3DBattleMock.tscn` is the first hybrid presentation target. It composes these meshes with existing isometric unit sprites, orthographic lighting, elevation, and tactical selection/range markers.

## Quality bar

Do not expand into dozens of new environments until the Ashvale mock is readable and attractive in a browser build. The acceptance target is a battlefield screenshot we would be comfortable showing publicly as a game-in-development image.
