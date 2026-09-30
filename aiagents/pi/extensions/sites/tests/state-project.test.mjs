import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile, lstat, symlink, unlink, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { join } from 'node:path';
import { StateStore } from '../src/state.ts';
import { projectRoot, readHosting, bindProject } from '../src/project.ts';
import { fixture, receipt, IDENTITY, PROJECT, code } from './helpers.mjs';
const statePath = (f, suffix = 'json') => join(f.stateDir, `${createHash('sha256').update(f.root).digest('hex')}.${suffix}`);

test('project: missing manifest returns empty object; binding preserves every unrelated key', async () => {
  const f = await fixture('manifest', false); assert.deepEqual(await readHosting(f.root), {});
  await mkdir(join(f.root, '.openai'));
  const original = { custom: { a: [1, 2] }, future_field: true, title: 'synthetic-title' };
  await writeFile(join(f.root, '.openai', 'hosting.json'), JSON.stringify(original));
  await bindProject(f.root, PROJECT);
  assert.deepEqual(await readHosting(f.root), { ...original, project_id: PROJECT });
  await bindProject(f.root, PROJECT); assert.deepEqual(await readHosting(f.root), { ...original, project_id: PROJECT });
  assert.equal((await lstat(join(f.root, '.openai', 'hosting.json'))).mode & 0o777, 0o600);
  assert.deepEqual(await readdir(join(f.root, '.openai')), ['hosting.json']);
});
test('project: existing binding cannot be overwritten', async () => {
  const f = await fixture('binding'); const before = await readFile(join(f.root, '.openai', 'hosting.json'), 'utf8');
  await assert.rejects(bindProject(f.root, 'another-site'), code('binding_mismatch'));
  assert.equal(await readFile(join(f.root, '.openai', 'hosting.json'), 'utf8'), before);
});
for (const [name, text] of [['malformed', '{oops'], ['null', 'null'], ['array', '[]'], ['primitive', '1'], ['oversize', JSON.stringify({ data: 'x'.repeat(65537) })]]) test(`project: refuses ${name} manifest without overwriting it`, async () => {
  const f = await fixture('invalid-manifest'); await writeFile(join(f.root, '.openai', 'hosting.json'), text);
  await assert.rejects(readHosting(f.root), code('invalid_manifest')); await assert.rejects(bindProject(f.root, PROJECT), code('invalid_manifest'));
  assert.equal(await readFile(join(f.root, '.openai', 'hosting.json'), 'utf8'), text);
});
for (const directory of [false, true]) test(`project: refuses ${directory ? '.openai directory' : 'hosting file'} symlinks`, async () => {
  const f = await fixture('manifest-symlink', false); const target = join(f.base, 'target');
  if (directory) { await mkdir(target); await writeFile(join(target, 'hosting.json'), '{}'); await symlink(target, join(f.root, '.openai')); }
  else { await mkdir(join(f.root, '.openai')); await writeFile(target, '{}'); await symlink(target, join(f.root, '.openai', 'hosting.json')); }
  await assert.rejects(projectRoot(f.root), code('manifest_symlink')); await assert.rejects(bindProject(f.root, PROJECT), code('manifest_symlink'));
  assert.equal(await readFile(directory ? join(target, 'hosting.json') : target, 'utf8'), '{}');
});
test('project: missing and regular-file roots are rejected', async () => { const f = await fixture('root'); await assert.rejects(projectRoot(join(f.base, 'missing')), code('invalid_project')); await assert.rejects(projectRoot(join(f.root, '.openai', 'hosting.json')), code('invalid_project')); });

test('state: absent state, atomic roundtrip and restrictive permissions', async () => {
  const f = await fixture('state'), store = new StateStore(f.stateDir, f.root, IDENTITY.accountId);
  assert.equal(await store.load(), undefined);
  const value = receipt(f.root); await store.save(value); const loaded = await store.load();
  assert.equal(loaded.root, f.root); assert.equal(loaded.accountId, IDENTITY.accountId); assert.equal(loaded.phase, 'prepared'); assert.equal(loaded.sha, value.sha);
  assert.ok(Date.parse(loaded.updatedAt));
  assert.equal((await lstat(statePath(f))).mode & 0o777, 0o600); assert.equal((await lstat(f.stateDir)).mode & 0o777, 0o700);
  assert.deepEqual(await readdir(f.stateDir), [statePath(f).split('/').at(-1)]);
});
for (const [name, mutate] of [['account', r => r.accountId = 'other-account'], ['root', r => r.root += '-other'], ['format', r => r.format = 2]]) test(`state: ${name} binding mismatch never silently accepted`, async () => {
  const f = await fixture('state-binding'); await mkdir(f.stateDir); const value = receipt(f.root); mutate(value); await writeFile(statePath(f), JSON.stringify(value));
  await assert.rejects(new StateStore(f.stateDir, f.root, IDENTITY.accountId).load(), code('state_account_mismatch', 'invalid_state'));
});
test('state: account switch uses same project key and blocks old receipt', async () => { const f = await fixture('account-switch'); await new StateStore(f.stateDir, f.root, IDENTITY.accountId).save(receipt(f.root)); await assert.rejects(new StateStore(f.stateDir, f.root, 'different-account').load(), code('state_account_mismatch')); });
test('state: malformed JSON is not overwritten by load', async () => { const f = await fixture('corrupt'); await mkdir(f.stateDir); await writeFile(statePath(f), 'synthetic-corrupt'); await assert.rejects(new StateStore(f.stateDir, f.root, IDENTITY.accountId).load(), code('invalid_state')); assert.equal(await readFile(statePath(f), 'utf8'), 'synthetic-corrupt'); });
for (const suffix of ['json', 'lock']) test(`state: refuses ${suffix} symlink`, async () => { const f = await fixture('state-symlink'); await mkdir(f.stateDir); const target = join(f.base, 'target'); await writeFile(target, 'keep'); await symlink(target, statePath(f, suffix)); const store = new StateStore(f.stateDir, f.root, IDENTITY.accountId); await assert.rejects(suffix === 'json' ? store.load() : store.lock(), code('unsafe_state')); if (suffix === 'json') await assert.rejects(store.save(receipt(f.root)), code('unsafe_state')); assert.equal(await readFile(target, 'utf8'), 'keep'); });
test('state: lock is exclusive across instances/accounts, release is idempotent and reacquirable', async () => {
  const f = await fixture('lock'), a = new StateStore(f.stateDir, f.root, IDENTITY.accountId), b = new StateStore(f.stateDir, f.root, 'other-account');
  const release = await a.lock(); assert.equal((await lstat(statePath(f, 'lock'))).mode & 0o777, 0o600);
  await assert.rejects(a.lock(), code('project_locked')); await assert.rejects(b.lock(), code('project_locked'));
  await release(); await release(); const release2 = await b.lock(); await release2();
});
test('state: old lease cannot unlink a replacement lock', async () => { const f = await fixture('lease'), store = new StateStore(f.stateDir, f.root, IDENTITY.accountId); const release = await store.lock(); const path = statePath(f, 'lock'); await unlink(path); await writeFile(path, JSON.stringify({ lease: 'replacement-lease' })); await release(); assert.equal(JSON.parse(await readFile(path, 'utf8')).lease, 'replacement-lease'); });
test('state: concurrent lock attempts yield exactly one winner', async () => { const f = await fixture('race'); const results = await Promise.allSettled(Array.from({ length: 8 }, () => new StateStore(f.stateDir, f.root, IDENTITY.accountId).lock())); const successes = results.filter(r => r.status === 'fulfilled'); assert.equal(successes.length, 1); for (const r of results.filter(r => r.status === 'rejected')) assert.equal(r.reason.code, 'project_locked'); await successes[0].value(); });
