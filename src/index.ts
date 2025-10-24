/*
 * Copyright 2021 WPPConnect Team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { defaultLogger } from '@wppconnect-team/wppconnect';
import cors from 'cors';
import express, { Express, NextFunction, Router } from 'express';
import boolParser from 'express-query-boolean';
import { createServer } from 'http';
import mergeDeep from 'merge-deep';
import process from 'process';
import { Server as Socket } from 'socket.io';
import { Logger } from 'winston';
//js
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const packageJson = JSON.parse(
  readFileSync(resolve(__dirname, '../package.json'), 'utf8')
);
const { version } = packageJson;


import config from './config/config.js';
import { convert } from './mapper/index.js';
import routes from './routes/index.js';
import { ServerOptions } from './types/ServerOptions.js';
import {
  createFolders,
  setMaxListners,
  startAllSessions,
} from './util/functions.js';
import { createLogger } from './util/logger.js';


import dotenv from 'dotenv';
dotenv.config();


export const logger = createLogger(config.log);

export function initServer(serverOptions: Partial<ServerOptions>): {
  app: Express;
  routes: Router;
  logger: Logger;
} {
  if (typeof serverOptions !== 'object') {
    serverOptions = {};
  }

  serverOptions = mergeDeep({}, config, serverOptions);
  defaultLogger.level = serverOptions?.log?.level
    ? serverOptions.log.level
    : 'silly';

  setMaxListners(serverOptions as ServerOptions);

  const app = express();
  const PORT = process.env.PORT || serverOptions.port;

  app.use(cors());
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));
  app.use('/files', express.static('WhatsAppImages'));
  app.use(boolParser());
  //ver logs de las requests
  app.use(routes);

  if (config?.aws_s3?.access_key_id && config?.aws_s3?.secret_key) {
    process.env['AWS_ACCESS_KEY_ID'] = config.aws_s3.access_key_id;
    process.env['AWS_SECRET_ACCESS_KEY'] = config.aws_s3.secret_key;
  }

  // Add request options
  app.use((req: any, res: any, next: NextFunction) => {
    req.serverOptions = serverOptions;
    req.logger = logger;
    req.io = io as any;

    const oldSend = res.send;

    res.send = async function (data: any) {
      const content = req.headers['content-type'];
      if (content == 'application/json') {
        data = JSON.parse(data);
        if (!data.session) data.session = req.client ? req.client.session : '';
        if (data.mapper && req.serverOptions.mapper.enable) {
          data.response = await convert(
            req.serverOptions.mapper.prefix,
            data.response,
            data.mapper
          );
          delete data.mapper;
        }
      }
      res.send = oldSend;
      return res.send(data);
    };
    next();
  });

  app.get('/', (req, res) => {
  res.status(200).send(' Servidor corriendo correctamente - WPPConnect en Railway');
  });

  createFolders();
  const http = createServer(app);
  const io = new Socket(http, {
    cors: {
      origin: '*',
    },
  });

  io.on('connection', (sock) => {
    logger.info(`ID: ${sock.id} entrou`);

    sock.on('disconnect', () => {
      logger.info(`ID: ${sock.id} saiu`);
    });
  });

http.listen({ port: Number(PORT), host: '0.0.0.0' }, () => {
  logger.info(` Server is running on port: ${PORT}`);
  logger.info(`WPPConnect-Server version: ${version}`);

  // Detectar dominio público de Railway
  const publicDomain =
    process.env.RAILWAY_PUBLIC_DOMAIN ||
    process.env.RAILWAY_STATIC_URL ||
    process.env.RAILWAY_PUBLIC_URL ||
    process.env.PUBLIC_URL ||
    '';

  const isLocal =
    !publicDomain &&
    (String(serverOptions.host || '').includes('localhost') ||
      String(serverOptions.host || '').includes('0.0.0.0') ||
      !serverOptions.host);

  const protocol = isLocal ? 'http' : 'https';
  const baseUrl = publicDomain
    ? `${protocol}://${publicDomain}`
    : `${protocol}://${serverOptions.host || '127.0.0.1'}:${PORT}`;

  logger.info(`\x1b[31m Visit ${baseUrl}/api-docs for Swagger docs`);

  // Crear copia segura con secretKey (evita undefined)
  const safeOptions = {
    secretKey: serverOptions.secretKey || process.env.SECRET_KEY || '',
    ...serverOptions,
  };

  if (safeOptions.startAllSession) {
    logger.info(' Starting all sessions...');
      setTimeout(() => {
      startAllSessions(safeOptions as any, logger);
      }, 2000);
    // Llamar con opciones seguras
    //startAllSessions(safeOptions as any, logger);
  }
});



  if (config.log.level === 'error' || config.log.level === 'warn') {
    console.log(`\x1b[33m ======================================================
Attention:
Your configuration is configured to show only a few logs, before opening an issue, 
please set the log to 'silly', copy the log that shows the error and open your issue.
======================================================
`);
  }

  return {
    app,
    routes,
    logger,
  };
}
