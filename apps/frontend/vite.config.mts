import { defineConfig } from '@vben/vite-config';

export default defineConfig(async () => {
  return {
    application: {},
    vite: {
      server: {
        proxy: {
          '/api': {
            changeOrigin: true,
            // 直接连接后端API
            target: 'http://localhost:9527',
            ws: true,
          },
        },
      },
    },
  };
});
