import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
const directory = process.argv[2] || 'build/web';
const calls = [];
const window = {fetch:async url => {
  calls.push(url);
  return new Response(url.endsWith('.txt') ? 'unchanged' : await fs.readFile(path.join(directory,new URL(url).pathname.split('/').pop())));
}};
const context = {window, document:{baseURI:'https://example.test/ProjectTactic/tactics/index.html'}, URL, Request, Response, Blob, DecompressionStream};
vm.runInNewContext(await fs.readFile(path.join(directory,'asset-parts.js'),'utf8'), context);
vm.runInNewContext(await fs.readFile('web/compressed-wasm-loader.js','utf8'),context);
for (const name of ['index.wasm','index.pck']) {
  const response = await window.fetch(name);
  const bytes = await response.arrayBuffer();
  assert.equal(bytes.byteLength,window.TACTICS_ASSETS[name].size);
  if (name.endsWith('wasm')) assert(WebAssembly.validate(bytes));
  else assert.equal(Buffer.from(bytes).subarray(0,4).toString(), 'GDPC');
}
assert.equal(await (await window.fetch('other.txt')).text(),'unchanged');
assert(calls[0].startsWith('https://example.test/ProjectTactic/tactics/'));
const html=await fs.readFile(path.join(directory,'index.html'),'utf8');
assert(html.indexOf('compressed-wasm-loader.js')<html.indexOf('src="index.js"'));
console.log('Web package: WASM validity, PCK header, byte lengths, subpath loading and native passthrough pass');
