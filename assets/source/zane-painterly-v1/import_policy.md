# Explicit atlas import policy — Godot 4.6.3

For this character's generated atlas only, keep:

- `compress/mode=0`: Lossless.
- `detect_3d/compress_to=0`: Disabled automatic compression switching.
- `mipmaps/generate=true`: explicit 3D distance filtering support.
- Existing non-VRAM `.ctex` destination and `vram_texture=false` metadata.

Godot's default auto-detection can rewrite a texture's import file after actual 3D use, choosing VRAM compression and platform-specific destinations. Exact 4.6.3 source confirms the callback only runs this conversion when `detect_3d/compress_to` is nonzero. The enum maps zero to Disabled. We retain mipmaps explicitly, so disabling that compression callback does not sacrifice them. [Godot 4.6.3 importer source](https://github.com/godotengine/godot/blob/4.6.3-stable/editor/import/resource_importer_texture.cpp#L117-L136).

Lossless retains source quality but uses more texture memory than VRAM-compressed formats. That is a deliberate first-pass tradeoff for one 1024² painted atlas, not a measured performance claim. [Godot 4.6 texture-import documentation](https://docs.godotengine.org/en/4.6/classes/class_resourceimportertexture.html#class-resourceimportertexture-property-compress-mode).

No global setting, PNG pixels, GLB, Blender material, mesh, rig, animation or gameplay value changes. A regression test pins this policy. Actual editor/3D-use persistence is verified separately by the integration lane.
