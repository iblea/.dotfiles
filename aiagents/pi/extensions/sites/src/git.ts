import { spawn } from 'node:child_process';
import { realpath, lstat, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { SitesError, Secrets } from './security.ts';
import type { Runner, RunResult, Json } from './types.ts';

export const runCommand: Runner = async (cwd, command, args, options = {}) => {
  if (!command || !Array.isArray(args) || [command, ...args].some(x => typeof x !== 'string' || x.includes('\0'))) throw new SitesError('invalid_command', '검사 명령은 실행 파일과 문자열 인자 배열이어야 해.');
  options.signal?.throwIfAborted();
  return new Promise<RunResult>((resolve, reject) => {
    const grouped = process.platform !== 'win32';
    const child = spawn(command, args, { cwd, env: options.env ?? process.env, stdio: ['ignore', 'pipe', 'pipe'], detached: grouped, shell: false });
    let stdout = '', stderr = '', bytes = 0, stopped = false;
    let killTimer: NodeJS.Timeout | undefined;
    const stop = () => {
      if (stopped) return;
      stopped = true;
      const kill = (signal: NodeJS.Signals) => { try { if (grouped && child.pid) process.kill(-child.pid, signal); else child.kill(signal); } catch {} };
      kill('SIGTERM'); killTimer = setTimeout(() => kill('SIGKILL'), 2000); killTimer.unref();
    };
    const timer = setTimeout(stop, 180000); timer.unref();
    options.signal?.addEventListener('abort', stop, { once: true });
    const collect = (name: 'stdout' | 'stderr', value: Buffer) => {
      bytes += value.byteLength;
      if (bytes > 4 * 1024 * 1024) { stop(); return; }
      if (name === 'stdout') stdout += value.toString('utf8'); else stderr += value.toString('utf8');
    };
    child.stdout.on('data', value => collect('stdout', value));
    child.stderr.on('data', value => collect('stderr', value));
    const cleanup = () => { clearTimeout(timer); if (killTimer) clearTimeout(killTimer); options.signal?.removeEventListener('abort', stop); };
    child.on('error', () => { cleanup(); reject(new SitesError('command_start_failed', '검사 또는 Git 프로세스를 시작하지 못했어.')); });
    child.on('close', code => { cleanup(); if (stopped) reject(new SitesError('command_interrupted', '검사 또는 Git 작업이 취소되거나 제한 시간을 넘었어. 상태를 확인한 뒤 재개해.')); else resolve({ stdout, stderr, code: code ?? 1 }); });
  });
};

export class SiteGit {
  constructor(public root: string, private secrets: Secrets, private signal?: AbortSignal, private runner: Runner = runCommand) {}
  async git(args: string[], env?: NodeJS.ProcessEnv, allowFailure = false) {
    const result = await this.runner(this.root, 'git', args, { env, signal: this.signal });
    if (result.code && !allowFailure) throw new SitesError('git_failed', `Git ${args.find(x => ['status', 'push', 'ls-remote', 'show', 'rev-parse', 'check-ref-format'].includes(x)) ?? '검사'} 작업에 실패했어. 로컬 소스는 유지돼.`);
    return result;
  }
  async validateRoot() {
    for (const key of ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR', 'GIT_CONFIG_COUNT']) if (process.env[key]) throw new SitesError('git_override', 'Git 경로나 인증 설정을 덮어쓴 환경에서는 게시하지 않아.');
    const dotGit = await lstat(join(this.root, '.git')).catch(() => null);
    if (!dotGit || dotGit.isSymbolicLink()) throw new SitesError('repository_required', '선택한 디렉터리에 독립된 Git 저장소가 필요해. 먼저 git init을 실행해.');
    const actual = await realpath((await this.git(['rev-parse', '--show-toplevel'])).stdout.trim());
    if (actual !== this.root) throw new SitesError('nested_repository', '사이트 디렉터리는 Git 저장소 최상위 경로여야 해.');
    const gitDir = (await this.git(['rev-parse', '--absolute-git-dir'])).stdout.trim();
    for (const name of ['MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply']) if (await lstat(join(gitDir, name)).catch(() => null)) throw new SitesError('git_operation_pending', '진행 중인 Git 병합·리베이스 작업을 먼저 끝내야 해.');
  }
  async inspect(projectId: string): Promise<string> {
    await this.validateRoot();
    if ((await this.git(['status', '--porcelain=v1', '--untracked-files=all'])).stdout.trim()) throw new SitesError('dirty_worktree', '커밋되지 않은 변경이 있어. 게시할 파일만 검토·커밋한 뒤 다시 시도해. 자동 커밋은 하지 않아.');
    const sha = (await this.git(['rev-parse', '--verify', 'HEAD^{commit}'])).stdout.trim();
    if (!/^[a-f0-9]{40,64}$/.test(sha)) throw new SitesError('invalid_commit', '게시할 커밋을 확인하지 못했어.');
    let hosting;
    try { hosting = JSON.parse((await this.git(['show', `${sha}:.openai/hosting.json`])).stdout); } catch { throw new SitesError('manifest_not_committed', '.openai/hosting.json이 커밋에 포함되어야 해.'); }
    if (hosting.project_id !== projectId) throw new SitesError('binding_mismatch', '커밋의 project_id와 선택한 Site가 달라.');
    const files = (await this.git(['ls-tree', '-r', '--name-only', '-z', sha])).stdout.split('\0').filter(Boolean);
    if (files.some(file => /(^|\/)(auth\.json|credentials(?:\.json)?|id_rsa|id_ed25519|\.npmrc|\.pypirc)$|\.(pem|p12|pfx|key)$/i.test(file) || /(^|\/)\.env($|\.)/.test(file) && !/\.env\.(example|sample)$/.test(file))) throw new SitesError('sensitive_source', '커밋에 인증정보 파일로 보이는 경로가 있어. 검토·제거 후 게시해.');
    const scan = await this.git(['grep', '-I', '-l', '-E', 'BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9]{24,}|Bearer [A-Za-z0-9._-]{40,}|eyJ[A-Za-z0-9_-]{20,}\\.[A-Za-z0-9_-]{20,}\\.[A-Za-z0-9_-]{20,}', sha, '--'], undefined, true);
    if (scan.code === 0) throw new SitesError('secret_in_source', '커밋에 비밀키·토큰으로 보이는 내용이 있어. 값을 출력하지 않고 게시를 중단했어.');
    if (scan.code !== 1) throw new SitesError('secret_scan_failed', '게시 전 비밀정보 검사를 완료하지 못했어.');
    return sha;
  }
  async check(command?: string[]) {
    if (!command) {
      let pkg; try { pkg = JSON.parse(await readFile(join(this.root, 'package.json'), 'utf8')); } catch (error: any) { if (error.code !== 'ENOENT') throw new SitesError('invalid_package', 'package.json을 읽지 못했어.'); }
      if (typeof pkg?.scripts?.build === 'string') command = ['npm', 'run', 'build'];
    }
    if (!command) return;
    if (!command.length) throw new SitesError('invalid_command', '빈 검사 명령은 허용하지 않아.');
    const result = await this.runner(this.root, command[0], command.slice(1), { signal: this.signal });
    if (result.code) throw new SitesError('build_failed', '로컬 빌드·검사가 실패했어. 소스를 업로드하지 않았어. 동일한 검사 명령으로 원인을 확인해.');
  }
  async network(credential: Json, args: string[]) {
    this.secrets.add(credential.token);
    if (credential.auth_mode !== 'http_extra_header' || typeof credential.token !== 'string' || !credential.token || /[\r\n\0]/.test(credential.token)) throw new SitesError('credential_format', '지원하지 않는 Sites Git 인증 형식이야.');
    if (credential.token_expires_at && (!Number.isFinite(Date.parse(credential.token_expires_at)) || Date.parse(credential.token_expires_at) <= Date.now())) throw new SitesError('credential_expired', 'Sites Git 인증이 만료됐어. 같은 프로젝트로 다시 시도해.');
    let remote: URL;
    try { remote = new URL(credential.remote_url); } catch { throw new SitesError('invalid_remote', 'Sites Git 주소가 유효하지 않아.'); }
    if (remote.protocol !== 'https:' || remote.hostname !== 'git.chatgpt-team.site' || remote.port || remote.username || remote.password || remote.search || remote.hash) throw new SitesError('invalid_remote', '허용된 Sites HTTPS 저장소 주소가 아니야.');
    if (typeof credential.branch !== 'string' || !credential.branch || credential.branch.startsWith('-')) throw new SitesError('invalid_branch', 'Sites 브랜치가 유효하지 않아.');
    await this.git(['check-ref-format', `refs/heads/${credential.branch}`]);
    const rewritten = (await this.git(['ls-remote', '--get-url', credential.remote_url])).stdout.trim();
    const rewrites = await this.git(['config', '--get-regexp', '^url\\..*\\.pushinsteadof$'], undefined, true);
    if (rewrites.code > 1 || rewritten !== credential.remote_url || rewrites.stdout.split('\n').some(line => { const prefix = line.match(/^\S+\s+(.+)$/)?.[1]; return prefix && credential.remote_url.startsWith(prefix); })) throw new SitesError('git_url_rewrite', 'Git URL 재작성 설정 때문에 목적지를 보장할 수 없어.');
    const env: NodeJS.ProcessEnv = { ...process.env, GIT_TERMINAL_PROMPT: '0', SITES_GIT_AUTHORIZATION: `Authorization: Bearer ${credential.token}` };
    for (const key of Object.keys(env)) if (key.startsWith('GIT_TRACE') || key === 'GIT_CURL_VERBOSE' || /^GIT_CONFIG_(COUNT|KEY_\d+|VALUE_\d+)$/.test(key)) delete env[key];
    return this.git(['-c', 'credential.helper=', '-c', 'core.hooksPath=/dev/null', '-c', 'http.extraHeader=', '-c', 'http.followRedirects=false', `--config-env=http.${credential.remote_url}.extraHeader=SITES_GIT_AUTHORIZATION`, ...args], env);
  }
  async push(credential: Json, sha: string, projectId: string) {
    if (credential.publish_on_push_accepted === true) throw new SitesError('unexpected_auto_publish', '자동 게시가 활성화된 인증은 이 명시적 게시 경로에서 사용하지 않아.');
    const ref = `refs/heads/${credential.branch}`;
    const remoteHead = async () => (await this.network(credential, ['ls-remote', '--heads', credential.remote_url, ref])).stdout.trim().split(/\s+/)[0];
    if (await this.inspect(projectId) !== sha) throw new SitesError('source_changed', '검사 이후 로컬 커밋이 바뀌었어.');
    if (await remoteHead() !== sha) await this.network(credential, ['push', '--porcelain', credential.remote_url, `${sha}:${ref}`]);
    if (await remoteHead() !== sha || await this.inspect(projectId) !== sha) throw new SitesError('source_changed', 'push 후 소스 일치 검증에 실패했어. 저장·배포하지 않았어.');
  }
}
