import test from 'node:test';
import assert from 'node:assert/strict';
import { SitesClient, readRpcResponse, checkArguments, ENDPOINT } from '../src/client.ts';
import { Secrets } from '../src/security.ts';
import { IDENTITY, code, jsonResponse, rpcFetcher, tool } from './helpers.mjs';

function streamed(parts, type = 'text/event-stream') {
  let cancelled = false;
  const body = new ReadableStream({ start(controller) { for (const part of parts) controller.enqueue(typeof part === 'string' ? new TextEncoder().encode(part) : part); }, cancel() { cancelled = true; } });
  return { response: new Response(body, { headers: { 'content-type': type } }), cancelled: () => cancelled };
}
test('RPC: JSON body is decoded and secrets learned', async () => {
  const secrets = new Secrets();
  assert.deepEqual(await readRpcResponse(jsonResponse({ id: 2, result: { token: 'synthetic-response-token' } }), 2, secrets), { id: 2, result: { token: 'synthetic-response-token' } });
  assert.equal(secrets.text('synthetic-response-token'), '[REDACTED]');
});
test('RPC: SSE ignores comments, notifications, mismatched IDs and DONE, then cancels stream', async () => {
  const s = streamed([': heartbeat\r\n\r\n', 'data: {"method":"notice"}\n\n', 'data: {"id":99,"result":{}}\n\n', 'data: [DONE]\n\n', 'event: message\r\ndata: {"id":7,\r\ndata: "result":{"ok":true}}\r\n\r\n']);
  assert.deepEqual(await readRpcResponse(s.response, 7, new Secrets()), { id: 7, result: { ok: true } });
  assert.equal(s.cancelled(), true);
});
test('RPC: SSE handles arbitrary UTF-8, CRLF and delimiter chunk boundaries', async () => {
  const bytes = new TextEncoder().encode('data: {"id":3,"result":{"text":"한글"}}\r\n\r\n');
  const s = streamed([...bytes].map(byte => Uint8Array.of(byte)));
  assert.deepEqual(await readRpcResponse(s.response, 3, new Secrets()), { id: 3, result: { text: '한글' } });
});
test('RPC: SSE final event without separator and empty notifications', async () => {
  assert.deepEqual(await readRpcResponse(new Response('data: {"id":1,"result":{}}', { headers: { 'content-type': 'text/event-stream' } }), 1, new Secrets()), { id: 1, result: {} });
  assert.equal(await readRpcResponse(new Response(null, { status: 202 }), undefined, new Secrets()), undefined);
  assert.equal(await readRpcResponse(new Response('data: {"id":2,"result":{}}', { headers: { 'content-type': 'text/event-stream' } }), 1, new Secrets()), undefined);
});
test('RPC: malformed JSON is rejected without echoing raw body', async () => {
  await assert.rejects(readRpcResponse(new Response('synthetic-raw-secret'), 1, new Secrets()), error => code('invalid_response')(error) && !error.message.includes('synthetic-raw-secret'));
});
test('RPC: total bytes bounded at 4 MiB and reader cancelled on overflow', async () => {
  const s = streamed([new Uint8Array(4 * 1024 * 1024), Uint8Array.of(32)], 'application/json');
  await assert.rejects(readRpcResponse(s.response, 1, new Secrets()), code('response_too_large'));
  assert.equal(s.cancelled(), true);
});
test('RPC: exact 4 MiB JSON boundary accepted', async () => {
  const body = '{"id":1,"result":0}' + ' '.repeat(4 * 1024 * 1024 - 19);
  assert.equal(Buffer.byteLength(body), 4 * 1024 * 1024);
  assert.equal((await readRpcResponse(new Response(body), 1, new Secrets())).result, 0);
});

test('client: initialize/notify/list handshake, pinned endpoint, scoped headers, cache and pagination', async () => {
  const f = rpcFetcher({ headers: { 'mcp-session-id': 'synthetic-session' }, list: ({ cursor }) => !cursor ? { tools: [tool('get_site'), tool('delete_site'), { name: 'other.get_site' }], nextCursor: 'next-page' } : { tools: [tool('list_sites')] } });
  const secrets = new Secrets(), client = new SitesClient(IDENTITY, secrets, undefined, f.fetcher);
  assert.deepEqual([...(await client.discover()).keys()], ['get_site', 'list_sites']);
  await client.discover(); assert.equal(f.requests.length, 4);
  assert.deepEqual(f.requests.map(r => r.body.method), ['initialize', 'notifications/initialized', 'tools/list', 'tools/list']);
  for (const request of f.requests) { assert.equal(request.url, ENDPOINT); assert.equal(request.method, 'POST'); assert.equal(request.redirect, 'error'); assert.equal(request.headers.authorization, `Bearer ${IDENTITY.token}`); assert.equal(request.headers['chatgpt-account-id'], IDENTITY.accountId); assert.ok(request.signal instanceof AbortSignal); }
  assert.equal(f.requests[1].body.id, undefined); assert.equal(f.requests[2].headers['mcp-session-id'], 'synthetic-session');
  assert.equal(f.requests[2].headers['mcp-protocol-version'], '2025-03-26'); assert.deepEqual(f.requests[3].body.params, { cursor: 'next-page' });
  assert.equal(secrets.text('synthetic-session'), '[REDACTED]');
});
for (const [name, list, expected] of [
  ['repeated cursor', () => ({ tools: [], nextCursor: 'repeat' }), 2],
  ['20 page limit', (() => { let n = 0; return () => ({ tools: [], nextCursor: `page-${++n}` }); })(), 20],
]) test(`client: bounded discovery ${name}`, async () => { const f = rpcFetcher({ list }); await assert.rejects(new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher).discover(), code('catalog_pagination')); assert.equal(f.requests.filter(r => r.body.method === 'tools/list').length, expected); });
test('client: malformed catalog rejected', async () => { const f = rpcFetcher({ list: () => ({ tools: {} }) }); await assert.rejects(new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher).discover(), code('invalid_catalog')); });
test('client: forbidden operations are rejected before any HTTP request', async () => { const f = rpcFetcher(); const client = new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher); for (const name of ['delete_site', 'set_access_policy', 'deploy_public_site_version', 'sites.get_site']) await assert.rejects(client.call(name, {}), code('unsupported_operation')); assert.equal(f.requests.length, 0); });
test('client: unavailable and schema-incompatible calls never reach tools/call', async () => {
  const f = rpcFetcher({ tools: [tool('get_site')] }), client = new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher);
  await assert.rejects(client.call('save_site_version', {}), code('tool_unavailable'));
  await assert.rejects(client.call('get_site', {}), code('schema_changed'));
  await assert.rejects(client.call('get_site', { project_id: 'fixture', unexpected: true }), code('schema_changed'));
  assert.ok(!f.requests.some(r => r.body.method === 'tools/call'));
});
for (const [name, result, expected] of [
  ['structured content', { structuredContent: { id: 'fixture' } }, { id: 'fixture' }],
  ['result wrapper', { structuredContent: { result: { id: 'fixture' } } }, { id: 'fixture' }],
  ['JSON text content', { content: [{ type: 'text', text: '{"id":' }, { type: 'image', data: 'ignored' }, { type: 'text', text: '"fixture"}' }] }, { id: 'fixture' }],
]) test(`client: ${name}`, async () => { const f = rpcFetcher({ tools: [tool('get_site')], invoke: () => result }); assert.deepEqual(await new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher).call('get_site', { project_id: 'fixture' }), expected); });
for (const [name, result, expected] of [['tool isError', { isError: true, content: [{ type: 'text', text: 'synthetic-secret' }] }, 'tool_failed'], ['non-JSON text', { content: [{ type: 'text', text: 'synthetic-secret' }] }, 'invalid_result']]) test(`client: ${name} never exposes backend text`, async () => { const f = rpcFetcher({ tools: [tool('get_site')], invoke: () => result }); await assert.rejects(new SitesClient(IDENTITY, new Secrets(), undefined, f.fetcher).call('get_site', { project_id: 'fixture' }), error => code(expected)(error) && !error.message.includes('synthetic-secret')); });
for (const [name, fetcher, expected] of [
  ['HTTP error', async () => jsonResponse({ error: { code: -1, message: 'synthetic-secret' } }, { status: 403 }), 'backend_error'],
  ['RPC error', async () => jsonResponse({ id: 1, error: { code: -1, message: 'synthetic-secret' } }), 'backend_error'],
  ['terms required', async () => jsonResponse({ error: { message: 'sites_publication_terms_required synthetic-secret' } }, { status: 403 }), 'terms_required'],
  ['wrong ID', async () => jsonResponse({ id: 99, result: {} }), 'invalid_response'],
  ['transport failure', async () => { throw new Error('synthetic-secret'); }, 'connection_interrupted'],
]) test(`client: ${name} is redacted and never automatically retried`, async () => { let count = 0; await assert.rejects(new SitesClient(IDENTITY, new Secrets(), undefined, async (...args) => { count++; return fetcher(...args); }).discover(), error => code(expected)(error) && !error.message.includes('synthetic-secret')); assert.equal(count, 1); });
test('client: already cancelled request makes no HTTP call', async () => { const f = rpcFetcher(), controller = new AbortController(); controller.abort(); await assert.rejects(new SitesClient(IDENTITY, new Secrets(), controller.signal, f.fetcher).discover(), { name: 'AbortError' }); assert.equal(f.requests.length, 0); });
test('client: in-flight cancellation propagated to injected fetch with no retry', async () => {
  const controller = new AbortController(); let count = 0;
  const fetcher = async (_url, init) => { count++; return new Promise((_, reject) => { init.signal.addEventListener('abort', () => reject(init.signal.reason), { once: true }); controller.abort(); }); };
  await assert.rejects(new SitesClient(IDENTITY, new Secrets(), controller.signal, fetcher).discover(), code('connection_interrupted'));
  assert.equal(count, 1);
});

const schema = { type: 'object', additionalProperties: false, required: ['project_id'], properties: { project_id: { type: 'string', minLength: 1, maxLength: 8, pattern: '^[a-z]+$' }, count: { type: 'integer', minimum: 1, maximum: 50 }, mode: { enum: ['private'] }, flag: { const: false }, list: { type: 'array', minItems: 1, maxItems: 2, uniqueItems: true, items: { type: 'string' } }, nested: { type: 'object', required: ['ok'], additionalProperties: false, properties: { ok: { type: 'boolean' } } }, either: { anyOf: [{ type: 'string' }, { type: 'null' }] } } };
test('schema: accepts supported nested constraints', () => { assert.doesNotThrow(() => checkArguments(schema, { project_id: 'fixture', count: 50, mode: 'private', flag: false, list: ['a', 'b'], nested: { ok: true }, either: null })); });
for (const [name, extra] of [
  ['wrong type', { project_id: 4 }], ['empty string', { project_id: '' }], ['max length', { project_id: 'toolongfixture' }], ['pattern', { project_id: 'UPPER' }],
  ['integer', { count: 1.5 }], ['minimum', { count: 0 }], ['maximum', { count: 51 }], ['nonfinite', { count: Infinity }], ['enum', { mode: 'public' }], ['const', { flag: true }],
  ['array min', { list: [] }], ['array max', { list: ['a', 'b', 'c'] }], ['array type', { list: [4] }], ['array duplicate', { list: ['a', 'a'] }],
  ['nested required', { nested: {} }], ['nested unknown', { nested: { ok: true, extra: 1 } }], ['nested type', { nested: { ok: 'true' } }], ['anyOf', { either: 12 }],
]) test(`schema: rejects ${name}`, () => { assert.throws(() => checkArguments(schema, { project_id: 'fixture', ...extra }), code('schema_changed', 'invalid_arguments')); });
test('schema: Object.prototype keys are not declared schema properties', () => { assert.throws(() => checkArguments(schema, { project_id: 'fixture', toString: 'unexpected' }), code('schema_changed', 'invalid_arguments')); });
test('schema: unknown required reference fails closed', () => { assert.throws(() => checkArguments({ type: 'object', required: ['input'], properties: { input: { $ref: '#/$defs/unknown' } } }, { input: {} }), code('schema_changed', 'invalid_arguments')); });
