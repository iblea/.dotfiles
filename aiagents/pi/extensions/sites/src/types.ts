export type Json = Record<string, any>;
export interface Identity {
  token: string;
  accountId: string;
  /** Authoritative Sites-policy identity, when obtained from a comparable identity source. */
  accountUserId?: string;
  /** OAuth subject namespace; not necessarily equal to Sites' UUID-shaped account-user ID. */
  oauthAccountUserId?: string;
  email?: string;
}
export interface Api {
  identity: Identity;
  discover(): Promise<Map<string, Json>>;
  call(name: string, args: Json): Promise<any>;
}
export interface Receipt {
  format: 1;
  root: string;
  accountId: string;
  projectId?: string;
  slug?: string;
  title?: string;
  phase: 'create_requested' | 'linked' | 'prepared' | 'push_requested' | 'pushed' | 'save_requested' | 'saved' | 'deploy_requested' | 'deploying' | 'succeeded' | 'failed';
  sha?: string;
  versionId?: string;
  deploymentId?: string;
  priorDeploymentId?: string;
  saveOnly?: boolean;
  url?: string;
  startedAt: string;
  updatedAt: string;
}
export interface RunResult { stdout: string; stderr: string; code: number }
export type Runner = (cwd: string, command: string, args: string[], options?: { env?: NodeJS.ProcessEnv; signal?: AbortSignal }) => Promise<RunResult>;
