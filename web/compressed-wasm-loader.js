// Reconstruct generated assets without trusting a cached manifest or mixed PCK.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const names = ['index.wasm', 'index.pck'];
  const abortReason = signal => signal.reason === undefined
    ? new DOMException('The operation was aborted.', 'AbortError') : signal.reason;
  const checkAbort = signal => { if (signal.aborted) throw abortReason(signal); };

  async function currentAsset(name, request) {
    const url = new URL('asset-parts.json', document.baseURI);
    // Revalidate even a fresh cached manifest; legacy JS is never a fallback.
    const response = await nativeFetch(new Request(url, new Request(request, {cache:'no-cache'})));
    if (!response.ok) throw new Error(`Manifest download failed (${response.status}).`);
    const manifest = await response.json();
    checkAbort(request.signal);
    const asset = manifest?.[name];
    if (!asset || !Number.isSafeInteger(asset.size) || asset.size <= 0 ||
        !Array.isArray(asset.parts) || !asset.parts.length ||
        asset.parts.some((file, index) => file !== `${name}.part${index}`) ||
        asset.gzip !== (name === 'index.wasm') ||
        asset.type !== (name === 'index.wasm' ? 'application/wasm' : 'application/octet-stream') ||
        (name === 'index.pck' && (typeof asset.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(asset.sha256)))) {
      throw new Error('Invalid game asset manifest.');
    }
    return asset;
  }

  // Synthetic responses must retain fetch's unread-body abort behavior too.
  function abortable(body, signal) {
    const reader = body.getReader();
    let finished = false;
    let onAbort;
    const cleanup = () => { finished = true; signal.removeEventListener('abort', onAbort); };
    return new ReadableStream({
      start(controller) {
        onAbort = () => {
          if (finished) return;
          cleanup();
          controller.error(abortReason(signal));
          reader.cancel(abortReason(signal)).catch(() => {});
        };
        signal.addEventListener('abort', onAbort, {once:true});
        if (signal.aborted) onAbort();
      },
      async pull(controller) {
        try {
          const result = await reader.read();
          if (finished) return;
          if (result.done) { cleanup(); controller.close(); }
          else controller.enqueue(result.value);
        } catch (error) {
          if (!finished) { cleanup(); controller.error(error); }
        }
      },
      cancel(reason) { cleanup(); return reader.cancel(reason); },
    });
  }

  window.fetch = async (input, options) => {
    const url = new URL(input instanceof Request ? input.url : input, document.baseURI);
    const name = names.find(name => new URL(name, document.baseURI).href === url.href);
    if (!name) return nativeFetch(input, options);
    // Do not clone a body-bearing Request before deciding to pass it through:
    // Request construction can consume the original body's one-shot stream.
    const method = options?.method === undefined
      ? (input instanceof Request ? input.method : 'GET') : options.method;
    if (String(method).toUpperCase() !== 'GET') return nativeFetch(input, options);
    const request = new Request(input instanceof Request ? input : url, options);
    // Only full ordinary GETs are reconstructed. Do not reinterpret Range/SRI.
    if (request.method !== 'GET' || request.headers.has('Range') || request.integrity) {
      return nativeFetch(input, options);
    }
    try {
      checkAbort(request.signal);
      if (name === 'index.pck' && !window.crypto?.subtle) {
        throw new Error('Game verification requires a current browser on HTTPS.');
      }
      for (let attempt = 0; attempt < 2; attempt++) {
        const asset = await currentAsset(name, request);
        const chunks = [];
        for (const file of asset.parts) {
          checkAbort(request.signal);
          const partURL = new URL(file, document.baseURI);
          if (name === 'index.pck') partURL.searchParams.set('v', asset.sha256);
          // On integrity retry, do not reuse the same poisoned HTTP-cache entry.
          const partRequest = new Request(partURL, request);
          const response = await nativeFetch(attempt && request.cache !== 'no-store'
            ? new Request(partRequest, {cache:'reload'}) : partRequest);
          if (!response.ok) throw new Error(`Game download failed (${response.status}).`);
          chunks.push(await response.arrayBuffer());
        }
        checkAbort(request.signal);
        let body = new Blob(chunks).stream();
        if (name === 'index.pck') {
          const bytes = await new Blob(chunks).arrayBuffer();
          const hash = await window.crypto.subtle.digest('SHA-256', bytes);
          checkAbort(request.signal);
          const actual = Array.from(new Uint8Array(hash), byte => byte.toString(16).padStart(2, '0')).join('');
          if (bytes.byteLength !== asset.size || actual !== asset.sha256) {
            if (attempt === 0) continue; // Fresh manifest + entire pack, exactly once.
            throw new Error('Game files changed during download or failed verification.');
          }
          body = new Blob([bytes]).stream();
        } else {
          if (typeof DecompressionStream === 'undefined') {
            throw new Error('Please use a current browser with gzip decompression support.');
          }
          body = body.pipeThrough(new DecompressionStream('gzip'));
        }
        checkAbort(request.signal);
        return new Response(abortable(body, request.signal),
          {headers:{'Content-Type':asset.type, 'Content-Length':String(asset.size)}});
      }
    } catch (error) {
      checkAbort(request.signal);
      if (error?.name === 'AbortError') throw error;
      throw new Error(`${error?.message || 'Game download failed.'} Reload to retry.`);
    }
  };
})();
