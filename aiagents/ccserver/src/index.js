#!/usr/bin/env node
import fs from 'node:fs';
import process from 'node:process';
import { startServer } from './server.js';
import { create as createLockfile, remove as removeLockfile, generateAuthToken } from './lockfile.js';
import { logger } from './logger.js';
import { getPresence } from './presence.js';

function parseArgs(argv) {
  const args = { readyFile: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--ready-file' || a === '-r') {
      args.readyFile = argv[++i];
    } else if (a === '--help' || a === '-h') {
      process.stdout.write(
        'Usage: ccserver [--ready-file <path>]\n' +
        '  --ready-file <path>  Write the chosen port to this file once listening\n'
      );
      process.exit(0);
    } else {
      logger.warn('index', 'unknown arg:', a);
    }
  }
  return args;
}

const args = parseArgs(process.argv);
const authToken = generateAuthToken();
let lockPort = null;
let wssrv = null;
const presence = getPresence();

function cleanupSync(reason) {
  logger.info('index', 'cleanup:', reason);
  if (lockPort !== null) {
    removeLockfile(lockPort);
    lockPort = null;
  }
  if (wssrv) {
    try { wssrv.close(); } catch {}
    wssrv = null;
  }
}

async function cleanup(reason) {
  cleanupSync(reason);
  try {
    await presence.disconnect();
  } catch (err) {
    logger.error('index', 'failed to disconnect Discord:', err.message);
  }
}

['SIGINT', 'SIGTERM', 'SIGHUP'].forEach((sig) => {
  process.on(sig, async () => {
    const timer = setTimeout(() => process.exit(0), 3000);
    await cleanup(sig);
    clearTimeout(timer);
    process.exit(0);
  });
});

process.on('exit', () => cleanupSync('exit'));
process.on('uncaughtException', (err) => {
  logger.error('index', 'uncaughtException:', err.stack || err.message);
  cleanup('uncaughtException');
  process.exit(1);
});

wssrv = startServer({
  authToken,
  onListening: (port) => {
    try {
      createLockfile({
        port,
        pid: process.pid,
        workspaceFolders: [process.cwd()],
        authToken,
      });
      lockPort = port;
    } catch (err) {
      logger.error('index', 'failed to create lockfile:', err.message);
      process.exit(1);
    }

    if (args.readyFile) {
      try {
        fs.writeFileSync(args.readyFile, String(port), 'utf8');
        logger.debug('index', 'ready file written:', args.readyFile);
      } catch (err) {
        logger.error('index', 'failed to write ready file:', err.message);
        process.exit(1);
      }
    }

    logger.info('index', `ccserver ready (port=${port}, pid=${process.pid})`);

    // Connect to Discord
    presence.connect().catch((err) => {
      logger.info('index', 'Discord RPC not available, skipping');
    });
  },
});
