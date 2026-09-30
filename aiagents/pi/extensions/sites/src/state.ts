import { mkdir, open, readFile, rename, unlink, lstat } from 'node:fs/promises';
import { createHash, randomUUID } from 'node:crypto';
import { join } from 'node:path';
import { SitesError } from './security.ts';
import type { Receipt } from './types.ts';

export class StateStore {
  private key: string;
  constructor(private directory: string, public root: string, private accountId: string) { this.key = createHash('sha256').update(root).digest('hex'); }
  private async path(suffix: string) {
    await mkdir(this.directory, { recursive: true, mode: 0o700 });
    const path = join(this.directory, `${this.key}.${suffix}`);
    const stat = await lstat(path).catch((error: any) => { if (error.code === 'ENOENT') return null; throw error; });
    if (stat?.isSymbolicLink()) throw new SitesError('unsafe_state', 'Sites 상태 파일의 심볼릭 링크는 허용하지 않아.');
    return path;
  }
  async load(): Promise<Receipt | undefined> {
    const path = await this.path('json');
    let state;
    try { state = JSON.parse(await readFile(path, 'utf8')); } catch (error: any) { if (error.code === 'ENOENT') return; throw new SitesError('invalid_state', 'Sites 상태 기록을 읽지 못했어. 자동으로 덮어쓰지 않아.'); }
    if (state.format !== 1 || state.root !== this.root || state.accountId !== this.accountId) throw new SitesError('state_account_mismatch', '이 프로젝트의 게시 기록과 현재 계정이 달라. 원래 계정으로 전환해.');
    return state;
  }
  async save(state: Receipt) {
    const path = await this.path('json');
    const temporary = `${path}.${randomUUID()}.tmp`;
    const handle = await open(temporary, 'wx', 0o600);
    try { await handle.writeFile(JSON.stringify({ ...state, updatedAt: new Date().toISOString() }, null, 2) + '\n'); } finally { await handle.close(); }
    await rename(temporary, path);
  }
  async lock(): Promise<() => Promise<void>> {
    const path = await this.path('lock');
    const lease = randomUUID();
    let handle;
    try { handle = await open(path, 'wx', 0o600); }
    catch (error: any) { if (error.code === 'EEXIST') throw new SitesError('project_locked', `다른 Sites 작업이 이 프로젝트를 사용 중이야. 비정상 종료했다면 프로세스 종료를 확인한 후 잠금 파일만 제거해: ${path}`); throw error; }
    try { await handle.writeFile(JSON.stringify({ pid: process.pid, lease, createdAt: new Date().toISOString() })); }
    catch (error) { await handle.close(); await unlink(path); throw error; }
    await handle.close();
    return async () => { try { const current = JSON.parse(await readFile(path, 'utf8')); if (current.lease === lease) await unlink(path); } catch (error: any) { if (error.code !== 'ENOENT') throw error; } };
  }
}
