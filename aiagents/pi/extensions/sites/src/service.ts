import { setTimeout as delay } from 'node:timers/promises';
import { SitesError, Secrets, opaqueId, ownerPrivate, safeSite, safeDeployment, cleanUrl } from './security.ts';
import { projectRoot, readHosting, bindProject } from './project.ts';
import { SiteGit } from './git.ts';
import { StateStore } from './state.ts';
import type { Api, Json, Receipt } from './types.ts';

type GitOperations = Pick<SiteGit, 'validateRoot' | 'inspect' | 'check' | 'push'>;
interface Options {
  gitFactory?: (root: string) => GitOperations;
  progress?: (message: string) => void;
  sleep?: (ms: number) => Promise<unknown>;
}

function items(result: Json): Json[] {
  if (!Array.isArray(result?.items)) throw new SitesError('response_changed', 'Sites 목록 응답 형식이 달라졌어.');
  return result.items;
}
function requireVersion(version: Json, projectId: string, sha: string, versionId?: string, code = 'version_mismatch') {
  if (!version || version.project_id !== projectId || version.source?.commit_sha !== sha || versionId && version.id !== versionId) throw new SitesError(code, '저장된 버전의 프로젝트·버전 ID·소스 커밋이 요청과 달라.');
  opaqueId(version.id, 'version_id');
}
function receiptView(state: Receipt) {
  return { project_id: state.projectId, phase: state.phase, commit_sha: state.sha, version_id: state.versionId, deployment_id: state.deploymentId, url: state.url, completed: state.phase === 'succeeded', build_mode: 'remote' };
}

export class SitesService {
  constructor(private api: Api, private secrets: Secrets, private directory: string, private signal?: AbortSignal, private options: Options = {}) {}
  private git(root: string) { return this.options.gitFactory?.(root) ?? new SiteGit(root, this.secrets, this.signal); }
  private store(root: string) { return new StateStore(this.directory, root, this.api.identity.accountId); }
  private async requireOperations(names: string[]) {
    const tools = await this.api.discover();
    const parameters: Record<string, string[]> = {
      check_slug_availability: ['slug'], create_site: ['title', 'slug'], get_site: ['project_id'],
      create_source_repository_write_credential: ['project_id'], save_site_version: ['project_id', 'commit_sha'],
      list_site_versions: ['project_id', 'limit', 'cursor'], get_site_version: ['project_id', 'version_id'],
      deploy_private_site_version: ['project_id', 'version_id'], get_deployment_status: ['project_id', 'deployment_id'],
    };
    for (const name of names) {
      const tool = tools.get(name);
      if (!tool) throw new SitesError('tool_unavailable', `필요한 sites.${name}이 없어. 원격 변경 전에 중단했어.`);
      if ((tool.inputSchema?.required ?? []).some((key: string) => !parameters[name]?.includes(key))) throw new SitesError('schema_changed', `sites.${name}의 필수 인자가 변경됐어. 원격 변경 전에 중단했어.`);
    }
  }
  private emit(message: string) { this.signal?.throwIfAborted(); this.options.progress?.(message); }
  private fresh(root: string, phase: Receipt['phase'], data: Partial<Receipt> = {}): Receipt {
    const timestamp = new Date().toISOString();
    return { format: 1, root, accountId: this.api.identity.accountId, phase, startedAt: timestamp, updatedAt: timestamp, ...data };
  }
  private async selected(path: string, supplied?: string) {
    if (supplied) return opaqueId(supplied, 'project_id');
    const root = await projectRoot(path);
    return opaqueId((await readHosting(root)).project_id, 'hosting.json project_id');
  }
  async doctor() {
    const tools = await this.api.discover();
    const required = ['get_site', 'list_sites', 'create_site', 'create_source_repository_write_credential', 'save_site_version', 'get_site_version', 'list_site_versions', 'deploy_private_site_version', 'get_deployment_status'];
    const missing = required.filter(name => !tools.has(name));
    return { connected: true, auth: 'Pi OpenAI Codex OAuth', available_operations: [...tools.keys()], publication_supported: !missing.length, missing, build_mode: 'remote', limitations: ['private-only', 'clean committed Git source required', 'no archive upload or automatic publish-on-push'] };
  }
  async list(limit = 20, cursor?: string) {
    if (!Number.isInteger(limit) || limit < 1 || limit > 50) throw new SitesError('invalid_limit', 'limit은 1~50 사이 정수여야 해.');
    const result = await this.api.call('list_sites', { limit, ...(cursor ? { cursor: opaqueId(cursor, 'cursor') } : {}) });
    return { items: items(result).map(value => safeSite(value, this.api.identity)), cursor: result.cursor ?? null };
  }
  async get(path: string, projectId?: string) {
    const id = await this.selected(path, projectId);
    return safeSite(await this.api.call('get_site', { project_id: id }), this.api.identity);
  }
  async create(path: string, title: string, slug: string) {
    if (!title?.trim() || title.length > 200 || !/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/.test(slug) || slug.length < 5 || slug.length > 63) throw new SitesError('invalid_site', '제목과 유효한 5~63자 영문 소문자 slug가 필요해.');
    const root = await projectRoot(path);
    await this.git(root).validateRoot();
    const store = this.store(root);
    const unlock = await store.lock();
    try {
      const hosting = await readHosting(root);
      if (hosting.project_id) throw new SitesError('already_linked', '이미 Site에 연결된 프로젝트야. 새로 만들지 말고 sites_get 또는 sites_publish를 사용해.');
      const previous = await store.load();
      if (previous?.projectId) {
        if (previous.slug !== slug) throw new SitesError('binding_mismatch', '등록 기록의 slug와 요청이 달라.');
        await bindProject(root, previous.projectId);
        previous.phase = 'linked'; await store.save(previous);
        return { project_id: previous.projectId, linked: true, recovered: true, next: '.openai/hosting.json을 검토·커밋한 뒤 sites_publish를 실행해.' };
      }
      if (previous) throw new SitesError('create_uncertain', '이전 Site 생성 요청의 결과가 불명확해. sites_list로 확인하고 정확한 project_id를 hosting.json에 연결해. 자동으로 다시 만들지 않아.');
      await this.requireOperations(['check_slug_availability', 'create_site']);
      const availability = await this.api.call('check_slug_availability', { slug });
      if (availability.available !== true) throw new SitesError('slug_unavailable', '이 slug를 사용할 수 없어.');
      const state = this.fresh(root, 'create_requested', { title, slug });
      await store.save(state);
      this.emit('비공개 Site 등록 중');
      const result = await this.api.call('create_site', { title: title.trim(), slug });
      state.projectId = opaqueId(result.id, 'project_id');
      state.phase = 'linked'; await store.save(state);
      await bindProject(root, state.projectId);
      return { ...safeSite(result), project_id: state.projectId, linked: true, next: '.openai/hosting.json을 포함한 게시 소스를 검토·커밋한 뒤 sites_publish를 실행해.' };
    } finally { await unlock(); }
  }
  private async assertPrivate(projectId: string) {
    const site = await this.api.call('get_site', { project_id: projectId });
    if (site.id !== projectId || !ownerPrivate(site, this.api.identity)) throw new SitesError('not_owner_private', '현재 계정 소유자만 접근 가능한 Site인지 확인되지 않았어. 공개 범위를 바꾸거나 공유 배포로 우회하지 않아.');
    return site;
  }
  private async versionForCommit(projectId: string, sha: string) {
    let cursor;
    const seen = new Set<string>();
    for (let page = 0; page < 20; page++) {
      const result = await this.api.call('list_site_versions', { project_id: projectId, limit: 20, ...(cursor ? { cursor } : {}) });
      const matches = items(result).filter(value => value.project_id === projectId && value.source?.commit_sha === sha);
      if (matches.length) return matches.sort((a, b) => (b.version_number ?? 0) - (a.version_number ?? 0))[0];
      cursor = result.cursor;
      if (!cursor) return undefined;
      if (seen.has(cursor)) break;
      seen.add(cursor);
    }
    throw new SitesError('reconciliation_limit', '저장된 버전 목록을 끝까지 확인하지 못했어. 중복 저장을 방지하려고 중단했어.');
  }
  private async reconcile(state: Receipt, store: StateStore) {
    if (state.phase === 'save_requested') {
      const version = await this.versionForCommit(state.projectId!, state.sha!);
      if (!version) throw new SitesError('save_uncertain', '버전 저장 요청의 결과가 아직 불명확해. 잠시 뒤 sites_status로 다시 확인해. 자동 재전송하지 않아.');
      state.versionId = opaqueId(version.id, 'version_id'); state.phase = 'saved'; await store.save(state);
    }
    if (state.phase === 'deploy_requested') {
      const version = await this.api.call('get_site_version', { project_id: state.projectId, version_id: state.versionId });
      requireVersion(version, state.projectId!, state.sha!, state.versionId);
      if (version.deployment_id && version.deployment_id !== state.priorDeploymentId) {
        state.deploymentId = opaqueId(version.deployment_id, 'deployment_id'); state.phase = 'deploying'; await store.save(state);
      } else throw new SitesError('deploy_uncertain', '배포 요청의 결과가 아직 불명확해. sites_status로 확인해. 중복 배포를 시작하지 않아.');
    }
  }
  private async poll(state: Receipt, store: StateStore, seconds: number) {
    const deadline = Date.now() + seconds * 1000;
    do {
      this.signal?.throwIfAborted();
      const raw = await this.api.call('get_deployment_status', { project_id: state.projectId, deployment_id: state.deploymentId });
      if (raw.id !== state.deploymentId || raw.project_id !== state.projectId || raw.version_id !== state.versionId) throw new SitesError('deployment_mismatch', '배포 응답의 프로젝트·버전이 요청과 달라.');
      const deployment = safeDeployment(raw);
      if (deployment.status === 'succeeded') {
        const version = await this.api.call('get_site_version', { project_id: state.projectId, version_id: state.versionId });
        const site = await this.assertPrivate(state.projectId!);
        requireVersion(version, state.projectId!, state.sha!, state.versionId, 'verification_failed');
        if (!deployment.url || cleanUrl(site.current_live_url) !== deployment.url) throw new SitesError('verification_failed', '배포 완료 후 커밋·URL·공개 범위 검증에 실패했어.');
        state.phase = 'succeeded'; state.url = deployment.url; await store.save(state);
        this.emit('비공개 배포 완료'); return { ...receiptView(state), deployment };
      }
      if (deployment.failed) { state.phase = 'failed'; await store.save(state); throw new SitesError('deployment_failed', 'Sites 배포가 실패했어. 버전·배포 ID는 보존했어. 사이트 관리 화면에서 빌드 오류를 확인해.'); }
      this.emit(`배포 상태: ${deployment.status}`);
      if (Date.now() >= deadline) return { ...receiptView(state), deployment, next: 'sites_status로 같은 배포를 계속 확인해.' };
      await (this.options.sleep?.(5000) ?? delay(Math.min(5000, Math.max(0, deadline - Date.now())), undefined, { signal: this.signal }));
    } while (true);
  }
  async publish(path: string, options: { check_command?: string[]; save_only?: boolean; wait_seconds?: number } = {}) {
    const seconds = this.waitSeconds(options.wait_seconds ?? 30);
    const root = await projectRoot(path);
    const projectId = opaqueId((await readHosting(root)).project_id, 'hosting.json project_id');
    await this.requireOperations(['get_site', 'create_source_repository_write_credential', 'save_site_version', 'list_site_versions', 'get_site_version', ...(!options.save_only ? ['deploy_private_site_version', 'get_deployment_status'] : [])]);
    const store = this.store(root), git = this.git(root);
    const unlock = await store.lock();
    try {
      let state = await store.load();
      if (state?.projectId && state.projectId !== projectId) throw new SitesError('binding_mismatch', 'Site 연결과 기존 게시 기록이 달라.');
      await this.assertPrivate(projectId);
      const sha = await git.inspect(projectId);
      if (state?.sha && state.sha !== sha && !['succeeded', 'failed'].includes(state.phase) && !(state.phase === 'saved' && state.saveOnly === true)) throw new SitesError('publication_pending', '이전 커밋의 게시가 아직 끝나지 않았어. sites_status로 먼저 확인해.');
      if (!state?.sha || state.sha !== sha) {
        this.emit('로컬 빌드·커밋 검사 중');
        await git.check(options.check_command);
        if (await git.inspect(projectId) !== sha) throw new SitesError('source_changed', '빌드·검사 중 소스가 변경됐어. 검토·커밋 후 다시 시도해.');
        state = this.fresh(root, 'prepared', { projectId, sha, saveOnly: options.save_only === true }); await store.save(state);
      }
      if (state.phase === 'failed') throw new SitesError('previous_deployment_failed', '같은 커밋의 배포가 실패했어. 원인을 수정하고 새 커밋으로 게시해.');
      await this.reconcile(state, store);
      if (state.phase === 'succeeded' || state.phase === 'deploying') return await this.poll(state, store, seconds);
      if (['prepared', 'push_requested'].includes(state.phase)) {
        this.emit('Sites 저장소에 소스 전송 중');
        const credential = await this.api.call('create_source_repository_write_credential', { project_id: projectId });
        state.phase = 'push_requested'; await store.save(state);
        await git.push(credential, sha, projectId);
        state.phase = 'pushed'; await store.save(state);
      }
      if (state.phase === 'pushed') {
        let version = await this.versionForCommit(projectId, sha);
        if (!version) {
          this.emit('원격 빌드용 버전 저장 중');
          state.phase = 'save_requested'; await store.save(state);
          version = await this.api.call('save_site_version', { project_id: projectId, commit_sha: sha });
        }
        const versionId = opaqueId(version?.id, 'version_id');
        if (version?.project_id !== projectId || version.source && version.source.commit_sha !== sha) throw new SitesError('version_mismatch', '버전 저장 응답의 프로젝트·소스 커밋이 요청과 달라.');
        if (!version.source) version = await this.api.call('get_site_version', { project_id: projectId, version_id: versionId });
        requireVersion(version!, projectId, sha, versionId);
        state.versionId = versionId; state.phase = 'saved'; await store.save(state);
      }
      if (options.save_only) {
        state.saveOnly = true; await store.save(state);
        return { ...receiptView(state), next: '같은 소스에서 sites_publish를 실행하면 저장된 버전을 비공개 배포해.' };
      }
      if (state.phase !== 'saved') throw new SitesError('invalid_phase', '게시 기록의 단계를 확인하지 못했어. 자동으로 재시작하지 않아.');
      state.saveOnly = false; await store.save(state);
      await this.assertPrivate(projectId);
      const version = await this.api.call('get_site_version', { project_id: projectId, version_id: state.versionId });
      requireVersion(version, projectId, sha, state.versionId);
      if (version.deployment_id) {
        state.deploymentId = opaqueId(version.deployment_id); state.phase = 'deploying'; await store.save(state);
      } else {
        this.emit('비공개 배포 시작 중');
        state.phase = 'deploy_requested'; state.priorDeploymentId = version.deployment_id ?? undefined; await store.save(state);
        const deployment = await this.api.call('deploy_private_site_version', { project_id: projectId, version_id: state.versionId });
        state.deploymentId = opaqueId(deployment.id, 'deployment_id'); state.phase = 'deploying'; await store.save(state);
      }
      return await this.poll(state, store, seconds);
    } finally { await unlock(); }
  }
  async status(path: string, seconds = 0) {
    this.waitSeconds(seconds);
    const root = await projectRoot(path);
    const projectId = opaqueId((await readHosting(root)).project_id, 'hosting.json project_id');
    const store = this.store(root), unlock = await store.lock();
    try {
      const state = await store.load();
      if (!state) return { site: await this.get(root), local_publication: null };
      if (state.projectId && state.projectId !== projectId) throw new SitesError('binding_mismatch', 'Site 연결과 게시 기록이 달라.');
      await this.reconcile(state, store);
      if (state.deploymentId && ['deploying', 'succeeded'].includes(state.phase)) return await this.poll(state, store, seconds);
      return { ...receiptView(state), site: await this.get(root) };
    } finally { await unlock(); }
  }
  private waitSeconds(value: number) { if (!Number.isInteger(value) || value < 0 || value > 120) throw new SitesError('invalid_wait', '대기 시간은 0~120초여야 해.'); return value; }
}
