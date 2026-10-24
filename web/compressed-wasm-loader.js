// Reconstruct generated assets from small static files. No custom server headers.
(() => {
  const nativeFetch = window.fetch.bind(window);
  const assets = window.TACTICS_ASSETS || {};
  window.fetch = async (input, options) => {
    const url = new URL(input instanceof Request ? input.url : input, document.baseURI);
    const entry = Object.entries(assets).find(([name]) => new URL(name, document.baseURI).href === url.href);
    if (!entry) return nativeFetch(input, options);
    const [, asset] = entry;
    const chunks = [];
    for (const file of asset.parts) {
      const response = await nativeFetch(new URL(file, document.baseURI).href, options);
      if (!response.ok) throw new Error(`Game download failed (${response.status}). Reload to retry.`);
      chunks.push(await response.arrayBuffer());
    }
    let body = new Blob(chunks).stream();
    if (asset.gzip) {
      if (typeof DecompressionStream === 'undefined') throw new Error('Please use a current browser with gzip decompression support.');
      body = body.pipeThrough(new DecompressionStream('gzip'));
    }
    return new Response(body, {headers:{'Content-Type':asset.type, 'Content-Length':String(asset.size)}});
  };
})();
