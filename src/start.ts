import { initServer } from './index.js';

// Puedes configurar aquí opciones personalizadas si las necesitas
initServer({
  port: process.env.PORT || 21465,
  startAllSession: true,
  log: {
    level: 'info',
  },
});
