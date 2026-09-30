import test from 'node:test';
import assert from 'node:assert/strict';
import { harness, receipt, SHA, PROJECT, URL, code } from './helpers.mjs';

function narrowDiscovery(h, change) { const original = h.api.discover.bind(h.api); h.api.discover = async () => { const tools = await original(); change(tools); return tools; }; }
const mutations = ['create_site', 'create_source_repository_write_credential', 'save_site_version', 'deploy_private_site_version'];
function noWrites(h) { assert.ok(!h.calls.some(c => mutations.includes(c.name))); assert.ok(!h.gitCalls.some(c => c[0] === 'push')); }

for (const operation of ['get_site', 'create_source_repository_write_credential', 'save_site_version', 'list_site_versions', 'get_site_version', 'deploy_private_site_version', 'get_deployment_status']) test(`preflight: missing ${operation} stops publication before any upload`, async () => {
  const h = await harness(); narrowDiscovery(h, tools => tools.delete(operation));
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('tool_unavailable')); noWrites(h); assert.equal(await h.store.load(), undefined);
});
for (const operation of ['check_slug_availability', 'create_site']) test(`preflight: missing ${operation} stops registration before create`, async () => {
  const h = await harness({ linked: false }); narrowDiscovery(h, tools => tools.delete(operation));
  await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('tool_unavailable')); noWrites(h); assert.equal(await h.store.load(), undefined);
});
for (const [operation, required] of [['save_site_version', 'archive'], ['deploy_private_site_version', 'shared_access'], ['create_source_repository_write_credential', 'publish_on_push']]) test(`preflight: newly required ${operation}.${required} stops before credential or push`, async () => {
  const h = await harness(); narrowDiscovery(h, tools => tools.set(operation, { inputSchema: { required: [required] } }));
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('schema_changed')); noWrites(h); assert.equal(await h.store.load(), undefined);
});
test('preflight: new mandatory create field stops before Site creation', async () => { const h = await harness({ linked: false }); narrowDiscovery(h, tools => tools.set('create_site', { inputSchema: { required: ['unsupported_field'] } })); await assert.rejects(h.service.create(h.root, 'Fixture', 'fixture-site'), code('schema_changed')); noWrites(h); });
test('preflight: save_only does not require unavailable deployment tools', async () => { const h = await harness(); narrowDiscovery(h, tools => { tools.delete('deploy_private_site_version'); tools.delete('get_deployment_status'); }); const result = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 }); assert.equal(result.phase, 'saved'); assert.equal(h.count('deploy_private_site_version'), 0); });

for (const method of ['publish', 'status']) test(`lock: ${method} retains lease until asynchronous deployment poll completes`, async () => {
  const h = await harness();
  const v = { id: 'version-held', project_id: PROJECT, source: { commit_sha: SHA }, deployment_id: 'deployment-held' };
  const d = { id: v.deployment_id, project_id: PROJECT, version_id: v.id, status: 'succeeded', url: URL };
  h.versions.set(v.id, v); h.deployments.set(d.id, d);
  await h.store.save(receipt(h.root, { phase: 'deploying', versionId: v.id, deploymentId: d.id }));
  let enter, finish;
  const entered = new Promise(resolve => { enter = resolve; });
  const gate = new Promise(resolve => { finish = resolve; });
  h.controls.handlers.get_deployment_status = async () => { enter(); await gate; return d; };
  const operation = method === 'publish' ? h.service.publish(h.root, { wait_seconds: 0 }) : h.service.status(h.root);
  try {
    await entered;
    // Let asynchronous finally/unlink complete if poll was accidentally returned without await.
    await new Promise(resolve => setTimeout(resolve, 20));
    await assert.rejects(h.store.lock(), code('project_locked'));
  } finally { finish(); await operation; }
  const release = await h.store.lock(); await release();
});

test('recovery: mismatched version during deploy reconciliation is not trusted', async () => {
  const h = await harness();
  await h.store.save(receipt(h.root, { phase: 'deploy_requested', versionId: 'expected-version' }));
  h.controls.handlers.get_site_version = () => ({ id: 'other-version', project_id: 'other-site', source: { commit_sha: 'b'.repeat(40) }, deployment_id: 'foreign-deployment' });
  h.controls.handlers.get_deployment_status = () => { assert.fail('foreign deployment must not be polled'); };
  await assert.rejects(h.service.status(h.root), code('version_mismatch', 'deployment_mismatch', 'verification_failed'));
  assert.equal((await h.store.load()).phase, 'deploy_requested'); noWrites(h);
});
test('publish: cross-project get_site_version response never authorizes deployment', async () => {
  const h = await harness();
  const version = { id: 'version-cross-project', project_id: 'other-site', source: { commit_sha: SHA } };
  h.versions.set(version.id, version); await h.store.save(receipt(h.root, { phase: 'saved', versionId: version.id }));
  await assert.rejects(h.service.publish(h.root, { wait_seconds: 0 }), code('version_mismatch', 'verification_failed'));
  assert.equal(h.count('deploy_private_site_version'), 0); noWrites(h);
});
test('publish: partial save response is verified through get_site_version before save-only success', async () => {
  const h = await harness();
  h.controls.handlers.save_site_version = () => {
    const version = { id: 'partial-version', project_id: PROJECT, source: { commit_sha: SHA } };
    h.versions.set(version.id, version);
    return { id: version.id, project_id: PROJECT, version_number: 1 };
  };
  const result = await h.service.publish(h.root, { save_only: true, wait_seconds: 0 });
  assert.equal(result.phase, 'saved');
  assert.equal(h.count('get_site_version'), 1);
  assert.equal(h.count('deploy_private_site_version'), 0);
});
test('publish: partial save response with wrong verified source leaves save uncertain', async () => {
  const h = await harness();
  h.controls.handlers.save_site_version = () => {
    const version = { id: 'partial-wrong-version', project_id: PROJECT, source: { commit_sha: 'b'.repeat(40) } };
    h.versions.set(version.id, version);
    return { id: version.id, project_id: PROJECT };
  };
  await assert.rejects(h.service.publish(h.root, { save_only: true, wait_seconds: 0 }), code('version_mismatch'));
  assert.equal((await h.store.load()).phase, 'save_requested');
  assert.equal(h.count('deploy_private_site_version'), 0);
});
test('poll: final version must belong to the selected project', async () => {
  const h = await harness();
  const version = { id: 'final-foreign-version', project_id: 'foreign-site', source: { commit_sha: SHA }, deployment_id: 'final-deployment' };
  const deployment = { id: version.deployment_id, project_id: PROJECT, version_id: version.id, status: 'succeeded', url: URL };
  h.versions.set(version.id, version); h.deployments.set(deployment.id, deployment);
  await h.store.save(receipt(h.root, { phase: 'deploying', versionId: version.id, deploymentId: deployment.id }));
  await assert.rejects(h.service.status(h.root), code('verification_failed'));
  assert.equal((await h.store.load()).phase, 'deploying');
  noWrites(h);
});
test('publish: save_only rejects a saved response for a different project/commit', async () => {
  const h = await harness(); h.controls.handlers.save_site_version = () => ({ id: 'foreign-version', project_id: 'other-site', source: { commit_sha: 'b'.repeat(40) } });
  await assert.rejects(h.service.publish(h.root, { save_only: true, wait_seconds: 0 }), code('version_mismatch', 'verification_failed'));
  assert.equal((await h.store.load()).phase, 'save_requested'); assert.equal(h.count('deploy_private_site_version'), 0);
});
