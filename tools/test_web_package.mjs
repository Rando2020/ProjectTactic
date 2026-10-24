// Real wrapper + native web primitives; only HTTP responses are simulated.
import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {createHash, webcrypto} from 'node:crypto';

const loader = await fs.readFile(new URL('../web/compressed-wasm-loader.js', import.meta.url), 'utf8');
const older = Buffer.from('GDPCold-header|old-tail');
const newer = Buffer.from('GDPCnew-header|new-tail');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const manifest = bytes => ({
  'index.pck': {parts:['index.pck.part0','index.pck.part1'],gzip:false,
    type:'application/octet-stream',size:bytes.length,sha256:digest(bytes)},
  'index.wasm': {parts:['index.wasm.part0'],gzip:true,type:'application/wasm',size:8},
});
const part = (bytes, i) => i === 0 ? bytes.subarray(0,14) : bytes.subarray(14);

function harness({baseURI='https://example.test/ProjectTactic/tactics/index.html',
  manifests=[manifest(newer)], chunk, manifestResponse, crypto=webcrypto, globalManifest=manifest(older)}={}) {
  const requests = [];
  let manifestCount = 0;
  let chunkCount = 0;
  let passthrough;
  const nativeFetch = async (input, options) => {
    const request = new Request(input, options);
    requests.push(request);
    request.signal.throwIfAborted();
    const url = new URL(request.url);
    const file = url.pathname.split('/').pop();
    if (file === 'asset-parts.json') {
      const count = manifestCount++;
      if (manifestResponse) return manifestResponse(request,count);
      // Fail if wrapper accidentally allows a still-fresh legacy cache response.
      return Response.json(request.cache === 'no-cache' || request.cache === 'no-store'
        ? manifests[Math.min(count,manifests.length-1)] : manifest(older));
    }
    if (file.startsWith('index.pck.part')) {
      const index = Number(file.split('.part')[1]);
      const count = chunkCount++;
      return chunk ? chunk({request,index,count,manifestCount}) : new Response(part(newer,index));
    }
    passthrough = {input,options};
    return new Response('native');
  };
  const window = {fetch:nativeFetch,TACTICS_ASSETS:globalManifest,crypto};
  vm.runInNewContext(loader,{window,document:{baseURI},URL,Request,Response,Blob,DecompressionStream,ReadableStream,crypto,DOMException});
  return {window,requests,get manifestCount(){return manifestCount;},get chunkCount(){return chunkCount;},
    get passthrough(){return passthrough;},url:name=>new URL(name,baseURI).href};
}

for (const baseURI of ['https://example.test/index.html?release=old',
  'https://example.test/ProjectTactic/tactics/', 'https://example.test/ProjectTactic/tactics/index.html']) {
  test(`fresh manifest supersedes cached legacy metadata at ${baseURI}`,async()=>{
    const h=harness({baseURI});
    const response=await h.window.fetch('index.pck');
    assert.deepEqual(Buffer.from(await response.arrayBuffer()),newer);
    assert.equal(response.headers.get('Content-Length'),String(newer.length));
    assert.equal(h.manifestCount,1);
    assert.equal(h.chunkCount,2);
    for (const request of h.requests.slice(1)) {
      assert.equal(new URL(request.url).searchParams.get('v'),digest(newer));
      assert.equal(new URL(request.url).pathname.startsWith(new URL('.',baseURI).pathname),true);
    }
  });
}

test('same-length mixed bytes never escape, even with correct GDPC header',async()=>{
  const h=harness({chunk:({index})=>new Response(part(index===0?older:newer,index))});
  await assert.rejects(h.window.fetch('index.pck'),/reload/i);
  assert.equal(h.manifestCount,2);
  assert.equal(h.chunkCount,4);
});

test('truncated bytes never escape and only two complete downloads are attempted',async()=>{
  const h=harness({chunk:({index})=>new Response(part(newer,index).subarray(1))});
  await assert.rejects(h.window.fetch('index.pck'),/reload/i);
  assert.equal(h.manifestCount,2);
  assert.equal(h.chunkCount,4);
});

test('deployment race refreshes metadata and retries the whole pack once',async()=>{
  const h=harness({manifests:[manifest(older),manifest(newer)],
    chunk:({index,manifestCount})=>new Response(part(manifestCount===1&&index===0?older:newer,index))});
  const bytes=Buffer.from(await (await h.window.fetch('index.pck')).arrayBuffer());
  assert.deepEqual(bytes,newer);
  assert.equal(h.manifestCount,2);
  assert.deepEqual(h.requests.filter(r=>r.url.includes('.part')).map(r=>new URL(r.url).searchParams.get('v')),
    [digest(older),digest(older),digest(newer),digest(newer)]);
});

test('stale but internally valid response is not accepted against fresh metadata',async()=>{
  const h=harness({chunk:({index})=>new Response(part(older,index))});
  await assert.rejects(h.window.fetch('index.pck'),/reload/i);
  assert.equal(h.chunkCount,4);
});

test('manifest HTTP failure is visible and does not fall back to legacy manifest',async()=>{
  const h=harness({manifestResponse:()=>new Response('unavailable',{status:503})});
  await assert.rejects(h.window.fetch('index.pck'),/503.*reload|reload.*503/i);
  assert.equal(h.manifestCount,1);
  assert.equal(h.chunkCount,0);
});

test('part HTTP failure is visible without an integrity retry',async()=>{
  const h=harness({chunk:()=>new Response('unavailable',{status:404})});
  await assert.rejects(h.window.fetch('index.pck'),/404.*reload|reload.*404/i);
  assert.equal(h.manifestCount,1);
  assert.equal(h.chunkCount,1);
});

for (const corrupt of [m=>delete m['index.pck'].sha256,m=>m['index.pck'].sha256='invalid',
  m=>m['index.pck'].sha256=[m['index.pck'].sha256],m=>m['index.pck'].parts=[],
  m=>m['index.pck'].size=-1,m=>m['index.pck'].parts=['https://elsewhere.test/private'],
  m=>m['index.pck'].parts=['../index.pck.part0']]) {
  test(`invalid manifest fails closed: ${corrupt}`,async()=>{
    const m=manifest(newer); corrupt(m);
    const h=harness({manifests:[m]});
    await assert.rejects(h.window.fetch('index.pck'),/reload/i);
    assert.equal(h.chunkCount,0);
  });
}

test('invalid JSON is not evaluated or replaced by cached metadata',async()=>{
  const h=harness({manifestResponse:()=>new Response('window.evaluated = true;')});
  await assert.rejects(h.window.fetch('index.pck'),/reload/i);
  assert.equal(h.window.evaluated,undefined);
  assert.equal(h.chunkCount,0);
});

test('missing WebCrypto never silently disables PCK verification',async()=>{
  const h=harness({crypto:{}});
  await assert.rejects(h.window.fetch('index.pck'),/reload/i);
});

test('Request credentials, headers, cache and abort signal reach part fetches',async()=>{
  const h=harness();
  const controller=new AbortController();
  const request=new Request(h.url('index.pck'),{credentials:'include',headers:{'X-Request':'preserved'},
    cache:'no-store',redirect:'error',signal:controller.signal});
  await h.window.fetch(request);
  for (const r of h.requests) {
    assert.equal(r.credentials,'include');
    assert.equal(r.headers.get('X-Request'),'preserved');
    assert.equal(r.redirect,'error');
    if (r.url.includes('.part')) assert.equal(r.cache,'no-store');
  }
  controller.abort();
  assert(h.requests.every(r=>r.signal.aborted));
});

test('Request init overrides are respected',async()=>{
  const h=harness();
  await h.window.fetch(new Request(h.url('index.pck'),{credentials:'omit'}),{credentials:'include'});
  assert(h.requests.every(r=>r.credentials==='include'));
});

test('pre-aborted Request rejects without any network requests',async()=>{
  const controller=new AbortController(); controller.abort();
  const h=harness();
  await assert.rejects(h.window.fetch(new Request(h.url('index.pck'),{signal:controller.signal})),e=>e.name==='AbortError');
  assert.equal(h.requests.length,0);
});

test('abort after headers still rejects unread reconstructed response body',async()=>{
  const controller=new AbortController();
  const h=harness();
  const response=await h.window.fetch('index.pck',{signal:controller.signal});
  controller.abort();
  await assert.rejects(response.arrayBuffer(),e=>e.name==='AbortError');
});

test('integrity retry bypasses a poisoned cached part response',async()=>{
  const h=harness({chunk:({request,index})=>new Response(part(
    request.cache==='reload'?newer:older,index))});
  assert.deepEqual(Buffer.from(await (await h.window.fetch('index.pck')).arrayBuffer()),newer);
  assert.equal(h.manifestCount,2);
});

for (const phase of ['manifest','part','digest']) {
  test(`abort during ${phase} rejects without retry`,async()=>{
    const controller=new AbortController();
    const h=harness({
      manifestResponse:phase==='manifest'?()=>{controller.abort();return Response.json(manifest(newer));}:undefined,
      chunk:phase==='part'?({index})=>{controller.abort();return new Response(part(newer,index));}:undefined,
      crypto:phase==='digest'?{subtle:{digest:async(...args)=>{controller.abort();return webcrypto.subtle.digest(...args);}}}:webcrypto,
    });
    await assert.rejects(h.window.fetch('index.pck',{signal:controller.signal}),e=>e.name==='AbortError');
    assert.equal(h.manifestCount,1);
    assert(h.chunkCount<=2);
  });
}

for (const [name,options] of [['other.txt',{}],['index.pck?custom=1',{}],['index.pck',{method:'HEAD'}],
  ['index.pck',{headers:{Range:'bytes=0-3'}}],['index.pck',{integrity:'sha256-unrelated'}]]) {
  test(`native passthrough preserves original input/options: ${name} ${JSON.stringify(options)}`,async()=>{
    const h=harness();
    const input=new Request(h.url(name));
    assert.equal(await (await h.window.fetch(input,options)).text(),'native');
    assert.equal(h.passthrough.input,input);
    assert.equal(h.passthrough.options,options);
    assert.equal(h.manifestCount,0);
  });
}

for (const [method,options] of [['POST',{}],['PUT',{}],['POST',{method:'PUT'}],
  ['GET',{method:'POST',body:'override payload'}]]) {
  test(`body-bearing native passthrough preserves Request: ${method} ${JSON.stringify(options)}`,async()=>{
    const h=harness();
    const input=new Request(h.url('index.pck'),method==='GET'?{}:{method,body:'original payload'});
    assert.equal(await (await h.window.fetch(input,options)).text(),'native');
    assert.equal(h.passthrough.input,input);
    assert.equal(h.passthrough.options,options);
    assert.equal(h.requests[0].method,options.method??method);
    assert.equal(await h.requests[0].text(),options.body??'original payload');
    assert.equal(h.manifestCount,0);
  });
}
