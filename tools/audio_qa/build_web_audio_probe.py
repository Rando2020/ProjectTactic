"""Build a standalone gesture-gated WebAudio probe from the exact shipped engine Bus class.
No game or wrapper code is modified. Usage: python build_web_audio_probe.py index.js probe.html
"""
import pathlib,sys,hashlib
engine=pathlib.Path(sys.argv[1]).read_text()
a=engine.index('Bus:class Bus')+4
b=engine.index(',sampleFinishedCallback:',a)
engine_class=engine[a:b]
html='''<!doctype html><meta charset="utf-8"><title>ProjectTactic WebAudio routing diagnostic</title>
<style>body{background:#111a26;color:#edf5ff;font:20px system-ui;padding:28px;max-width:900px}button{padding:16px;margin:8px;font:inherit}pre{white-space:pre-wrap;background:#223047;padding:20px}</style>
<h1>WebAudio routing diagnostic</h1><p>Tests the exact shipped Godot Bus class, without WebGL. Each button creates/resumes audio from your click. A quiet one-second tone should be audible only when the route reaches the output.</p>
<button id="legacy">Test old add_bus route</button><button id="fixed">Test corrected bus_count route</button><pre id="result">Ready. Click one test.</pre>
<script>
let context;
const result=document.getElementById('result');
async function run(fixed){
 try {
  if(context) await context.close();
  context=new (window.AudioContext||window.webkitAudioContext)();
  const analyser=context.createAnalyser();analyser.fftSize=2048;analyser.connect(context.destination);
  const GodotAudio={buses:[],busSolo:null,ctx:{createGain:()=>context.createGain(),destination:analyser},linear_to_db:x=>20*Math.log10(x),db_to_linear:x=>10**(x/20)};
  GodotAudio.Bus=__ENGINE_CLASS__;
  GodotAudio.Bus.setCount(1);
  for(let index=1;index<=3;index++){
   if(fixed)GodotAudio.Bus.setCount(GodotAudio.buses.length+1);else GodotAudio.Bus.addAt(-1);
   GodotAudio.Bus.getBus(index).setSend(GodotAudio.Bus.getBus(index===1?0:1));
  }
  await context.resume();
  const buffer=context.createBuffer(1,context.sampleRate,context.sampleRate);const pcm=buffer.getChannelData(0);
  for(let i=0;i<pcm.length;i++){const t=i/context.sampleRate;pcm[i]=Math.sin(2*Math.PI*440*t)*.12*Math.min(1,t/.02,(1-t)/.02);}
  const source=context.createBufferSource();source.buffer=buffer;source.connect(GodotAudio.Bus.getBus(3).getInputNode());source.start();
  result.textContent='Measuring '+(fixed?'corrected':'old')+' route… context='+context.state;
  await new Promise(resolve=>setTimeout(resolve,250));
  const data=new Float32Array(analyser.fftSize);analyser.getFloatTimeDomainData(data);
  const rms=Math.sqrt(data.reduce((s,v)=>s+v*v,0)/data.length);const peak=Math.max(...data.map(Math.abs));
  result.textContent=JSON.stringify({route:fixed?'bus_count':'add_bus(-1)',context_state:context.state,rms,peak,signal_detected:rms>.005,expected_signal:fixed,passes:(rms>.005)===fixed,engine_sha256:'__ENGINE_HASH__'},null,2);
  document.body.dataset.result=(rms>.005)===fixed?'pass':'fail';
 }catch(error){result.textContent=error.stack||String(error);document.body.dataset.result='error';}
}
document.getElementById('legacy').onclick=()=>run(false);document.getElementById('fixed').onclick=()=>run(true);
</script>'''
html=html.replace('__ENGINE_CLASS__',engine_class).replace('__ENGINE_HASH__',hashlib.sha256(engine.encode()).hexdigest())
pathlib.Path(sys.argv[2]).write_text(html)
print(sys.argv[2])
