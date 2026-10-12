import { defineConfig } from "vite";
export default defineConfig({
  esbuild: { jsx: "automatic" },
  server: { proxy: { "/api": "http://localhost:8000", "/ws": { target: "ws://localhost:8000", ws: true } } },
});
