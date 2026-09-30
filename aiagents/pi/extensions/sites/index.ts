import { join, resolve } from 'node:path';
import { Type } from 'typebox';
import { getAgentDir, withFileMutationQueue } from '@earendil-works/pi-coding-agent';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { resolveIdentity } from './src/auth.ts';
import { SitesClient } from './src/client.ts';
import { Secrets, SitesError } from './src/security.ts';
import { SitesService } from './src/service.ts';
import { validateSchema } from './src/schema.ts';

const pathParam = Type.Optional(Type.String({ description: 'Absolute Site Git repository root. Defaults to current directory.' }));
const waitParam = Type.Optional(Type.Integer({ minimum: 0, maximum: 120 }));
const object = (properties: Record<string, any>) => Type.Object(properties, { additionalProperties: false });
const definitions = [
  { action: 'doctor', description: 'Check Pi ChatGPT OAuth and live Sites capabilities without creating, pushing, or deploying anything.', schema: object({}) },
  { action: 'list', description: 'List ChatGPT Sites available to the selected account. Does not change any Site. Secret credentials are never returned.', schema: object({ limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 50 })), cursor: Type.Optional(Type.String()) }) },
  { action: 'get', description: 'Inspect Site metadata and owner-private access. Provide project_id or a local Site path. Does not return tokens, environment secrets, or viewer identities.', schema: object({ path: pathParam, project_id: Type.Optional(Type.String()) }) },
  { action: 'create', description: 'Register a NEW private Site for an existing dedicated local Git repository, and persist its project_id. Use only on an explicit user request to create/publish a Site, not for research or ordinary report generation. Does not commit, push, or deploy. Reuse an existing hosting.json binding instead of creating another Site.', schema: object({ path: pathParam, title: Type.String({ minLength: 1, maxLength: 200 }), slug: Type.String({ minLength: 5, maxLength: 63 }) }) },
  { action: 'publish', description: 'Publish explicitly user-requested, clean committed Site source to its verified owner-private ChatGPT Site. Requires committed .openai/hosting.json; never commits changes automatically. Runs check_command, or npm run build when present, then authenticated Git push, source-only version save, remote build, and private deployment. Runtime approval is required. Reconciles an interrupted operation before retrying. No public/shared deployment, archive upload, or publish-on-push experiment.', schema: object({ path: pathParam, check_command: Type.Optional(Type.Array(Type.String(), { minItems: 1 })), save_only: Type.Optional(Type.Boolean()), wait_seconds: waitParam }) },
  { action: 'status', description: 'Read and reconcile the selected local Site publication receipt and deployment status. Never creates a Site, issues Git credentials, pushes, saves, deploys, or changes access. Continue this after a publish timeout or cancellation.', schema: object({ path: pathParam, wait_seconds: waitParam }) },
] as const;
const help = '사용법: /sites doctor | list | get | create | publish | status [JSON]\n예: /sites create {"path":"/abs/site","title":"보고서","slug":"my-report"}\n예: /sites publish {"path":"/abs/site","wait_seconds":30}\n새 프로젝트: git init → 소스 준비 → sites_create → hosting.json 포함 커밋 → sites_publish\n이 버전은 비공개·원격 빌드만 지원해. 공개 전환·삭제·토큰 회전은 제공하지 않아.';

export default function sitesExtension(pi: ExtensionAPI) {
  const active = new Set<AbortController>();
  const cancel = () => { for (const controller of active) controller.abort(); active.clear(); };
  pi.on('session_shutdown', cancel);
  pi.on('session_start', cancel);

  async function perform(action: string, params: Record<string, any>, ctx: ExtensionContext, signal?: AbortSignal, update?: (text: string) => void) {
    const controller = new AbortController(); active.add(controller);
    const merged = AbortSignal.any([controller.signal, ...([signal, ctx.signal].filter(Boolean) as AbortSignal[])]);
    const secrets = new Secrets();
    try {
      const path = resolve(ctx.cwd, params.path ?? '.');
      const identity = await resolveIdentity(ctx.modelRegistry, secrets);
      if (action === 'create' || action === 'publish') {
        if (ctx.hasUI) {
          const allowed = await ctx.ui.confirm(action === 'create' ? 'ChatGPT Sites 등록' : params.save_only ? 'ChatGPT Sites 소스 저장' : 'ChatGPT Sites 비공개 게시', `대상: ${path}\n계정: ${identity.accountId.slice(0, 8)}…\n${action === 'create' ? `새 비공개 사이트: ${params.title} (${params.slug})` : '커밋된 소스를 외부 Sites 저장소로 전송해. 공개 범위는 넓히지 않아.'}`);
          if (!allowed) throw new SitesError('approval_declined', 'Sites 변경 작업을 취소했어.');
        } else if (process.env.PI_SITES_ALLOW_WRITE !== '1') {
          throw new SitesError('approval_required', '대화형 승인 없이 쓰기 작업을 수행하지 않아. headless 자동화는 운영자가 PI_SITES_ALLOW_WRITE=1로 pi를 시작해야 해.');
        }
      }
      const api = new SitesClient(identity, secrets, merged);
      const service = new SitesService(api, secrets, join(getAgentDir(), 'sites', 'state'), merged, { progress: message => { update?.(message); if (ctx.hasUI) ctx.ui.setStatus('sites', message); } });
      let result;
      switch (action) {
        case 'doctor': result = await service.doctor(); break;
        case 'list': result = await service.list(params.limit, params.cursor); break;
        case 'get': result = await service.get(path, params.project_id); break;
        case 'create': result = await withFileMutationQueue(join(path, '.openai', 'hosting.json'), () => service.create(path, params.title, params.slug)); break;
        case 'publish': result = await service.publish(path, params); break;
        case 'status': result = await service.status(path, params.wait_seconds ?? 0); break;
        default: throw new SitesError('invalid_action', help);
      }
      const clean = (value: any): any => typeof value === 'string' ? secrets.text(value) : Array.isArray(value) ? value.map(clean) : value && typeof value === 'object' ? Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, clean(entry)])) : value;
      const safe = clean(result);
      const text = JSON.stringify(safe, null, 2);
      if (Buffer.byteLength(text) > 16000) return { content: [{ type: 'text' as const, text: text.slice(0, 12000) + '\n[출력이 잘렸어. 더 작은 limit으로 조회해.]' }], details: { truncated: true } };
      return { content: [{ type: 'text' as const, text }], details: safe };
    } catch (error) { throw secrets.error(error); }
    finally { active.delete(controller); secrets.clear(); if (ctx.hasUI) ctx.ui.setStatus('sites', undefined); }
  }

  for (const definition of definitions) pi.registerTool({
    name: `sites_${definition.action}`,
    label: `Sites ${definition.action}`,
    description: definition.description,
    parameters: definition.schema,
    executionMode: 'sequential',
    promptGuidelines: definition.action === 'publish' ? ['Sites publishing requires an explicit user publishing request. Never enable headless write authorization yourself. Commit only intended source files; never force-push or expose tokens. A pending deployment is not success. Use sites_status to reconcile interrupted work.'] : undefined,
    async execute(_id, params, signal, onUpdate, ctx) {
      return perform(definition.action, params, ctx, signal, text => onUpdate?.({ content: [{ type: 'text', text }], details: undefined }));
    },
  });

  pi.registerCommand('sites', {
    description: 'ChatGPT Sites 조회·비공개 게시. /sites로 사용법 확인',
    getArgumentCompletions(prefix) { const values = definitions.map(value => value.action).filter(value => value.startsWith(prefix)); return values.length ? values.map(value => ({ value, label: value })) : null; },
    async handler(input, ctx) {
      const match = input.trim().match(/^(\S+)(?:\s+([\s\S]+))?$/);
      if (!match) { pi.sendMessage({ customType: 'sites-result', content: help, display: true }); return; }
      const [, action, raw] = match;
      try {
        if (!definitions.some(value => value.action === action)) throw new SitesError('invalid_action', help);
        const params = raw ? JSON.parse(raw) : {};
        if (!params || typeof params !== 'object' || Array.isArray(params)) throw new SitesError('invalid_arguments', '인자는 JSON 객체로 입력해.');
        const definition = definitions.find(value => value.action === action)!;
        validateSchema(definition.schema, params);
        const result = await perform(action, params, ctx);
        pi.sendMessage({ customType: 'sites-result', content: result.content, details: result.details, display: true });
      } catch (error) {
        const message = error instanceof SitesError ? error.message : '인자나 작업을 처리하지 못했어. /sites 사용법을 확인해.';
        if (ctx.hasUI) ctx.ui.notify(message, 'error');
        else pi.sendMessage({ customType: 'sites-result', content: message, display: true });
      }
    },
  });
}
