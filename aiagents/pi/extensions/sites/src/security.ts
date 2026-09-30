import type { Identity, Json } from './types.ts';

export class SitesError extends Error {
  constructor(public code: string, message: string) { super(message); this.name = 'SitesError'; }
}

export class Secrets {
  private values = new Set<string>();
  add(value: unknown) { if (typeof value === 'string' && value.length > 0) this.values.add(value); }
  learn(value: unknown, depth = 0) {
    if (!value || typeof value !== 'object' || depth > 30) return;
    for (const [key, child] of Object.entries(value)) {
      if (/token|secret|password|authorization|cookie|download_url|upload_url/i.test(key)) {
        if (typeof child === 'string') this.add(child);
        else this.learn(child, depth + 1);
      } else this.learn(child, depth + 1);
    }
  }
  text(value: unknown): string {
    let text = String(value);
    for (const secret of [...this.values].sort((a, b) => b.length - a.length)) text = text.split(secret).join('[REDACTED]');
    return text.replace(/Bearer\s+[^\s"'<>]+/gi, 'Bearer [REDACTED]')
      .replace(/eyJ[\w-]+\.[\w-]+\.[\w-]+/g, '[REDACTED_JWT]')
      .replace(/https?:\/\/[^\s"<>]+/g, raw => {
        try { const url = new URL(raw); if (url.username || url.password || url.search) return `${url.origin}${url.pathname}?[REDACTED]`; } catch {}
        return raw;
      });
  }
  error(error: unknown): SitesError {
    return error instanceof SitesError ? new SitesError(error.code, this.text(error.message).slice(0, 2000))
      : new SitesError('operation_failed', 'Sites 작업에 실패했어. 저장된 단계는 유지돼. sites_status로 확인해.');
  }
  clear() { this.values.clear(); }
}

export function opaqueId(value: unknown, name = 'id'): string {
  if (typeof value !== 'string' || !value.trim() || value.length > 512 || /[\r\n\0]/.test(value)) throw new SitesError('invalid_id', `${name}가 유효하지 않아.`);
  return value;
}

export function cleanUrl(value: unknown): string | undefined {
  if (typeof value !== 'string') return;
  try { const u = new URL(value); if (u.protocol === 'https:' && !u.username && !u.password && !u.search && !u.hash) return u.href; } catch {}
}

export function ownerPrivate(site: Json, identity: Identity): boolean {
  const p = site?.access_policy;
  if (site?.current_user_role !== 'owner' || site.access_mode !== 'custom' || p?.access_mode !== 'custom') return false;
  if (!Array.isArray(p.allowed_account_user_ids) || p.allowed_account_user_ids.length !== 1 || !Array.isArray(p.allowed_users) || p.allowed_users.length !== 1) return false;
  for (const key of ['allowed_groups', 'allowed_workspace_group_ids', 'allowed_tenant_group_ids']) if (!Array.isArray(p[key]) || p[key].length) return false;
  if (p.external_visitor_count !== 0 || (p.allowed_editors && (!Array.isArray(p.allowed_editors) || p.allowed_editors.length))) return false;
  const user = p.allowed_users[0];
  if (typeof user?.account_user_id !== 'string' || !user.account_user_id.trim() || user.account_user_id !== p.allowed_account_user_ids[0]) return false;
  if (identity.accountUserId !== undefined) return Boolean(identity.accountUserId && user.account_user_id === identity.accountUserId);
  if (identity.oauthAccountUserId && user.account_user_id === identity.oauthAccountUserId) return true;
  return Boolean(identity.email && typeof user.email === 'string' && user.email.toLowerCase() === identity.email.toLowerCase());
}

export function safeSite(site: Json, identity?: Identity) {
  const output: Json = {};
  for (const key of ['id', 'title', 'slug', 'status', 'access_mode', 'current_user_role', 'latest_version_number']) {
    if (typeof site?.[key] === 'string' || typeof site?.[key] === 'number') output[key] = typeof site[key] === 'string' ? site[key].slice(0, 512) : site[key];
  }
  for (const key of ['current_live_url', 'expected_url']) { const url = cleanUrl(site?.[key]); if (url) output[key] = url; }
  if (identity) output.owner_private_verified = ownerPrivate(site, identity);
  return output;
}

export function safeDeployment(value: Json) {
  return { id: opaqueId(value.id, 'deployment_id'), version_id: value.version_id, status: value.status, url: cleanUrl(value.url), failed: !['pending', 'building', 'publishing', 'succeeded'].includes(value.status) };
}
