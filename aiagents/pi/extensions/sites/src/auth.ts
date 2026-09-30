import { SitesError, Secrets } from './security.ts';
import type { Identity } from './types.ts';

export async function resolveIdentity(registry: { getProviderAuth(provider: string): Promise<any> }, secrets: Secrets): Promise<Identity> {
  let resolved;
  try { resolved = await registry.getProviderAuth('openai-codex'); }
  catch { throw new SitesError('auth_refresh_failed', 'pi의 OpenAI Codex 인증 갱신에 실패했어. /login openai-codex 후 다시 시도해.'); }
  const token = resolved?.auth?.apiKey;
  if (typeof token !== 'string' || !token) throw new SitesError('login_required', '/login openai-codex로 ChatGPT 계정을 연결해야 해.');
  secrets.add(token);
  let claims;
  try { claims = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8')); }
  catch { throw new SitesError('oauth_required', 'Sites에는 ChatGPT OAuth 로그인이 필요해. 일반 OpenAI API 키는 사용할 수 없어.'); }
  const auth = claims['https://api.openai.com/auth'];
  const accountId = auth?.chatgpt_account_id;
  if (typeof accountId !== 'string' || !accountId || /[\r\n\0]/.test(accountId) || !Number.isFinite(claims.exp) || claims.exp * 1000 <= Date.now()) throw new SitesError('invalid_oauth', '유효한 ChatGPT OAuth 계정 정보를 확인하지 못했어. 다시 로그인해.');
  const profile = claims['https://api.openai.com/profile'];
  return { token, accountId, oauthAccountUserId: typeof auth.chatgpt_account_user_id === 'string' ? auth.chatgpt_account_user_id : undefined, email: profile?.email_verified === true && typeof profile.email === 'string' ? profile.email : undefined };
}
