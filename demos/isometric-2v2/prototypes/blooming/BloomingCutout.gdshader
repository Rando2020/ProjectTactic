shader_type canvas_item;
// Source manifest alpha_cutoff: 0.5. Test source alpha, not unit-occlusion fade.
void fragment() {
 if (texture(TEXTURE, UV).a < 0.5) discard;
}
