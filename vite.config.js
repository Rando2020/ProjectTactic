import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

export default defineConfig(({ mode }) => {
  if (mode === 'godot') {
    const root = fileURLToPath(new URL('./build/web/', import.meta.url))
    if (!existsSync(`${root}index.html`)) {
      throw new Error('Export the Godot Web game first: python tools/export_godot_web.py --godot /path/to/godot')
    }
    return {
      root,
      base: '/',
      server: { host: '0.0.0.0', allowedHosts: ['terminal.local'] },
    }
  }
  return { plugins: [react()], base: '/ProjectTactic/' }
})
