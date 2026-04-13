const LEVELS = { debug: 10, info: 20, warn: 30, error: 40 };
const currentLevel = LEVELS[process.env.CCSERVER_LOG_LEVEL || 'info'] ?? LEVELS.info;

function stamp() {
  return new Date().toISOString();
}

function log(level, mod, ...args) {
  if (LEVELS[level] < currentLevel) return;
  const prefix = `[${stamp()}] [${level}] [${mod}]`;
  const line = [prefix, ...args.map((a) => (typeof a === 'string' ? a : JSON.stringify(a)))].join(' ');
  process.stderr.write(line + '\n');
}

export const logger = {
  debug: (mod, ...args) => log('debug', mod, ...args),
  info: (mod, ...args) => log('info', mod, ...args),
  warn: (mod, ...args) => log('warn', mod, ...args),
  error: (mod, ...args) => log('error', mod, ...args),
};
