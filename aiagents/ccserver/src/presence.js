import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import DiscordRPC from 'discord-rpc';

const CLIENT_ID = '1494241543387877446';
const DISCORD_LOCK_PATH = path.join(os.tmpdir(), 'discord-ccserver.lock');

function isProcessAlive(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function acquireDiscordLock() {
  try {
    const content = fs.readFileSync(DISCORD_LOCK_PATH, 'utf8').trim();
    const pid = parseInt(content, 10);
    if (!isNaN(pid) && isProcessAlive(pid)) {
      console.log(`[Discord Presence] Lock held by PID ${pid}, skipping connection`);
      return false;
    }
  } catch (err) {
    if (err.code !== 'ENOENT') {
      console.warn('[Discord Presence] Failed to read lock file:', err.message);
    }
  }

  fs.writeFileSync(DISCORD_LOCK_PATH, String(process.pid), 'utf8');
  return true;
}

function releaseDiscordLock() {
  try {
    const content = fs.readFileSync(DISCORD_LOCK_PATH, 'utf8').trim();
    if (parseInt(content, 10) === process.pid) {
      fs.unlinkSync(DISCORD_LOCK_PATH);
    }
  } catch {
    // 이미 없거나 읽기 실패 - 무시
  }
}

class DiscordPresence {
  constructor() {
    this.client = new DiscordRPC.Client({ transport: 'ipc' });
    this.isConnected = false;
    this.isConnecting = false;
    this.startTime = Date.now();

    this.setupEventHandlers();
  }

  setupEventHandlers() {
    this.client.on('ready', () => {
      console.log('[Discord Presence] Connected to Discord');
      this.isConnected = true;
      this.updateActivity();
    });

    this.client.on('error', (error) => {
      console.error('[Discord Presence] Error:', error);
      this.isConnected = false;
    });

    this.client.on('disconnected', () => {
      console.log('[Discord Presence] Disconnected from Discord');
      this.isConnected = false;
      releaseDiscordLock();
    });
  }

  connect() {
    if (this.isConnecting || this.isConnected) {
      return Promise.resolve();
    }

    if (!acquireDiscordLock()) {
      return Promise.resolve();
    }

    this.isConnecting = true;
    console.log('[Discord Presence] Connecting to Discord...');

    return this.client
      .login({ clientId: CLIENT_ID })
      .then(() => {
        this.isConnecting = false;
      })
      .catch((error) => {
        console.error('[Discord Presence] Failed to connect:', error);
        this.isConnecting = false;
        this.isConnected = false;
        releaseDiscordLock();
      });
  }

  disconnect() {
    this.isConnected = false;
    this.isConnecting = false;
    return this.client.clearActivity()
      .catch(() => {})
      .then(() => this.client.destroy())
      .then(() => {
        console.log('[Discord Presence] Disconnected');
        releaseDiscordLock();
      })
      .catch(() => {
        releaseDiscordLock();
      });
  }

  updateActivity(options = {}) {
    if (!this.isConnected) {
      return;
    }

    const activity = {
      details: options.details || 'claude 괴롭히는 중',
      state: options.state || 'Talking',
      largeImageKey: options.largeImageKey || 'claudecode',
      largeImageText: options.largeImageText || 'ClaudeCode',
      smallImageKey: options.smallImageKey,
      smallImageText: options.smallImageText,
      startTimestamp: options.startTimestamp || this.startTime,
      instance: true,
    };

    Object.keys(activity).forEach((key) => {
      if (activity[key] === undefined) {
        delete activity[key];
      }
    });

    this.client
      .setActivity(activity)
      .then(() => {
        console.log('[Discord Presence] Activity updated:', activity);
      })
      .catch((error) => {
        console.error('[Discord Presence] Failed to update activity:', error);
      });
  }

  setStatus(state, details) {
    this.updateActivity({
      state,
      details,
      largeImageKey: 'claudecode',
      largeImageText: 'ClaudeCode',
    });
  }

  clearActivity() {
    if (!this.isConnected) {
      return;
    }

    this.client.clearActivity().catch((error) => {
      console.error('[Discord Presence] Failed to clear activity:', error);
    });
  }
}

// Singleton instance
let presenceInstance = null;

export function getPresence() {
  if (!presenceInstance) {
    presenceInstance = new DiscordPresence();
  }
  return presenceInstance;
}

export default DiscordPresence;
