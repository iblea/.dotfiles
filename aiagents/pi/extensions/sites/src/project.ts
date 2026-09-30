import { lstat, readFile, realpath, mkdir, open, rename } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { SitesError } from './security.ts';
import type { Json } from './types.ts';

export async function projectRoot(path: string) {
  let root;
  try { root = await realpath(resolve(path)); if (!(await lstat(root)).isDirectory()) throw new Error(); }
  catch { throw new SitesError('invalid_project', '사이트 프로젝트 디렉터리를 찾을 수 없어.'); }
  for (const name of ['.openai', '.openai/hosting.json']) {
    const stat = await lstat(join(root, name)).catch((error: any) => { if (error.code === 'ENOENT') return null; throw error; });
    if (stat?.isSymbolicLink()) throw new SitesError('manifest_symlink', '사이트 메타데이터의 심볼릭 링크는 허용하지 않아.');
  }
  return root;
}
export async function readHosting(root: string): Promise<Json> {
  try {
    const text = await readFile(join(root, '.openai/hosting.json'), 'utf8');
    if (text.length > 65536) throw new Error();
    const value = JSON.parse(text);
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error();
    return value;
  } catch (error: any) {
    if (error.code === 'ENOENT') return {};
    throw new SitesError('invalid_manifest', '.openai/hosting.json이 유효한 JSON 객체가 아니야.');
  }
}
export async function bindProject(root: string, projectId: string) {
  await projectRoot(root);
  const value = await readHosting(root);
  if (value.project_id && value.project_id !== projectId) throw new SitesError('binding_mismatch', '기존 project_id를 다른 Site로 덮어쓰지 않아.');
  const dir = join(root, '.openai');
  await mkdir(dir, { recursive: true });
  const temporary = join(dir, `hosting.${randomUUID()}.tmp`);
  const handle = await open(temporary, 'wx', 0o600);
  try { await handle.writeFile(JSON.stringify({ ...value, project_id: projectId }, null, 2) + '\n'); } finally { await handle.close(); }
  await rename(temporary, join(dir, 'hosting.json'));
}
