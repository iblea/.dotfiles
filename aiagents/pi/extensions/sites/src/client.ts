import { SitesError, Secrets } from './security.ts';
import type { Identity, Json, Api } from './types.ts';
import { validateSchema } from './schema.ts';

export const ENDPOINT = 'https://chatgpt.com/backend-api/ps/mcp';
export const OPERATIONS = new Set(['check_slug_availability', 'create_site', 'get_site', 'list_sites', 'create_source_repository_write_credential', 'save_site_version', 'list_site_versions', 'get_site_version', 'deploy_private_site_version', 'get_deployment_status']);

export function checkArguments(schema: Json, args: Json) {
  if (!schema || !args || typeof args !== 'object' || Array.isArray(args)) throw new SitesError('invalid_arguments', 'Sites 인자는 JSON 객체여야 해.');
  for (const key of schema.required ?? []) if (!Object.hasOwn(args, key) || args[key] === undefined) throw new SitesError('schema_changed', `Sites 서버가 새 필수 인자를 요구해: ${key}`);
  for (const key of Object.keys(args)) if (!Object.hasOwn(schema.properties ?? {}, key)) throw new SitesError('schema_changed', `Sites 서버가 인자를 지원하지 않아: ${key}`);
  validateSchema(schema, args);
}

export async function readRpcResponse(response: Response, id: number | undefined, secrets: Secrets): Promise<any> {
  if (!response.body) return undefined;
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let text = '', size = 0;
  const eventStream = response.headers.get('content-type')?.includes('text/event-stream');
  function parse(value: string) { try { const result = JSON.parse(value); secrets.learn(result); return result; } catch { throw new SitesError('invalid_response', 'Sites가 올바른 JSON 응답을 반환하지 않았어.'); } }
  try {
    while (true) {
      const chunk = await reader.read();
      if (chunk.done) break;
      size += chunk.value.byteLength;
      if (size > 4 * 1024 * 1024) throw new SitesError('response_too_large', 'Sites 응답이 안전 크기 제한을 넘었어.');
      text += decoder.decode(chunk.value, { stream: true });
      if (eventStream) {
        text = text.replace(/\r\n/g, '\n');
        let boundary;
        while ((boundary = text.indexOf('\n\n')) !== -1) {
          const event = text.slice(0, boundary); text = text.slice(boundary + 2);
          const data = event.split('\n').filter(line => line.startsWith('data:')).map(line => line.slice(5).trimStart()).join('\n');
          if (!data || data === '[DONE]') continue;
          const result = parse(data);
          if (result.id === id && ('result' in result || 'error' in result)) return result;
        }
      }
    }
    text += decoder.decode();
    if (!text.trim()) return undefined;
    if (eventStream) {
      const data = text.split('\n').filter(line => line.startsWith('data:')).map(line => line.slice(5).trimStart()).join('\n');
      if (!data || data === '[DONE]') return undefined;
      const result = parse(data); return result.id === id ? result : undefined;
    }
    return parse(text);
  } finally { await reader.cancel().catch(() => {}); reader.releaseLock(); }
}

export class SitesClient implements Api {
  private headers: Record<string, string>;
  private requestId = 0;
  private tools?: Map<string, Json>;
  constructor(public identity: Identity, private secrets: Secrets, private signal?: AbortSignal, private fetcher: typeof fetch = fetch) {
    secrets.add(identity.token);
    this.headers = { authorization: `Bearer ${identity.token}`, 'chatgpt-account-id': identity.accountId, 'x-openai-product-sku': 'codex', originator: 'pi', accept: 'application/json, text/event-stream', 'content-type': 'application/json' };
  }
  private async rpc(method: string, params: Json, notification = false) {
    this.signal?.throwIfAborted();
    const id = notification ? undefined : ++this.requestId;
    let response: Response;
    try {
      response = await this.fetcher(ENDPOINT, { method: 'POST', redirect: 'error', headers: this.headers, signal: AbortSignal.any([AbortSignal.timeout(120000), ...(this.signal ? [this.signal] : [])]), body: JSON.stringify({ jsonrpc: '2.0', ...(id === undefined ? {} : { id }), method, params }) });
    } catch { throw new SitesError('connection_interrupted', 'Sites 연결이 중단됐어. 쓰기 요청은 자동 재시도하지 않아. sites_status로 먼저 확인해.'); }
    const session = response.headers.get('mcp-session-id');
    if (session) { this.secrets.add(session); this.headers['mcp-session-id'] = session; }
    const result = await readRpcResponse(response, id, this.secrets);
    if (!response.ok || result?.error) {
      const serialized = JSON.stringify(result ?? {});
      if (/sites_publication_terms_required/i.test(serialized)) throw new SitesError('terms_required', 'ChatGPT Sites 이용약관에 브라우저에서 동의한 뒤 다시 시도해: https://chatgpt.com/sites');
      throw new SitesError('backend_error', `Sites 요청이 거부됐어 (HTTP ${response.status}${result?.error?.code ? `, RPC ${result.error.code}` : ''}). 계정 권한과 현재 작업 상태를 확인해.`);
    }
    if (notification) return undefined;
    if (!result || result.id !== id || !('result' in result)) throw new SitesError('invalid_response', 'Sites 응답 ID 또는 결과가 요청과 맞지 않아.');
    return result.result;
  }
  async discover() {
    if (this.tools) return this.tools;
    const initialized = await this.rpc('initialize', { protocolVersion: '2025-03-26', capabilities: {}, clientInfo: { name: 'pi-sites', version: '0.1.0' } });
    this.headers['mcp-protocol-version'] = initialized.protocolVersion ?? '2025-03-26';
    await this.rpc('notifications/initialized', {}, true);
    const tools = new Map<string, Json>();
    const cursors = new Set<string>();
    let cursor: string | undefined;
    for (let page = 0; page < 20; page++) {
      const result = await this.rpc('tools/list', cursor ? { cursor } : {});
      if (!Array.isArray(result?.tools)) throw new SitesError('invalid_catalog', 'Sites 도구 목록 형식이 달라졌어.');
      for (const tool of result.tools) if (typeof tool.name === 'string' && tool.name.startsWith('sites.') && OPERATIONS.has(tool.name.slice(6))) tools.set(tool.name.slice(6), tool);
      cursor = result.nextCursor;
      if (!cursor) { this.tools = tools; return tools; }
      if (cursors.has(cursor)) break;
      cursors.add(cursor);
    }
    throw new SitesError('catalog_pagination', 'Sites 도구 목록 페이지를 안전하게 조회하지 못했어.');
  }
  async call(name: string, args: Json) {
    if (!OPERATIONS.has(name)) throw new SitesError('unsupported_operation', '이 확장에서 허용하지 않는 Sites 작업이야.');
    const tool = (await this.discover()).get(name);
    if (!tool) throw new SitesError('tool_unavailable', `현재 계정에서 sites.${name}을 사용할 수 없어.`);
    checkArguments(tool.inputSchema, args);
    const result = await this.rpc('tools/call', { name: tool.name, arguments: args });
    this.secrets.learn(result);
    if (result?.isError) throw new SitesError('tool_failed', `sites.${name}이 실패했어. 쓰기 작업은 상태 확인 없이 재시도하지 않아.`);
    let value = result?.structuredContent;
    if (value === undefined) {
      const text = (result?.content ?? []).filter((item: Json) => item.type === 'text').map((item: Json) => item.text).join('\n');
      try { value = JSON.parse(text); } catch { throw new SitesError('invalid_result', `sites.${name}이 구조화된 결과를 반환하지 않았어.`); }
    }
    this.secrets.learn(value);
    return value?.result ?? value;
  }
}
