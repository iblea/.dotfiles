import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, writeFile, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { SitesError } from '../src/security.ts';
import { harness, receipt, privateSite, SHA, SHA2, PROJECT, URL, code } from './helpers.mjs';

const mutations = ['create_site', 'create_source_repository_write_credential', 'save_site_version', 'deploy_private_site_version'];
function noMutations(h, start = 0) { assert.deepEqual(h.calls.slice(start).filter(c => mutations.includes(c.name)), []); }
function seedVersion(h, extra = {}) { const v = { id: 'version-seeded', project_id: PROJECT, version_number: 3, source: { commit_sha: SHA }, ...extra }; h.versions.set(v.id, v); return v; }
function seedDeployment(h, version, extra = {}) { const d = { id: 'deployment-seeded', project_id: PROJECT, version_id: version.id, status: 'succeeded', url: URL, ...extra }; h.deployments.set(d.id, d); version.deployment_id = d.id; return d; }

test('publish: complete mocked progression binds SHA/version/deployment/private URL, preserving manifest', async () => {
  const h = await harness(); const manifest = await readFile(join(h.root, '.openai', 'hosting.json'), 'utf8');
  const result = await h.service.publish(h.root, { check_command: ['synthetic-check', '--offline'], wait_seconds: 0 });
  assert.equal(result.completed, true); assert.equal(result.phase, 'succeeded'); assert.equal(result.commit_sha, SHA); assert.equal(result.url, URL); assert.equal(result.build_mode, 'remote');
  assert.deepEqual(h.names(), ['get_site', 'create_source_repository_write_credential', 'list_site_versions', 'save_site_version', 'get_site', 'get_site_version', 'deploy_private_site_version', 'get_deployment_status', 'get_site_version', 'get_site']);
  assert.deepEqual(h.gitCalls.map(c => c[0]), ['inspect', 'check', 'inspect', 'push']);
  assert.deepEqual(h.gitCalls.find(c => c[0] === 'check')[1], ['synthetic-check', '--offline']);
  assert.deepEqual(h.calls.find(c => c.name === 'save_site_version').args, { project_id: PROJECT, commit_sha: SHA });
  assert.deepEqual(h.calls.find(c => c.name === 'deploy_private_site_version').args, { project_id: PROJECT, version_id: result.version_id });
  assert.equal(h.count('create_site'), 0); assert.ok(h.progress.length >= 5); assert.equal((await h.store.load()).phase, 'succeeded');
  assert.equal(await readFile(join(h.root, '.openai', 'hosting.json'), 'utf8'), manifest);
  const disk = await readFile(join(h.stateDir, (await readdir(h.stateDir)).find(p => p.endsWith('.json'))), 'utf8');
  assert.ok(!disk.includes('synthetic-git-token')); assert.ok(!disk.includes('synthetic-access-token'));
});
test('publish: update reuses project, creates only new version/deployment for new SHA', async () => {
  const h = await harness(); const first = await h.service.publish(h.root, { wait_seconds: 0 }); h.controls.sha = SHA2;
  const second = await h.service.publish(h.root, { wait_seconds: 0 });
  assert.equal(second.completed, true); assert.equal(second.commit_sha, SHA2); assert.equal(first.project_id, second.project_id);
  assert.notEqual(first.version_id, second.version_id); assert.notEqual(first.deployment_id, second.deployment_id);
  assert.equal(h.count('create_site'), 0); assert.equal(h.count('save_site_version'), 2); assert.equal(h.count('deploy_private_site_version'), 2);
});
test('publish: repeat succeeded SHA polls without new credential, push, save, deployment, or build', async () => {
  const h = await harness(); await h.service.publish(h.root, { wait_seconds: 0 }); const start = h.calls.length, gitStart = h.gitCalls.length;
  assert.equal((await h.service.publish(h.root, { wait_seconds: 0 })).completed, true); noMutations(h, start);
  assert.ok(!h.gitCalls.slice(gitStart).some(c => ['check', 'push'].includes(c[0])));
});
test('publish: save_only stops after source save; same SHA later deploys without reupload', async () => {
  const h = await harness(); const saved = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 });
  assert.equal(saved.phase, 'saved'); assert.equal(saved.completed, false); assert.equal(h.count('deploy_private_site_version'), 0); assert.equal(h.count('get_deployment_status'), 0);
  assert.equal((await h.store.load()).saveOnly, true);
  const repeated = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 }); assert.equal(repeated.version_id, saved.version_id);
  const deployed = await h.service.publish(h.root, { wait_seconds: 0 }); assert.equal(deployed.completed, true);
  assert.equal(h.count('create_source_repository_write_credential'), 1); assert.equal(h.count('save_site_version'), 1); assert.equal(h.count('deploy_private_site_version'), 1);
  assert.notEqual((await h.store.load()).saveOnly, true);
});
test('publish: explicitly completed save_only permits a new SHA update', async () => {
  const h = await harness(); await h.service.publish(h.root, { save_only: true, wait_seconds: 0 }); h.controls.sha = SHA2;
  const result = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 });
  assert.equal(result.phase, 'saved'); assert.equal(result.commit_sha, SHA2); assert.equal(h.count('save_site_version'), 2); assert.equal(h.count('deploy_private_site_version'), 0);
});
test('publish: interrupted non-save-only saved phase blocks a different SHA', async () => {
  const h = await harness(); const v = seedVersion(h); await h.store.save(receipt(h.root, { phase: 'saved', versionId: v.id, saveOnly: false })); h.controls.sha = SHA2;
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('publication_pending')); noMutations(h);
});

test('create: explicit registration persists manifest and receipt, never pushes or deploys', async () => {
  const h = await harness({ linked: false }); const result = await h.service.create(h.root, ' Synthetic title ', 'fixture-site');
  assert.equal(result.project_id, PROJECT); assert.equal(result.linked, true); assert.equal((await h.store.load()).phase, 'linked');
  assert.equal(JSON.parse(await readFile(join(h.root, '.openai', 'hosting.json'), 'utf8')).project_id, PROJECT);
  assert.deepEqual(h.names(), ['check_slug_availability', 'create_site']); assert.deepEqual(h.calls[1].args, { title: 'Synthetic title', slug: 'fixture-site' });
  assert.deepEqual(h.gitCalls.map(c => c[0]), ['validateRoot']);
  await assert.rejects(h.service.create(h.root, 'Synthetic title', 'fixture-site'), code('already_linked')); assert.equal(h.count('create_site'), 1);
});
test('create: existing manifest never triggers even a slug availability request', async () => { const h = await harness(); await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('already_linked')); assert.equal(h.calls.length, 0); });
test('create: unavailable slug does not create Site or persist create request', async () => { const h = await harness({ linked: false }); h.controls.handlers.check_slug_availability = () => ({ available: false }); await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('slug_unavailable')); assert.equal(h.count('create_site'), 0); assert.equal(await h.store.load(), undefined); });
for (const [title, slug] of [['', 'fixture-site'], ['x'.repeat(201), 'fixture-site'], ['Fixture', 'Abcde'], ['Fixture', 'abcd'], ['Fixture', 'abc--def'], ['Fixture', 'a'.repeat(64)]]) test(`create: rejects invalid title/slug ${slug.slice(0, 16)}-${title.length}`, async () => { const h = await harness({ linked: false }); await assert.rejects(h.service.create(h.root, title, slug), code('invalid_site')); assert.equal(h.calls.length, 0); });
test('create: uncertain response is recorded before request and never retried', async () => {
  const h = await harness({ linked: false });
  h.controls.handlers.create_site = async () => { assert.equal((await h.store.load()).phase, 'create_requested'); throw new SitesError('connection_interrupted', 'synthetic interruption'); };
  await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('connection_interrupted'));
  await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('create_uncertain'));
  assert.equal(h.count('create_site'), 1);
});
test('create: recorded project recovers local link without duplicate API mutation', async () => { const h = await harness({ linked: false }); await h.store.save(receipt(h.root, { phase: 'linked', sha: undefined, slug: 'fixture-site' })); const result = await h.service.create(h.root, 'Fixture', 'fixture-site'); assert.equal(result.recovered, true); assert.equal(result.project_id, PROJECT); noMutations(h); assert.equal(h.calls.length, 0); });
test('create: recovery refuses conflicting slug', async () => { const h = await harness({ linked: false }); await h.store.save(receipt(h.root, { phase: 'linked', sha: undefined, slug: 'existing-site' })); await assert.rejects(h.service.create(h.root, 'Fixture', 'different-site'), code('binding_mismatch')); noMutations(h); });

test('recovery: uncertain save never reissues save until same commit appears', async () => {
  const h = await harness(); h.controls.handlers.save_site_version = async () => { assert.equal((await h.store.load()).phase, 'save_requested'); throw new SitesError('connection_interrupted', 'synthetic interruption'); };
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('connection_interrupted'));
  const start = h.calls.length; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('save_uncertain')); noMutations(h, start);
  await assert.rejects(h.service.status(h.root), code('save_uncertain')); assert.equal(h.count('save_site_version'), 1);
  const version = seedVersion(h); const before = h.calls.length;
  const status = await h.service.status(h.root); assert.equal(status.phase, 'saved'); assert.equal(status.version_id, version.id); noMutations(h, before);
  assert.equal((await h.service.publish(h.root, { wait_seconds: 0 })).completed, true); assert.equal(h.count('save_site_version'), 1); assert.equal(h.count('create_source_repository_write_credential'), 1);
});
test('recovery: uncertain deployment reconciles new deployment ID read-only and never redeploys', async () => {
  const h = await harness(); h.controls.handlers.deploy_private_site_version = async () => { assert.equal((await h.store.load()).phase, 'deploy_requested'); throw new SitesError('connection_interrupted', 'synthetic interruption'); };
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('connection_interrupted'));
  const start = h.calls.length; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('deploy_uncertain')); noMutations(h, start);
  const version = [...h.versions.values()][0]; const d = seedDeployment(h, version);
  const before = h.calls.length; const status = await h.service.status(h.root); assert.equal(status.completed, true); assert.equal(status.deployment_id, d.id); noMutations(h, before);
  assert.equal(h.count('deploy_private_site_version'), 1);
});
test('recovery: prior deployment ID is not mistaken for result of uncertain new deployment', async () => {
  const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v); await h.store.save(receipt(h.root, { phase: 'deploy_requested', versionId: v.id, priorDeploymentId: d.id }));
  await assert.rejects(h.service.status(h.root), code('deploy_uncertain')); noMutations(h);
});
test('recovery: existing matching version prevents duplicate save, picks newest matching version only', async () => {
  const h = await harness(); seedVersion(h, { id: 'old-match', version_number: 2 }); seedVersion(h, { id: 'new-match', version_number: 5 }); seedVersion(h, { id: 'wrong-site', project_id: 'other', version_number: 99 }); seedVersion(h, { id: 'wrong-sha', source: { commit_sha: SHA2 }, version_number: 100 });
  const result = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 }); assert.equal(result.version_id, 'new-match'); assert.equal(h.count('save_site_version'), 0);
});
test('recovery: saved version with existing deployment is polled, not deployed twice', async () => { const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v); await h.store.save(receipt(h.root, { phase: 'saved', versionId: v.id })); const result = await h.service.publish(h.root, { wait_seconds: 0 }); assert.equal(result.deployment_id, d.id); assert.equal(result.completed, true); noMutations(h); });
test('recovery: matching commit on later page avoids duplicate save', async () => {
  const h = await harness(); const v = seedVersion(h); const seen = [];
  h.controls.handlers.list_site_versions = args => { seen.push(args.cursor); return args.cursor ? { items: [v], cursor: null } : { items: [{ ...v, source: { commit_sha: SHA2 } }], cursor: 'next-page' }; };
  assert.equal((await h.service.publish(h.root, { save_only: true, wait_seconds: 0 })).version_id, v.id); assert.deepEqual(seen, [undefined, 'next-page']); assert.equal(h.count('save_site_version'), 0);
});
for (const repeat of [true, false]) test(`recovery: ${repeat ? 'repeated cursor' : '20-page bound'} prevents blind save`, async () => {
  const h = await harness(); let pages = 0; h.controls.handlers.list_site_versions = () => ({ items: [], cursor: repeat ? (++pages, 'repeat') : `page-${++pages}` });
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('reconciliation_limit')); assert.equal(pages, repeat ? 2 : 20); assert.equal(h.count('save_site_version'), 0); assert.equal(h.count('deploy_private_site_version'), 0); assert.equal((await h.store.load()).phase, 'pushed');
});
test('recovery: malformed version list fails before source save', async () => { const h = await harness(); h.controls.handlers.list_site_versions = () => ({ items: 'wrong' }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('response_changed')); assert.equal(h.count('save_site_version'), 0); });

test('status: uninitialized local receipt is remotely read-only with no Git/build', async () => { const h = await harness(); const result = await h.service.status(h.root); assert.equal(result.local_publication, null); assert.deepEqual(h.names(), ['get_site']); assert.equal(h.gitCalls.length, 0); });
for (const phase of ['prepared', 'push_requested', 'pushed', 'saved', 'failed']) test(`status: ${phase} never resumes mutations or invokes Git`, async () => { const h = await harness(); await h.store.save(receipt(h.root, { phase, versionId: phase === 'saved' ? 'version' : undefined })); const result = await h.service.status(h.root); assert.equal(result.phase, phase); noMutations(h); assert.equal(h.gitCalls.length, 0); });
test('poll: zero wait returns pending honestly and status later completes read-only', async () => {
  const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v, { status: 'building' }); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id }));
  const pending = await h.service.status(h.root, 0); assert.equal(pending.completed, false); assert.equal(pending.phase, 'deploying'); assert.equal(h.sleeps.length, 0);
  d.status = 'succeeded'; assert.equal((await h.service.status(h.root)).completed, true); noMutations(h); assert.equal(h.gitCalls.length, 0);
});
test('poll: injected sleep and progress support bounded continuation to success', async () => {
  const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v, { status: 'pending' }); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id }));
  h.controls.onSleep = () => { d.status = 'succeeded'; };
  assert.equal((await h.service.status(h.root, 10)).completed, true); assert.equal(h.sleeps.length, 1); assert.ok(h.progress.some(p => p.includes('pending'))); noMutations(h);
});
for (const status of ['failed', 'cancelled', 'unknown-status']) test(`poll: ${status} preserves failed receipt, never reports success`, async () => { const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v, { status }); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id })); await assert.rejects(h.service.status(h.root), code('deployment_failed')); const state = await h.store.load(); assert.equal(state.phase, 'failed'); assert.equal(state.versionId, v.id); assert.equal(state.deploymentId, d.id); noMutations(h); });
for (const field of ['id', 'project_id', 'version_id']) test(`poll: rejects deployment ${field} mismatch`, async () => { const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id })); h.controls.handlers.get_deployment_status = () => ({ ...d, [field]: 'other' }); await assert.rejects(h.service.status(h.root), code('deployment_mismatch')); assert.equal((await h.store.load()).phase, 'deploying'); noMutations(h); });
for (const [name, mutate] of [
  ['commit mismatch', (h, v) => v.source.commit_sha = SHA2], ['version ID mismatch', (h, v) => h.controls.handlers.get_site_version = () => ({ ...v, id: 'other' })],
  ['live URL mismatch', h => h.controls.site.current_live_url = 'https://other.example.invalid/'], ['credential URL', (_h, _v, d) => d.url = 'https://example.invalid/?token=synthetic'],
]) test(`poll: final ${name} never marks success`, async () => { const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id })); mutate(h, v, d); await assert.rejects(h.service.status(h.root), code('verification_failed')); assert.equal((await h.store.load()).phase, 'deploying'); noMutations(h); });
test('poll: ownership/privacy drift at success fails verification', async () => { const h = await harness(); const v = seedVersion(h), d = seedDeployment(h, v); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id })); h.controls.site.access_mode = 'public'; await assert.rejects(h.service.status(h.root), code('not_owner_private')); noMutations(h); });

for (const [name, site] of [['public', privateSite({ access_mode: 'public' })], ['non-owner', privateSite({ current_user_role: 'editor' })], ['wrong project', privateSite({ id: 'other' })]]) test(`publish: ${name} rejected before credentials/build/push`, async () => { const h = await harness({ controls: { site } }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('not_owner_private')); noMutations(h); assert.equal(h.gitCalls.length, 0); });
test('publish: privacy is rechecked immediately before deploy', async () => { const h = await harness(); let reads = 0; h.controls.handlers.get_site = () => ++reads === 1 ? privateSite() : privateSite({ access_mode: 'public' }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('not_owner_private')); assert.equal(h.count('save_site_version'), 1); assert.equal(h.count('deploy_private_site_version'), 0); assert.equal((await h.store.load()).phase, 'saved'); });
test('publish: dirty worktree stops before build, credential, save or deployment', async () => { const h = await harness({ controls: { dirty: true } }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('dirty_worktree')); noMutations(h); assert.equal(await h.store.load(), undefined); });
test('publish: failed local check stops all uploads', async () => { const h = await harness({ controls: { checkError: new SitesError('build_failed', 'synthetic failure') } }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('build_failed')); noMutations(h); assert.equal(await h.store.load(), undefined); });
test('publish: source changed by check stops before credential issuance', async () => { const h = await harness(); h.controls.afterCheck = () => { h.controls.sha = SHA2; }; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('source_changed')); noMutations(h); assert.equal(await h.store.load(), undefined); });
test('publish: push uncertainty retains push_requested; retry does not rebuild', async () => { const h = await harness(); h.controls.onPush = () => { throw new SitesError('connection_interrupted', 'synthetic push interruption'); }; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('connection_interrupted')); assert.equal((await h.store.load()).phase, 'push_requested'); assert.equal(h.count('save_site_version'), 0); h.controls.onPush = undefined; assert.equal((await h.service.publish(h.root, { wait_seconds: 0 })).completed, true); assert.equal(h.gitCalls.filter(c => c[0] === 'check').length, 1); });
test('publish: source error from Git push prevents source save and deployment', async () => { const h = await harness(); h.controls.onPush = () => { throw new SitesError('source_changed', 'synthetic source change'); }; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('source_changed')); assert.equal(h.count('save_site_version'), 0); assert.equal(h.count('deploy_private_site_version'), 0); });
test('publish: saved version source mismatch prevents deployment', async () => { const h = await harness(); const v = seedVersion(h, { source: { commit_sha: SHA2 } }); await h.store.save(receipt(h.root, { phase: 'saved', versionId: v.id })); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('version_mismatch')); noMutations(h); });
test('publish: failed same SHA requires new commit; new SHA may publish', async () => { const h = await harness(); await h.store.save(receipt(h.root, { phase: 'failed', versionId: 'old-version', deploymentId: 'old-deployment' })); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('previous_deployment_failed')); noMutations(h); h.controls.sha = SHA2; assert.equal((await h.service.publish(h.root, { wait_seconds: 0 })).completed, true); });
for (const method of ['publish', 'status']) test(`${method}: receipt project mismatch fails before API calls`, async () => { const h = await harness(); await h.store.save(receipt(h.root, { projectId: 'other' })); await assert.rejects(h.service[method](h.root), code('binding_mismatch')); assert.equal(h.calls.length, 0); });
for (const method of ['publish', 'status', 'create']) test(`${method}: account mismatch does not change backend or overwrite receipt`, async () => { const h = await harness({ linked: method !== 'create' }); await h.store.save(receipt(h.root, { accountId: 'other-account' })); await assert.rejects(method === 'create' ? h.service.create(h.root, 'Fixture', 'fixture-site') : h.service[method](h.root), code('state_account_mismatch')); assert.equal(h.calls.length, 0); });
test('publish/status: competing operation cannot enter while project locked', async () => { const h = await harness(); const release = await h.store.lock(); try { await assert.rejects(h.service.publish(h.root), code('project_locked')); await assert.rejects(h.service.status(h.root), code('project_locked')); assert.equal(h.calls.length, 0); } finally { await release(); } });
test('publish: lock released even after failure', async () => { const h = await harness({ controls: { dirty: true } }); await assert.rejects(h.service.publish(h.root), code('dirty_worktree')); const release = await h.store.lock(); await release(); });
for (const value of [-1, 121, NaN, Infinity, '1']) test(`service: invalid wait ${value} rejected before network`, async () => { const h = await harness(); await assert.rejects(h.service.publish(h.root, { wait_seconds: value }), code('invalid_wait')); await assert.rejects(h.service.status(h.root, value), code('invalid_wait')); assert.equal(h.calls.length, 0); });

test('cancellation: pre-cancelled publish never mutates backend', async () => { const controller = new AbortController(); controller.abort(); const h = await harness({ signal: controller.signal }); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), { name: 'AbortError' }); noMutations(h); });
test('cancellation: aborted local check never obtains Git credentials', async () => { const controller = new AbortController(); const h = await harness({ signal: controller.signal }); h.controls.afterCheck = () => controller.abort(); await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), { name: 'AbortError' }); noMutations(h); });
test('cancellation: interrupted save preserves uncertain phase and does not replay', async () => { const controller = new AbortController(); const h = await harness({ signal: controller.signal }); h.controls.handlers.save_site_version = () => { controller.abort(); throw controller.signal.reason; }; await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), { name: 'AbortError' }); assert.equal((await h.store.load()).phase, 'save_requested'); assert.equal(h.count('deploy_private_site_version'), 0); const release = await h.store.lock(); await release(); });
test('cancellation: cancellation during poll leaves resumable deployment receipt', async () => { const controller = new AbortController(); const h = await harness({ signal: controller.signal }); const v = seedVersion(h), d = seedDeployment(h, v, { status: 'building' }); await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id })); h.controls.onSleep = () => controller.abort(); await assert.rejects(h.service.status(h.root, 10), { name: 'AbortError' }); assert.equal((await h.store.load()).phase, 'deploying'); noMutations(h); const release = await h.store.lock(); await release(); });

test('inspection: doctor is discovery-only and reports supported private remote build', async () => { const h = await harness(); const result = await h.service.doctor(); assert.equal(result.publication_supported, true); assert.equal(result.build_mode, 'remote'); assert.equal(h.calls.length, 0); });
test('inspection: list/get filter credentials and forward validated pagination', async () => { const h = await harness(); h.controls.site.token = 'synthetic-hidden'; h.controls.site.env = { SECRET: 'synthetic-hidden' }; const list = await h.service.list(5, 'synthetic-cursor'); assert.equal(list.items[0].token, undefined); assert.equal(list.items[0].env, undefined); assert.deepEqual(h.calls[0].args, { limit: 5, cursor: 'synthetic-cursor' }); assert.equal((await h.service.get(h.root)).id, PROJECT); assert.equal((await h.service.get('/synthetic-unused-root', PROJECT)).id, PROJECT); noMutations(h); });
for (const value of [0, 51, 1.5, NaN, '5']) test(`inspection: rejects invalid list limit ${value}`, async () => { const h = await harness(); await assert.rejects(h.service.list(value), code('invalid_limit')); assert.equal(h.calls.length, 0); });
