shader_type canvas_item;
render_mode unshaded;
uniform bool coping = false;
varying vec4 vertex_tint;
void vertex(){ vertex_tint=COLOR; }
void fragment(){
 vec2 quadrant=coping?vec2(.5,.5):vec2(0.,.5);
 vec3 paint=texture(TEXTURE,quadrant+vec2(.004)+fract(UV)*.492).rgb;
 COLOR=vec4(paint,1.)*vertex_tint;
}
