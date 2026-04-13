import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { logger } from '../logger.js';

export const schema = {
  description: 'Open a diff view comparing old file content with new file content',
  inputSchema: {
    type: 'object',
    properties: {
      old_file_path: { type: 'string', description: 'Path to the old file to compare' },
      new_file_path: { type: 'string', description: 'Path to the new file to compare' },
      new_file_contents: { type: 'string', description: 'Contents for the new file version' },
      tab_name: { type: 'string', description: 'Name for the diff tab/view' },
    },
    required: ['old_file_path', 'new_file_path', 'new_file_contents', 'tab_name'],
    additionalProperties: false,
    $schema: 'http://json-schema.org/draft-07/schema#',
  },
};

function tmuxAvailable() {
  if (!process.env.TMUX) return false;
  const res = spawnSync('tmux', ['display-message', '-p', '#S'], { stdio: 'ignore' });
  return res.status === 0;
}

function shellQuote(s) {
  return `'${String(s).replace(/'/g, `'\\''`)}'`;
}

export async function handler(params) {
  const required = ['old_file_path', 'new_file_path', 'new_file_contents', 'tab_name'];
  for (const k of required) {
    if (params[k] === undefined || params[k] === null) {
      const err = new Error(`Missing required parameter: ${k}`);
      err.code = -32602;
      throw err;
    }
  }

  if (!tmuxAvailable()) {
    const err = new Error('tmux session required');
    err.code = -32000;
    err.data = 'ccserver must run inside a tmux session';
    throw err;
  }

  const { old_file_path, new_file_contents, tab_name } = params;
  const ext = path.extname(old_file_path) || '';
  const id = crypto.randomBytes(4).toString('hex');
  const tmpDir = os.tmpdir();
  const tmpNew = path.join(tmpDir, `ccserver-new-${id}${ext}`);
  const exitFile = path.join(tmpDir, `ccserver-exit-${id}`);
  const channel = `ccserver-${id}`;

  fs.writeFileSync(tmpNew, new_file_contents, 'utf8');
  logger.debug('openDiff', 'wrote tmp', tmpNew, 'tab:', tab_name);

  const oldExists = fs.existsSync(old_file_path);
  const leftPath = oldExists ? old_file_path : '/dev/null';

  const nvimCmd =
    `nvim -d ${shellQuote(leftPath)} ${shellQuote(tmpNew)} ` +
    `-c ${shellQuote('wincmd K')} -c ${shellQuote('wincmd =')} ` +
    `-c ${shellQuote('cnoreabbrev <expr> q  getcmdtype()==":" && getcmdline()=="q"  ? "cq" : "q"')} ` +
    `-c ${shellQuote('cnoreabbrev <expr> q! getcmdtype()==":" && getcmdline()=="q!" ? "cq" : "q!"')} ` +
    `-c ${shellQuote('cnoreabbrev <expr> qa getcmdtype()==":" && getcmdline()=="qa" ? "cq" : "qa"')} ` +
    `-c ${shellQuote('cnoreabbrev <expr> qa! getcmdtype()==":" && getcmdline()=="qa!" ? "cq" : "qa!"')}; ` +
    `echo $? > ${shellQuote(exitFile)}; ` +
    `tmux wait-for -S ${shellQuote(channel)}`;

  const windowName = `diff:${path.basename(old_file_path).slice(0, 30)}`;

  logger.debug('openDiff', 'spawning tmux new-window', windowName);
  const newWin = spawnSync('tmux', ['new-window', '-a', '-n', windowName, nvimCmd], { stdio: 'inherit' });
  if (newWin.status !== 0) {
    fs.unlinkSync(tmpNew);
    const err = new Error('Failed to create tmux window');
    err.code = -32000;
    throw err;
  }

  await new Promise((resolve, reject) => {
    const waiter = spawn('tmux', ['wait-for', channel]);
    waiter.on('exit', (code) => (code === 0 ? resolve() : reject(new Error(`wait-for exited ${code}`))));
    waiter.on('error', reject);
  });

  let exitCode = 1;
  try {
    exitCode = parseInt(fs.readFileSync(exitFile, 'utf8').trim(), 10);
    if (Number.isNaN(exitCode)) exitCode = 1;
  } catch (e) {
    logger.warn('openDiff', 'failed to read exit file', e.message);
  }

  const finalContents = fs.readFileSync(tmpNew, 'utf8');

  try { fs.unlinkSync(tmpNew); } catch {}
  try { fs.unlinkSync(exitFile); } catch {}

  if (exitCode === 0) {
    logger.info('openDiff', 'FILE_SAVED', tab_name);
    return {
      content: [
        { type: 'text', text: 'FILE_SAVED' },
        { type: 'text', text: finalContents },
      ],
    };
  }

  logger.info('openDiff', 'DIFF_REJECTED', tab_name);
  return {
    content: [
      { type: 'text', text: 'DIFF_REJECTED' },
      { type: 'text', text: tab_name },
    ],
  };
}
