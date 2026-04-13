import { WebSocketServer } from 'ws';
import { logger } from './logger.js';
import { getToolList, handleInvoke } from './tools/index.js';

const MCP_PROTOCOL_VERSION = '2024-11-05';
const AUTH_HEADER = 'x-claude-code-ide-authorization';
const PING_INTERVAL_MS = 30000;

export function startServer({ authToken, onListening }) {
  const wssrv = new WebSocketServer({
    host: '127.0.0.1',
    port: 0,
    verifyClient: (info, done) => {
      const provided = info.req.headers[AUTH_HEADER];
      if (!provided || provided !== authToken) {
        logger.warn('server', 'rejected connection: bad auth token');
        return done(false, 401, 'Unauthorized');
      }
      done(true);
    },
  });

  wssrv.on('listening', () => {
    const { port } = wssrv.address();
    logger.info('server', `listening on 127.0.0.1:${port}`);
    if (onListening) onListening(port);
  });

  const pingTimer = setInterval(() => {
    wssrv.clients.forEach((ws) => {
      if (ws.isAlive === false) {
        logger.warn('server', 'terminating stale client');
        return ws.terminate();
      }
      ws.isAlive = false;
      ws.ping();
    });
  }, PING_INTERVAL_MS);

  wssrv.on('connection', (ws, req) => {
    ws.isAlive = true;
    logger.info('server', 'client connected from', req.socket.remoteAddress);

    ws.on('pong', () => { ws.isAlive = true; });

    ws.on('message', async (raw) => {
      let parsed;
      try {
        parsed = JSON.parse(raw.toString('utf8'));
      } catch {
        sendError(ws, null, -32700, 'Parse error', 'Invalid JSON');
        return;
      }

      if (!parsed || parsed.jsonrpc !== '2.0') {
        sendError(ws, parsed?.id ?? null, -32600, 'Invalid Request', 'Not JSON-RPC 2.0');
        return;
      }

      if (parsed.id !== undefined && parsed.id !== null) {
        await handleRequest(ws, parsed);
      } else {
        handleNotification(ws, parsed);
      }
    });

    ws.on('close', (code, reason) => {
      logger.info('server', 'client closed', code, reason?.toString?.());
    });

    ws.on('error', (err) => {
      logger.error('server', 'client error:', err.message);
    });
  });

  wssrv.on('close', () => {
    clearInterval(pingTimer);
  });

  return wssrv;
}

function sendResult(ws, id, result) {
  ws.send(JSON.stringify({ jsonrpc: '2.0', id, result }));
}

function sendError(ws, id, code, message, data) {
  ws.send(JSON.stringify({ jsonrpc: '2.0', id, error: { code, message, data } }));
}

async function handleRequest(ws, req) {
  const { method, params, id } = req;
  try {
    switch (method) {
      case 'initialize':
        return sendResult(ws, id, {
          protocolVersion: MCP_PROTOCOL_VERSION,
          capabilities: {
            logging: {},
            prompts: { listChanged: true },
            resources: { subscribe: true, listChanged: true },
            tools: { listChanged: true },
          },
          serverInfo: { name: 'ccserver', version: '0.1.0' },
        });

      case 'prompts/list':
        return sendResult(ws, id, { prompts: [] });

      case 'resources/list':
        return sendResult(ws, id, { resources: [] });

      case 'tools/list':
        return sendResult(ws, id, { tools: getToolList() });

      case 'tools/call': {
        const toolName = params?.name;
        const args = params?.arguments || {};
        logger.debug('server', 'tools/call', toolName);
        const result = await handleInvoke(toolName, args);
        return sendResult(ws, id, result);
      }

      default:
        return sendError(ws, id, -32601, 'Method not found', `Unknown method: ${method}`);
    }
  } catch (err) {
    logger.error('server', 'handler error:', err.message);
    return sendError(
      ws,
      id,
      err.code || -32603,
      err.message || 'Internal error',
      err.data || undefined
    );
  }
}

function handleNotification(ws, note) {
  logger.debug('server', 'notification', note.method);
}
