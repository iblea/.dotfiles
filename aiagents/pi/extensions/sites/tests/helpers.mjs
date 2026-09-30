import assert from 'node:assert/strict';
import { mkdtemp, mkdir, realpath, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Secrets, SitesError } from '../src/security.ts';
import { SitesService } from '../src/service.ts';
import { StateStore } from '../src/state.ts';

// Every suite imports this guard. All HTTP, Git, auth and service boundaries are synthetic.
globalThis.fetch = async () => { throw new Error('TEST SAFETY: real network is forbidden'); };
export const SHA = 'a'.repeat(40);
export const SHA2 = 'b'.repeat(40);
export const IDENTITY = Object.freeze({ token: 'synthetic-access-token', accountId: 'account-fixture', accountUserId: 'user-fixture', email: 'owner@example.invalid' });
export const PROJECT = 'site-fixture';
export const URL = 'https://fixture.chatgpt-sites.example.invalid/';
export const credential = (extra = {}) => ({ auth_mode: 'http_extra_header', token: 'synthetic-git-token', token_expires_at: '2099-01-01T00:00:00Z', remote_url: 'https://git.chatgpt-team.site/fixture/repo.git', branch: 'main', publish_on_push_accepted: false, ...extra });
export const privateSite = (extra = {}) => ({ id: PROJECT, title: 'Fixture', slug: 'fixture-site', current_user_role: 'owner', access_mode: 'custom', current_live_url: URL, access_policy: { access_mode: 'custom', allowed_account_user_ids: [IDENTITY.accountUserId], allowed_users: [{ account_user_id: IDENTITY.accountUserId, email: IDENTITY.email }], allowed_groups: [], allowed_workspace_group_ids: [], allowed_tenant_group_ids: [], external_visitor_count: 0, allowed_editors: [] }, ...extra });
export const code = (...codes) => error => { assert.ok(error instanceof SitesError, `expected SitesError; got ${error?.constructor?.name}: ${error?.message}`); assert.ok(codes.includes(error.code), `expected ${codes.join('|')}; got ${error.code}: ${error.message}`); return true; };
export async function fixture(name = 'fixture', linked = true) {
  const base = await realpath(await mkdtemp(join(tmpdir(), `pi-sites-offline-${name}-`)));
  const root = join(base, 'project');
  const stateDir = join(base, 'state');
  await mkdir(root);
  if (linked) { await mkdir(join(root, '.openai')); await writeFile(join(root, '.openai', 'hosting.json'), JSON.stringify({ project_id: PROJECT, custom: { preserve: true } })); }
  return { base, root, stateDir };
}
export function receipt(root, extra = {}) {
  return { format: 1, root, accountId: IDENTITY.accountId, projectId: PROJECT, phase: 'prepared', sha: SHA, startedAt: '2025-01-01T00:00:00Z', updatedAt: '2025-01-01T00:00:00Z', ...extra };
}
export async function harness(options = {}) {
  const f = await fixture('service', options.linked !== false);
  const calls = [], gitCalls = [], progress = [], sleeps = [];
  const versions = new Map();
  const deployments = new Map();
  const controls = { sha: SHA, site: privateSite(), dirty: false, checkError: undefined, afterCheck: undefined, handlers: {}, ...options.controls };
  const api = {
    identity: options.identity ?? { ...IDENTITY },
    async discover() { return new Map(['get_site', 'list_sites', 'create_site', 'check_slug_availability', 'create_source_repository_write_credential', 'save_site_version', 'get_site_version', 'list_site_versions', 'deploy_private_site_version', 'get_deployment_status'].map(name => [name, { inputSchema: { type: 'object', required: [] } }])); },
    async call(name, args) {
      calls.push({ name, args: structuredClone(args) });
      if (controls.handlers[name]) return controls.handlers[name](args);
      switch (name) {
        case 'get_site': return structuredClone(controls.site);
        case 'list_sites': return { items: [structuredClone(controls.site)], cursor: null };
        case 'check_slug_availability': return { available: true };
        case 'create_site': return structuredClone(controls.site);
        case 'create_source_repository_write_credential': return credential();
        case 'list_site_versions': return { items: [...versions.values()].map(v => structuredClone(v)), cursor: null };
        case 'save_site_version': {
          const v = { id: `version-${versions.size + 1}`, project_id: PROJECT, version_number: versions.size + 1, source: { commit_sha: args.commit_sha } };
          versions.set(v.id, v); return structuredClone(v);
        }
        case 'get_site_version': {
          assert.ok(versions.has(args.version_id), `unknown version ${args.version_id}`);
          return structuredClone(versions.get(args.version_id));
        }
        case 'deploy_private_site_version': {
          const d = { id: `deployment-${deployments.size + 1}`, project_id: PROJECT, version_id: args.version_id, status: 'succeeded', url: URL };
          deployments.set(d.id, d); versions.get(args.version_id).deployment_id = d.id; return structuredClone(d);
        }
        case 'get_deployment_status': {
          assert.ok(deployments.has(args.deployment_id), `unknown deployment ${args.deployment_id}`);
          return structuredClone(deployments.get(args.deployment_id));
        }
        default: throw new Error(`Unexpected API call: ${name}`);
      }
    },
  };
  const git = {
    async validateRoot() { gitCalls.push(['validateRoot']); },
    async inspect(id) { gitCalls.push(['inspect', id]); if (controls.dirty) throw new SitesError('dirty_worktree', 'synthetic dirty worktree'); return controls.sha; },
    async check(command) { gitCalls.push(['check', command]); if (controls.checkError) throw controls.checkError; await controls.afterCheck?.(); },
    async push(cred, sha, id) { gitCalls.push(['push', cred, sha, id]); await controls.onPush?.(); },
  };
  const secrets = new Secrets();
  const service = new SitesService(api, secrets, f.stateDir, options.signal, { gitFactory: root => { assert.equal(root, f.root); return git; }, progress: message => progress.push(message), sleep: async ms => { sleeps.push(ms); await controls.onSleep?.(); } });
  const store = new StateStore(f.stateDir, f.root, api.identity.accountId);
  return { ...f, api, service, store, secrets, controls, calls, git, gitCalls, progress, sleeps, versions, deployments, names: () => calls.map(c => c.name), count: name => calls.filter(c => c.name === name).length };
}
export function jsonResponse(value, init = {}) { return new Response(JSON.stringify(value), { headers: { 'content-type': 'application/json', ...init.headers }, ...init }); }
export function rpcFetcher({ tools = [], list, invoke, initialize = {}, headers = {} } = {}) {
  const requests = [];
  const fetcher = async (url, init) => {
    const body = JSON.parse(init.body);
    requests.push({ url, ...init, headers: { ...init.headers }, body });
    if (body.method === 'notifications/initialized') return new Response(null, { status: 202 });
    let result;
    if (body.method === 'initialize') result = { protocolVersion: '2025-03-26', ...initialize };
    else if (body.method === 'tools/list') result = list ? await list(body.params) : { tools };
    else if (body.method === 'tools/call') result = await invoke?.(body.params);
    else throw new Error(`Unexpected RPC ${body.method}`);
    return jsonResponse({ jsonrpc: '2.0', id: body.id, result }, { headers });
  };
  return { fetcher, requests };
}
export const tool = (name, schema = { type: 'object', properties: { project_id: { type: 'string' } }, required: ['project_id'], additionalProperties: false }) => ({ name: `sites.${name}`, inputSchema: schema });
