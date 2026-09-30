import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdir, writeFile, symlink } from 'node:fs/promises';
import { join } from 'node:path';
import { SiteGit, runCommand } from '../src/git.ts';
import { Secrets } from '../src/security.ts';
import { fixture, credential, SHA, SHA2, PROJECT, code } from './helpers.mjs';

async function gitHarness(extra = {}) {
  const f = await fixture('git'); await mkdir(join(f.root, '.git'));
  const calls = [], secrets = new Secrets();
  const controls = { status: '', sha: SHA, manifest: { project_id: PROJECT }, files: ['index.html', '.openai/hosting.json'], scan: 1, head: '', rewritten: credential().remote_url, rewrites: '', checkCode: 0, ...extra };
  const runner = async (cwd, command, args, options = {}) => {
    calls.push({ cwd, command, args: [...args], options });
    assert.equal(cwd, f.root);
    let stdout = '', code = 0;
    if (command !== 'git') return { stdout: '', stderr: 'synthetic-build-stderr', code: controls.checkCode };
    const network = args.some(a => a.startsWith('--config-env='));
    if (network) {
      assert.equal(options.env.SITES_GIT_AUTHORIZATION, `Authorization: Bearer ${credential().token}`);
      if (args.includes('push')) { controls.head = controls.pushedHead ?? controls.sha; await controls.afterPush?.(); }
      else if (args.includes('ls-remote')) stdout = controls.head ? `${controls.head}\trefs/heads/main\n` : '';
    } else if (args[0] === 'rev-parse') stdout = args[1] === '--show-toplevel' ? (controls.top ?? f.root) : args[1] === '--absolute-git-dir' ? join(f.root, '.git') : controls.sha;
    else if (args[0] === 'status') stdout = controls.status;
    else if (args[0] === 'show') stdout = typeof controls.manifest === 'string' ? controls.manifest : JSON.stringify(controls.manifest);
    else if (args[0] === 'ls-tree') stdout = `${controls.files.join('\0')}\0`;
    else if (args[0] === 'grep') code = controls.scan;
    else if (args[0] === 'ls-remote') stdout = controls.rewritten;
    else if (args[0] === 'config') { stdout = controls.rewrites; code = controls.rewriteCode ?? (stdout ? 0 : 1); }
    else if (args[0] === 'check-ref-format') code = controls.refCode ?? 0;
    else throw new Error(`Unexpected git args ${JSON.stringify(args)}`);
    return { stdout, stderr: 'synthetic-git-stderr', code };
  };
  return { ...f, git: new SiteGit(f.root, secrets, undefined, runner), controls, calls, secrets };
}

test('Git: fake-token credential remains environment-only, URL-scoped, noninteractive, hookless and redirect-free', async () => {
  const h = await gitHarness();
  const keys = ['GIT_TRACE', 'GIT_TRACE_CURL', 'GIT_CURL_VERBOSE', 'GIT_CONFIG_COUNT', 'GIT_CONFIG_KEY_0', 'GIT_CONFIG_VALUE_0'];
  const before = Object.fromEntries(keys.map(k => [k, process.env[k]]));
  try {
    for (const key of keys) process.env[key] = 'synthetic-trace';
    await h.git.network(credential(), ['ls-remote', '--heads', credential().remote_url, 'refs/heads/main']);
  } finally { for (const [key, value] of Object.entries(before)) if (value === undefined) delete process.env[key]; else process.env[key] = value; }
  const network = h.calls.at(-1);
  assert.equal(network.options.env.GIT_TERMINAL_PROMPT, '0');
  for (const key of keys) assert.equal(network.options.env[key], undefined);
  assert.ok(network.args.includes('credential.helper=')); assert.ok(network.args.includes('core.hooksPath=/dev/null')); assert.ok(network.args.includes('http.extraHeader=')); assert.ok(network.args.includes('http.followRedirects=false'));
  assert.ok(network.args.includes(`--config-env=http.${credential().remote_url}.extraHeader=SITES_GIT_AUTHORIZATION`));
  assert.ok(!JSON.stringify(h.calls.map(c => c.args)).includes(credential().token));
  assert.equal(h.secrets.text(credential().token), '[REDACTED]');
  assert.ok(!h.calls.some(c => c.args.includes('remote') || c.args.includes('--global')));
});
for (const [name, extra, expected] of [
  ['wrong mode', { auth_mode: 'basic' }, 'credential_format'], ['empty token', { token: '' }, 'credential_format'], ['newline token', { token: 'synthetic\nInjected: x' }, 'credential_format'],
  ['expired token', { token_expires_at: '2000-01-01' }, 'credential_expired'], ['invalid expiry', { token_expires_at: 'nonsense' }, 'credential_expired'],
  ['http', { remote_url: 'http://git.chatgpt-team.site/repo' }, 'invalid_remote'], ['wrong host', { remote_url: 'https://git.chatgpt-team.site.evil.invalid/repo' }, 'invalid_remote'],
  ['userinfo', { remote_url: 'https://user:pass@git.chatgpt-team.site/repo' }, 'invalid_remote'], ['query', { remote_url: 'https://git.chatgpt-team.site/repo?token=x' }, 'invalid_remote'],
  ['fragment', { remote_url: 'https://git.chatgpt-team.site/repo#x' }, 'invalid_remote'], ['port', { remote_url: 'https://git.chatgpt-team.site:444/repo' }, 'invalid_remote'],
  ['ssh', { remote_url: 'ssh://git.chatgpt-team.site/repo' }, 'invalid_remote'], ['bad URL', { remote_url: 'not a URL' }, 'invalid_remote'],
  ['option branch', { branch: '--force' }, 'invalid_branch'], ['empty branch', { branch: '' }, 'invalid_branch'],
]) test(`Git: rejects ${name} before invoking authenticated process`, async () => { const h = await gitHarness(); await assert.rejects(h.git.network(credential(extra), ['push']), code(expected)); assert.ok(!h.calls.some(c => c.options.env?.SITES_GIT_AUTHORIZATION)); });
for (const [name, controls] of [
  ['insteadOf', { rewritten: 'https://evil.example.invalid/repo' }],
  ['pushInsteadOf', { rewrites: 'url.https://evil.example.invalid/.pushinsteadof https://git.chatgpt-team.site/\n' }],
  ['unreadable config', { rewriteCode: 2 }],
]) test(`Git: rejects ${name} rewrite before exposing header`, async () => { const h = await gitHarness(controls); await assert.rejects(h.git.network(credential(), ['push']), code('git_url_rewrite')); assert.ok(!h.calls.some(c => c.options.env?.SITES_GIT_AUTHORIZATION)); });
test('Git: unrelated pushInsteadOf does not block approved remote', async () => { const h = await gitHarness({ rewrites: 'url.https://example.invalid/.pushinsteadof https://unrelated.invalid/\n' }); await h.git.network(credential(), ['ls-remote']); assert.ok(h.calls.at(-1).options.env.SITES_GIT_AUTHORIZATION); });
test('Git: malformed ref is checked before authenticated operation', async () => { const h = await gitHarness({ refCode: 1 }); await assert.rejects(h.git.network(credential({ branch: 'bad..branch' }), ['push']), code('git_failed')); assert.ok(!h.calls.some(c => c.options.env?.SITES_GIT_AUTHORIZATION)); });

test('Git: clean committed manifest and source scan return SHA', async () => { const h = await gitHarness(); assert.equal(await h.git.inspect(PROJECT), SHA); assert.ok(h.calls.some(c => c.args[0] === 'grep')); });
for (const [name, controls, expected] of [
  ['dirty tracked', { status: ' M index.html' }, 'dirty_worktree'], ['dirty untracked', { status: '?? new.html' }, 'dirty_worktree'],
  ['invalid SHA', { sha: '--option' }, 'invalid_commit'], ['uncommitted manifest', { manifest: 'invalid-json' }, 'manifest_not_committed'], ['wrong project', { manifest: { project_id: 'other' } }, 'binding_mismatch'],
  ['content secret', { scan: 0 }, 'secret_in_source'], ['failed secret scan', { scan: 2 }, 'secret_scan_failed'],
]) test(`Git: refuses ${name}`, async () => { const h = await gitHarness(controls); await assert.rejects(h.git.inspect(PROJECT), code(expected)); assert.ok(!h.calls.some(c => c.options.env?.SITES_GIT_AUTHORIZATION)); });
for (const file of ['auth.json', 'nested/credentials.json', 'id_rsa', 'nested/.env.local', '.env', '.npmrc', 'server.key', 'cert.pem', 'nested/.pypirc']) test(`Git: refuses sensitive source path ${file}`, async () => { const h = await gitHarness({ files: [file] }); await assert.rejects(h.git.inspect(PROJECT), code('sensitive_source')); });
test('Git: example/sample environment files allowed', async () => { const h = await gitHarness({ files: ['.env.example', 'nested/.env.sample'] }); assert.equal(await h.git.inspect(PROJECT), SHA); });
test('Git: repository path override refused', async () => { const h = await gitHarness(); const previous = process.env.GIT_DIR; try { process.env.GIT_DIR = 'synthetic-override'; await assert.rejects(h.git.validateRoot(), code('git_override')); } finally { if (previous === undefined) delete process.env.GIT_DIR; else process.env.GIT_DIR = previous; } assert.equal(h.calls.length, 0); });
test('Git: independent root required, not nested Git root', async () => { const h = await gitHarness(); h.controls.top = h.base; await assert.rejects(h.git.validateRoot(), code('nested_repository')); });
test('Git: symlink .git refused without executing Git', async () => { const f = await fixture('dotgit-link'); const target = join(f.base, 'target-git'); await mkdir(target); await symlink(target, join(f.root, '.git')); let called = false; await assert.rejects(new SiteGit(f.root, new Secrets(), undefined, async () => { called = true; }).validateRoot(), code('repository_required')); assert.equal(called, false); });
for (const pending of ['MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply']) test(`Git: refuses unfinished ${pending}`, async () => { const h = await gitHarness(); await writeFile(join(h.root, '.git', pending), 'synthetic'); await assert.rejects(h.git.validateRoot(), code('git_operation_pending')); });

test('Git: defaults to npm build and respects explicit argv without shell', async () => { const h = await gitHarness(); await writeFile(join(h.root, 'package.json'), JSON.stringify({ scripts: { build: 'synthetic-build' } })); await h.git.check(); assert.equal(h.calls.at(-1).command, 'npm'); assert.deepEqual(h.calls.at(-1).args, ['run', 'build']); await h.git.check(['fixture-check', '--flag', 'a;not-a-shell']); assert.equal(h.calls.at(-1).command, 'fixture-check'); assert.deepEqual(h.calls.at(-1).args, ['--flag', 'a;not-a-shell']); });
test('Git: no build script does not run a default command', async () => { const h = await gitHarness(); await h.git.check(); assert.equal(h.calls.length, 0); });
test('Git: failed build and invalid package stop publication', async () => { const h = await gitHarness({ checkCode: 1 }); await assert.rejects(h.git.check(['fixture-check']), code('build_failed')); await writeFile(join(h.root, 'package.json'), '{bad'); await assert.rejects(h.git.check(), code('invalid_package')); await assert.rejects(h.git.check([]), code('invalid_command')); });
test('Git: push compares remote head and never force-pushes or configures a persistent remote', async () => { const h = await gitHarness(); await h.git.push(credential(), SHA, PROJECT); const pushes = h.calls.filter(c => c.args.includes('push')); assert.equal(pushes.length, 1); assert.ok(pushes[0].args.includes(`${SHA}:refs/heads/main`)); assert.ok(!pushes[0].args.some(a => a.includes('force') || a.startsWith('+'))); assert.equal(h.calls.filter(c => c.options.env?.SITES_GIT_AUTHORIZATION && c.args.includes('ls-remote')).length, 2); });
test('Git: retry at already-pushed SHA issues no duplicate push', async () => { const h = await gitHarness({ head: SHA }); await h.git.push(credential(), SHA, PROJECT); assert.ok(!h.calls.some(c => c.args.includes('push'))); });
test('Git: publish-on-push credentials refused', async () => { const h = await gitHarness(); await assert.rejects(h.git.push(credential({ publish_on_push_accepted: true }), SHA, PROJECT), code('unexpected_auto_publish')); assert.equal(h.calls.length, 0); });
test('Git: source changed before push prevents authenticated calls', async () => { const h = await gitHarness({ sha: SHA2 }); await assert.rejects(h.git.push(credential(), SHA, PROJECT), code('source_changed')); assert.ok(!h.calls.some(c => c.options.env?.SITES_GIT_AUTHORIZATION)); });
test('Git: source changed after push is detected', async () => { const h = await gitHarness(); h.controls.afterPush = () => { h.controls.sha = SHA2; }; await assert.rejects(h.git.push(credential(), SHA, PROJECT), code('source_changed')); });
test('Git: remote head mismatch after push is detected', async () => { const h = await gitHarness({ pushedHead: SHA2 }); await assert.rejects(h.git.push(credential(), SHA, PROJECT), code('source_changed')); });
test('runner: cancelled command is rejected without starting a process', async () => { const controller = new AbortController(); controller.abort(); await assert.rejects(runCommand('/synthetic-not-real', 'not-real-command', [], { signal: controller.signal }), { name: 'AbortError' }); });
test('runner: invalid argv rejected without starting process', async () => { for (const [command, args] of [['', []], ['x', ['bad\0arg']], ['x', [1]], ['x', 'not-array']]) await assert.rejects(runCommand('/synthetic-not-real', command, args), code('invalid_command')); });
