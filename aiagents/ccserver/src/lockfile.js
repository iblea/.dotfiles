import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { logger } from './logger.js';

function getLockDir() {
  const custom = process.env.CLAUDE_CONFIG_DIR;
  if (custom && custom.length > 0) {
    return path.join(custom, 'ide');
  }
  return path.join(os.homedir(), '.claude', 'ide');
}

export function generateAuthToken() {
  return crypto.randomUUID();
}

export function create({ port, pid, workspaceFolders, authToken, ideName = 'ccserver' }) {
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error(`Invalid port: ${port}`);
  }

  const dir = getLockDir();
  fs.mkdirSync(dir, { recursive: true });

  const lockPath = path.join(dir, `${port}.lock`);
  const payload = {
    pid,
    workspaceFolders: workspaceFolders && workspaceFolders.length > 0 ? workspaceFolders : [process.cwd()],
    ideName,
    transport: 'ws',
    authToken,
  };

  fs.writeFileSync(lockPath, JSON.stringify(payload), 'utf8');
  logger.debug('lockfile', 'created', lockPath);
  return lockPath;
}

export function remove(port) {
  const lockPath = path.join(getLockDir(), `${port}.lock`);
  try {
    fs.unlinkSync(lockPath);
    logger.debug('lockfile', 'removed', lockPath);
    return true;
  } catch (err) {
    if (err.code !== 'ENOENT') {
      logger.warn('lockfile', 'failed to remove', lockPath, err.message);
    }
    return false;
  }
}
