import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';
import {createHash, webcrypto} from 'node:crypto';
const directory = process.argv[2] || 'build/web';
const manifest = JSON.parse(await fs.readFile(path.join(directory,'asset-parts.json'),'utf8'));
const loader = await fs.readFile(path.join(directory,'compressed-wasm-loader.js'),'utf8');
for (const baseURI of ['https://example.test/index.html', 'https://example.test/ProjectTactic/tactics/index.html']) {
  const calls = [];
  const window = {crypto:webcrypto,fetch:async (input, options) => {
    const request = new Request(input instanceof Request ? input : new URL(input,baseURI), options);
    const url = new URL(request.url);
    calls.push(request);
    return new Response(url.pathname.endsWith('.txt') ? 'unchanged'
      : await fs.readFile(path.join(directory,url.pathname.split('/').pop())));
  }};
  const context = {window,document:{baseURI},URL,Request,Response,Blob,DecompressionStream,ReadableStream,DOMException};
  vm.runInNewContext(await fs.readFile(path.join(directory,'asset-parts.js'),'utf8'),context);
  assert.equal(JSON.stringify(window.TACTICS_ASSETS),JSON.stringify(manifest));
  vm.runInNewContext(loader,context);
  for (const name of ['index.wasm','index.pck']) {
    const response = await window.fetch(name);
    const bytes = await response.arrayBuffer();
    assert.equal(bytes.byteLength,manifest[name].size);
    if (name.endsWith('wasm')) assert(WebAssembly.validate(bytes));
    else {
      assert.equal(Buffer.from(bytes).subarray(0,4).toString(),'GDPC');
      assert.equal(createHash('sha256').update(Buffer.from(bytes)).digest('hex'),manifest[name].sha256);
    }
  }
  assert.equal(await (await window.fetch('other.txt')).text(),'unchanged');
  assert(calls.every(request=>request.url.startsWith(new URL('.',baseURI).href)));
  assert.equal(calls.filter(request=>request.url.endsWith('asset-parts.json')).length,2);
  for (const request of calls.filter(request=>request.url.includes('index.pck.part'))) {
    assert.equal(new URL(request.url).searchParams.get('v'),manifest['index.pck'].sha256);
  }
}
const html=await fs.readFile(path.join(directory,'index.html'),'utf8');
const loaderVersion=createHash('sha256').update(loader).digest('hex');
assert(html.includes(`src="compressed-wasm-loader.js?v=${loaderVersion}"`));
assert(html.indexOf('compressed-wasm-loader.js')<html.indexOf('src="index.js"'));
console.log('Web package: WASM validity, PCK SHA-256/length/header, fresh manifest, versioned bootstrap, root/subpath and native passthrough pass');
