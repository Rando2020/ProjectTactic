// Run against the exact exported engine, not a handwritten substitute for its bus code.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const path = require('node:path');
const engine = fs.readFileSync(process.argv[2], 'utf8');
const start = engine.indexOf('Bus:class Bus') + 4;
const end = engine.indexOf(',sampleFinishedCallback:', start);
assert(start > 4 && end > start, 'supported Godot Web Bus class found');
class Gain { constructor() { this.gain={value:1}; this.outputs=[]; } connect(node) { this.outputs.push(node); return node; } disconnect() { this.outputs=[]; } }
const destination = {};
const audio = {buses:[],busSolo:null,ctx:{destination,createGain:()=>new Gain()},linear_to_db:x=>20*Math.log10(x),db_to_linear:x=>10**(x/20)};
audio.Bus = vm.runInNewContext(`(${engine.slice(start,end)})`, {GodotAudio:audio, Set, Error, ReferenceError});
function reaches(node, seen=new Set()) { if(node===destination)return true; if(seen.has(node))return false; seen.add(node); return (node.outputs||[]).some(n=>reaches(n,seen)); }
function createBuses(policy) {
  audio.buses=[]; audio.Bus.setCount(1);
  for(let index=1;index<=3;index++) {
    // AudioServer::add_bus converts append positions >=bus_count back to -1.
    if(policy==='count') audio.Bus.setCount(audio.buses.length+1); else audio.Bus.addAt(-1);
    audio.Bus.getBus(index).setSend(audio.Bus.getBus(index===1?0:1));
  }
  return audio.buses.map(b=>reaches(b.getInputNode()));
}
assert.deepEqual(createBuses('add'), [false,false,false,false], 'legacy append reproduces disconnected graph');
assert.deepEqual(createBuses('count'), [true,true,true,true], 'count growth preserves Master and all output paths');
const settings = fs.readFileSync(path.resolve(__dirname,'../../demos/isometric-2v2/scripts/systems/AudioSettings.gd'),'utf8');
assert(!settings.includes('AudioServer.add_bus('), 'application must not use broken Web add_bus append path');
assert(settings.includes('AudioServer.bus_count += 1'), 'application grows bus count without moving Master');
console.log('Exact exported Web bus graph: legacy reproduction + fixed output paths PASS');
