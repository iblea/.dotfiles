import * as openDiff from './openDiff.js';
import { logger } from '../logger.js';

const tools = new Map();

function register(name, mod) {
  tools.set(name, { name, schema: mod.schema, handler: mod.handler });
}

register('openDiff', openDiff);

export function getToolList() {
  return Array.from(tools.values()).map(({ name, schema }) => ({
    name,
    description: schema.description,
    inputSchema: schema.inputSchema,
  }));
}

export async function handleInvoke(toolName, args) {
  const tool = tools.get(toolName);
  if (!tool) {
    const err = new Error(`Tool not found: ${toolName}`);
    err.code = -32601;
    throw err;
  }
  logger.debug('tools', 'invoke', toolName);
  return await tool.handler(args || {});
}
