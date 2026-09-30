import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveIdentity } from '../src/auth.ts';
import { Secrets, SitesError, ownerPrivate, safeSite, safeDeployment, cleanUrl, opaqueId } from '../src/security.ts';
import { IDENTITY, privateSite, code, URL } from './helpers.mjs';

function jwt(extra = {}) {
  const claims = { exp: Math.floor(Date.now() / 1000) + 600, 'https://api.openai.com/auth': { chatgpt_account_id: IDENTITY.accountId, chatgpt_account_user_id: IDENTITY.accountUserId }, 'https://api.openai.com/profile': { email: IDENTITY.email, email_verified: true }, ...extra };
  return `eyJhbGciOiJub25lIn0.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.synthetic-signature`;
}
const registry = token => ({ async getProviderAuth(provider) { assert.equal(provider, 'openai-codex'); return { auth: { apiKey: token } }; } });

test('auth: resolves registry OAuth and verified account profile without credential files', async () => {
  const secrets = new Secrets(), token = jwt();
  assert.deepEqual(await resolveIdentity(registry(token), secrets), { token, accountId: IDENTITY.accountId, oauthAccountUserId: IDENTITY.accountUserId, email: IDENTITY.email });
  assert.equal(secrets.text(token), '[REDACTED]');
});
test('auth: refresh errors never include underlying secrets', async () => {
  await assert.rejects(resolveIdentity({ async getProviderAuth() { throw new Error('synthetic-refresh-secret'); } }, new Secrets()), error => code('auth_refresh_failed')(error) && !error.message.includes('synthetic-refresh-secret'));
});
for (const token of [undefined, '', null, 12]) test(`auth: missing token ${String(token)}`, async () => { await assert.rejects(resolveIdentity(registry(token), new Secrets()), code('login_required')); });
for (const token of ['synthetic-api-key', 'a.not-json.c']) test(`auth: rejects non-OAuth ${token}`, async () => { await assert.rejects(resolveIdentity(registry(token), new Secrets()), code('oauth_required')); });
for (const [name, claims] of [
  ['expired', { exp: 1 }], ['expiry now', { exp: Math.floor(Date.now() / 1000) }], ['no expiry', { exp: undefined }], ['string expiry', { exp: '9999999999' }],
  ['no account', { 'https://api.openai.com/auth': {} }], ['header injection', { 'https://api.openai.com/auth': { chatgpt_account_id: 'x\r\nInjected: x' } }],
]) test(`auth: rejects ${name}`, async () => { await assert.rejects(resolveIdentity(registry(jwt(claims)), new Secrets()), code('invalid_oauth')); });
test('auth: unverified email is not an ownership proof', async () => {
  const identity = await resolveIdentity(registry(jwt({ 'https://api.openai.com/profile': { email: IDENTITY.email, email_verified: false } })), new Secrets());
  assert.equal(identity.email, undefined);
});

test('secrets: recursive learning, longest-first replacement and generic failures', () => {
  const secrets = new Secrets();
  secrets.learn({ nested: { token: 'synthetic-token-long', refresh_secret: 'synthetic-secret', password: 'synthetic-password', upload_url: 'https://upload.example.invalid/object?sig=fixture' } });
  secrets.add('synthetic-token');
  for (const secret of ['synthetic-token-long', 'synthetic-secret', 'synthetic-password']) assert.equal(secrets.text(secret), '[REDACTED]');
  const error = secrets.error(new SitesError('failure', 'synthetic-token-long Bearer unknown-token https://user:pass@example.invalid/a?sig=fixture'));
  assert.equal(error.code, 'failure');
  for (const part of ['synthetic-token', 'unknown-token', 'user:pass', 'sig=fixture']) assert.ok(!error.message.includes(part));
  assert.equal(secrets.error(new Error('raw-synthetic-password')).code, 'operation_failed');
  assert.ok(!secrets.error(new Error('raw-synthetic-password')).message.includes('raw-synthetic-password'));
  assert.ok(secrets.error(new SitesError('failure', 'x'.repeat(3000))).message.length <= 2000);
  secrets.clear(); assert.equal(secrets.text('synthetic-secret'), 'synthetic-secret');
});
test('secrets: JWT and credential-bearing URL fallback redaction', () => {
  const text = new Secrets().text(`oops ${jwt()} https://example.invalid/path?token=fixture#fragment`);
  assert.ok(!text.includes('eyJhb')); assert.ok(!text.includes('token=fixture'));
});

test('policy: exact owner-only policy is accepted', () => { assert.equal(ownerPrivate(privateSite(), IDENTITY), true); });
for (const [name, mutate] of [
  ['nonowner', s => s.current_user_role = 'editor'], ['public', s => s.access_mode = 'public'], ['policy public', s => s.access_policy.access_mode = 'public'],
  ['extra user', s => s.access_policy.allowed_users.push({ account_user_id: 'other' })], ['extra ID', s => s.access_policy.allowed_account_user_ids.push('other')],
  ['mismatched ID list', s => s.access_policy.allowed_account_user_ids[0] = 'other'], ['external visitor', s => s.access_policy.external_visitor_count = 1],
  ['missing visitor count', s => delete s.access_policy.external_visitor_count], ['editor', s => s.access_policy.allowed_editors.push('other')],
  ...['allowed_groups', 'allowed_workspace_group_ids', 'allowed_tenant_group_ids'].flatMap(key => [[`${key} populated`, s => s.access_policy[key].push('other')], [`${key} missing`, s => delete s.access_policy[key]]]),
]) test(`policy: rejects ${name}`, () => { const site = privateSite(); mutate(site); assert.equal(ownerPrivate(site, IDENTITY), false); });
test('policy: verified email fallback requires an actual nonempty account user ID', () => {
  const site = privateSite(); site.access_policy.allowed_account_user_ids = [undefined]; delete site.access_policy.allowed_users[0].account_user_id;
  assert.equal(ownerPrivate(site, { ...IDENTITY, accountUserId: undefined }), false);
});
test('policy: matching email cannot override conflicting known account user ID', () => {
  const site = privateSite(); site.access_policy.allowed_account_user_ids = ['other-user']; site.access_policy.allowed_users[0].account_user_id = 'other-user';
  assert.equal(ownerPrivate(site, IDENTITY), false);
});
test('policy: OAuth subject namespace mismatch permits only the verified owner email proof', async () => {
  const token = jwt({ 'https://api.openai.com/auth': { chatgpt_account_id: IDENTITY.accountId, chatgpt_account_user_id: 'user-synthetic-oauth-subject' } });
  const identity = await resolveIdentity(registry(token), new Secrets());
  assert.equal(identity.accountUserId, undefined);
  assert.equal(ownerPrivate(privateSite(), identity), true);
  assert.equal(ownerPrivate(privateSite(), { ...identity, email: undefined }), false);
  assert.equal(ownerPrivate(privateSite(), { ...identity, email: 'different@example.invalid' }), false);
});
test('policy: empty and non-string policy identity is not a proof', () => {
  for (const value of ['', ' ', null, 123]) {
    const site = privateSite(); site.access_policy.allowed_account_user_ids = [value]; site.access_policy.allowed_users[0].account_user_id = value;
    assert.equal(ownerPrivate(site, { ...IDENTITY, accountUserId: undefined }), false);
  }
});
test('policy: verified email fallback works when OAuth has no account-user claim', () => {
  const site = privateSite(); site.access_policy.allowed_users[0].email = IDENTITY.email.toUpperCase();
  assert.equal(ownerPrivate(site, { ...IDENTITY, accountUserId: undefined }), true);
});
test('output: site and deployment projection exclude credentials and viewer identities', () => {
  const site = safeSite(privateSite({ token: 'synthetic-token', environment: { SECRET: 'synthetic' }, title: 'x'.repeat(1000), expected_url: 'https://example.invalid/?secret=synthetic' }), IDENTITY);
  assert.equal(site.title.length, 512); assert.equal(site.owner_private_verified, true);
  assert.equal(site.token, undefined); assert.equal(site.access_policy, undefined); assert.equal(site.environment, undefined); assert.equal(site.expected_url, undefined);
  assert.equal(safeDeployment({ id: 'd', status: 'succeeded', url: URL }).failed, false);
  for (const status of ['failed', 'cancelled', 'unrecognized']) assert.equal(safeDeployment({ id: 'd', status }).failed, true);
});
for (const value of ['http://example.invalid/', 'https://u:p@example.invalid/', 'https://example.invalid/?q=x', 'https://example.invalid/#x', 'not-a-url', undefined]) test(`URL: refuses credential-bearing or unsafe ${value}`, () => { assert.equal(cleanUrl(value), undefined); });
test('ID: bounded nonempty and no control characters', () => {
  assert.equal(opaqueId('synthetic-id'), 'synthetic-id');
  for (const value of ['', ' ', 12, null, 'a'.repeat(513), 'a\n', 'a\r', 'a\0']) assert.throws(() => opaqueId(value), code('invalid_id'));
});
