shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform int surface = 0;
varying vec3 pos;
varying vec3 face;
void vertex(){
	pos = (MODEL_MATRIX * vec4(VERTEX,1.)).xyz;
	face = MODEL_NORMAL_MATRIX * NORMAL;
}
float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
float field(vec2 p){
	vec2 a=floor(p), b=fract(p); b=b*b*(3.-2.*b);
	return mix(mix(hash(a),hash(a+vec2(1,0)),b.x),mix(hash(a+vec2(0,1)),hash(a+1.),b.x),b.y);
}
vec3 paint(vec2 q,vec2 uv){
	return textureGrad(atlas,q+.004+fract(uv)*.492,dFdx(uv)*.492,dFdy(uv)*.492).rgb;
}
void fragment(){
	vec2 p=pos.xz;
	bool top=abs(face.y)>.5;
	vec2 side=abs(face.x)>.5?pos.zy:pos.xy;
	vec3 color;
	if(top && surface<2){
		// Stagger wide slabs, with uneven course ends and gently chipped corners.
		vec2 w=p+.075*vec2(field(p*2.),field(p*2.+31.));
		float row=floor(w.y/1.13);
		float width=1.52+.57*hash(vec2(row,3.));
		vec2 g=vec2(w.x/width+hash(vec2(row,7.)),w.y/1.13);
		vec2 id=floor(g), f=fract(g), edge=min(f,1.-f)*vec2(width,1.13);
		float seam=min(min(edge.x,edge.y),(edge.x+edge.y-(.045+.095*hash(id)))*.707);
		float seed=hash(id);
		// Use a bounded patch of the painted coping stone: no second grid of mortar.
		vec2 uv=vec2(.53,.53)+vec2(seed*.19,f.y*.085)+vec2(f.x*.21,0.);
		vec3 slab=textureGrad(atlas,uv,dFdx(p)*.045,dFdy(p)*.045).rgb;
		slab*=mix(vec3(.79,.79,.86),vec3(1.04,1.,.93),seed);
		float aa=max(.007,fwidth(seam)*.55);
		float cap=smoothstep(.009-aa,.009+aa,seam);
		color=mix(slab*vec3(.38,.34,.44),slab,cap);
		color+=slab*.13*(1.-smoothstep(.018,.07,seam))*cap*step(f.y,.5);
		if(surface==1){
			float track=min(abs(p.x-4.),abs(p.x-18.))-1.12;
			float boundary=min(15.-p.y,track)+(field(p*1.1)-.5)*.55+(field(id*.72)-.5)*1.15;
			vec2 dirt_uv=p*.12+.035*vec2(field(p*.47),field(p*.47+19.));
			vec3 dirt=paint(vec2(.5,0),dirt_uv)*mix(.82,1.02,field(p*.44));
			color=mix(color,dirt,smoothstep(-.12,.24,boundary));
		}
	}else if(surface==3){
		color=paint(vec2(.5), (top?p:side)*.12)*(top?1.:.72);
	}else{
		color=paint(vec2(0,.5),(top?p:side)*.19)*(top?vec3(.98):vec3(.74,.70,.84));
	}
	ALBEDO=color;
}
