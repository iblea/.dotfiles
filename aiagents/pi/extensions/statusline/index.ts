/** Claude Code 스타일의 2줄 footer. /statusline [on|off]로 전환 */
import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { promisify, stripVTControlCharacters } from "node:util";
import type {
	ContextUsage,
	ExtensionAPI,
	ExtensionContext,
	SessionEntry,
	Theme,
} from "@earendil-works/pi-coding-agent";
import { sliceByColumn, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { fetchWeeklyQuota, renderWeeklyQuota, WEEKLY_QUOTA_REFRESH_MS, type WeeklyQuota } from "./weekly-quota.ts";

const execFileAsync = promisify(execFile);
const VIRTUAL_CONTEXT_TOKENS = 200_000;
const PATH_WIDTH = 40;
const GIT_REFRESH_MS = 5_000;

function singleLine(text: string): string {
	return stripVTControlCharacters(text).replace(/[\x00-\x1f\x7f-\x9f]/g, " ");
}

export function formatPath(cwd: string, home = homedir()): string {
	const abbreviated = cwd === home ? "~" : cwd.startsWith(`${home}/`) ? `~${cwd.slice(home.length)}` : cwd;
	const path = singleLine(abbreviated);
	const width = visibleWidth(path);
	return width <= PATH_WIDTH ? path : `...${sliceByColumn(path, width - PATH_WIDTH + 3, PATH_WIDTH - 3)}`;
}

export function formatTokens(tokens: number): string {
	if (tokens < 1_000) return `${tokens}`;
	if (tokens < 1_000_000) return `${+(tokens / 1_000).toFixed(1)}k`;
	return `${+(tokens / 1_000_000).toFixed(1)}m`;
}

export function formatDuration(start: number, now: number): string {
	const minutes = Math.max(0, Math.floor((now - start) / 60_000));
	if (minutes === 0) return "<1m";
	return minutes < 60 ? `${minutes}m` : `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
}

export interface GitStatus {
	branch: string;
	stash: number;
	staged: number;
	modified: number;
	untracked: number;
	conflicts: number;
}

export function parseGitStatus(output: string): GitStatus {
	const status: GitStatus = { branch: "", stash: 0, staged: 0, modified: 0, untracked: 0, conflicts: 0 };
	let oid = "";
	const records = output.split("\0");
	for (let i = 0; i < records.length; i++) {
		const record = records[i];
		if (record.startsWith("# branch.head ")) status.branch = record.slice(14);
		else if (record.startsWith("# branch.oid ")) oid = record.slice(13);
		else if (record.startsWith("# stash ")) status.stash = Number(record.slice(8)) || 0;
		else if (record.startsWith("? ")) status.untracked++;
		else if (record.startsWith("u ")) status.conflicts++;
		else if (record.startsWith("1 ") || record.startsWith("2 ")) {
			if (record[2] !== ".") status.staged++;
			if (record[3] !== ".") status.modified++;
			// -z rename/copy 레코드 뒤의 원래 파일명 건너뛰기
			if (record[0] === "2") i++;
		}
	}
	if (status.branch === "(detached)") status.branch = oid.slice(0, 7) || "detached";
	return status;
}

export async function readGitStatus(cwd: string, signal?: AbortSignal): Promise<GitStatus | null> {
	try {
		const { stdout } = await execFileAsync("git", [
			"--no-optional-locks", "status", "--porcelain=v2", "-z", "--branch", "--show-stash", "--untracked-files=all",
		], { cwd, signal, timeout: 2_000, maxBuffer: 2 * 1024 * 1024, encoding: "utf8" });
		return parseGitStatus(stdout);
	} catch {
		// Git 미설치, 저장소 외부, 타임아웃, 종료 중 취소 시 footer 유지
		return null;
	}
}

export function gitSummary(status: GitStatus): string {
	return [
		["*", status.stash], ["+", status.staged], ["!", status.modified],
		["?", status.untracked], ["~", status.conflicts],
	].filter(([, count]) => Number(count) > 0).map(([symbol, count]) => `${symbol}${count}`).join(" ");
}

export function collectUsage(entries: readonly SessionEntry[]) {
	let input = 0, output = 0, cost = 0;
	for (const entry of entries) {
		const usage = entry.type === "message"
			? (entry.message.role === "assistant" || entry.message.role === "toolResult" ? entry.message.usage : undefined)
			: (entry.type === "usage" || entry.type === "compaction" || entry.type === "branch_summary" ? entry.usage : undefined);
		if (!usage) continue;
		// 누적 입력에 캐시 토큰 포함. 압축/도구/캐시 워밍 비용도 합산
		input += usage.input + usage.cacheRead + usage.cacheWrite;
		output += usage.output;
		cost += usage.cost.total;
	}
	return { input, output, cost };
}

export function renderContext(usage: ContextUsage | undefined, theme: Theme): string {
	const virtual = (usage?.contextWindow ?? 0) >= 1_000_000;
	const label = virtual ? `CTX/${formatTokens(VIRTUAL_CONTEXT_TOKENS)}` : "CTX";
	const maxContext = (usage?.contextWindow ?? 0) > 0 ? ` (max ${formatTokens(usage!.contextWindow)})` : "";
	if (!usage || usage.tokens === null || usage.contextWindow <= 0) {
		return theme.fg("dim", `${label} ░░░░░░░░░░ ?${maxContext}`);
	}
	const clamp = (percent: number) => Math.max(0, Math.min(100, percent));
	const actualUsed = clamp(usage.tokens / usage.contextWindow * 100);
	const used = clamp(usage.tokens / (virtual ? VIRTUAL_CONTEXT_TOKENS : usage.contextWindow) * 100);
	const remaining = Math.round(100 - used);
	const overVirtual = virtual && usage.tokens >= VIRTUAL_CONTEXT_TOKENS;
	const filled = Math.floor((overVirtual ? actualUsed : used) / 10);
	const barColor = overVirtual ? "dim" : used >= 85 ? "error" : used >= 70 ? "warning" : "success";
	const remainingColor = remaining < 10 ? "error" : remaining < 20 ? "warning" : "success";
	const bar = theme.fg(barColor, "█".repeat(filled)) + theme.fg("dim", "░".repeat(10 - filled));
	const actual = overVirtual ? theme.fg("warning", ` (actual ${Math.round(100 - actualUsed)}% left)`) : "";
	return `${theme.fg("muted", label)} ${bar} ${theme.fg(remainingColor, `${remaining}% left`)}${theme.fg("muted", maxContext)}${actual}`;
}

export default function statusline(pi: ExtensionAPI) {
	let enabled = true;
	let disposeFooter: (() => void) | undefined;

	function install(ctx: ExtensionContext) {
		disposeFooter?.();
		if (ctx.mode !== "tui" || !enabled) return;

		ctx.ui.setFooter((tui, _theme, footerData) => {
			let disposed = false;
			let git: GitStatus | null = null;
			let gitPending = false;
			let metricsKey = "";
			let usage = { input: 0, output: 0, cost: 0 };
			let context: ContextUsage | undefined;
			let weeklyQuota: WeeklyQuota | null = null;
			let quotaPending = false;
			let quotaProvider: string | undefined;
			let quotaGeneration = 0;
			let nextQuotaRefresh = 0;
			let memoryMB = 0;
			const started = Date.parse(ctx.sessionManager.getHeader()?.timestamp ?? "") || Date.now();
			const controller = new AbortController();

			function refreshMetrics() {
				// 매 렌더마다 전체 transcript를 순회하지 않도록 변경 시에만 집계
				const model = ctx.model;
				const key = JSON.stringify([ctx.sessionManager.getLeafId(), model?.provider, model?.id, model?.contextWindow]);
				if (key !== metricsKey) {
					metricsKey = key;
					usage = collectUsage(ctx.sessionManager.getEntries());
					context = ctx.getContextUsage();
				}
				memoryMB = Math.round(process.memoryUsage.rss() / 1024 / 1024);
			}

			async function refreshGit() {
				if (disposed || gitPending) return;
				gitPending = true;
				try {
					const result = await readGitStatus(ctx.cwd, controller.signal);
					if (!disposed) {
						git = result;
						tui.requestRender();
					}
				} finally {
					gitPending = false;
				}
			}

			async function refreshQuota() {
				if (disposed) return;
				const provider = ctx.model?.provider;
				if (provider !== quotaProvider) {
					quotaProvider = provider;
					quotaGeneration++;
					weeklyQuota = null;
					nextQuotaRefresh = 0;
				}
				if ((provider !== "openai-codex" && provider !== "openai") || quotaPending || Date.now() < nextQuotaRefresh) return;
				const generation = quotaGeneration;
				quotaPending = true;
				nextQuotaRefresh = Date.now() + WEEKLY_QUOTA_REFRESH_MS;
				try {
					const result = await fetchWeeklyQuota(ctx.modelRegistry, controller.signal);
					if (!disposed && generation === quotaGeneration && ctx.model?.provider === provider) {
						weeklyQuota = result;
						// 주간 리셋 시점에는 3분 캐시보다 먼저 갱신
						if (result?.resetsAt && result.resetsAt * 1000 > Date.now()) {
							nextQuotaRefresh = Math.min(nextQuotaRefresh, result.resetsAt * 1000);
						}
						tui.requestRender();
					}
				} finally {
					quotaPending = false;
				}
			}

			refreshMetrics();
			void refreshGit();
			void refreshQuota();
			const clock = setInterval(() => {
				refreshMetrics();
				void refreshQuota();
				tui.requestRender();
			}, 1_000);
			const gitPoll = setInterval(() => void refreshGit(), GIT_REFRESH_MS);
			clock.unref();
			gitPoll.unref();
			const unsubscribe = footerData.onBranchChange(() => void refreshGit());
			const dispose = () => {
				if (disposed) return;
				disposed = true;
				clearInterval(clock);
				clearInterval(gitPoll);
				controller.abort();
				unsubscribe();
			};
			disposeFooter = dispose;

			return {
				dispose,
				invalidate() {},
				render(width: number): string[] {
					if (disposed) return [];
					// 테마 변경 시 현재 팔레트 사용
					const theme = ctx.ui.theme;
					const separator = theme.fg("dim", " | ");
					const model = ctx.model;
					let modelName = singleLine(model?.name || model?.id || "no-model").replace(/\(1M context\)/gi, "[1m]");
					if ((model?.contextWindow ?? 0) >= 1_000_000 && !/\[1m\]/i.test(modelName)) modelName += " [1m+]";
					const first = [`🧠 ${theme.fg("accent", modelName)}`];
					if (model?.reasoning) {
						const effort = pi.getThinkingLevel();
						first.push(theme.fg(effort === "max" ? "error" : effort === "xhigh" ? "warning" : "muted", `💪 ${effort}`));
					}
					first.push(theme.fg("muted", singleLine(model?.provider || "no-provider")));
					const branch = git?.branch || footerData.getGitBranch();
					const changes = git ? gitSummary(git) : "";
					first.push(branch
						? theme.fg("thinkingHigh", singleLine(branch)) + (changes ? theme.fg("warning", ` (${changes})`) : "")
						: theme.fg("muted", "X"));
					first.push(theme.fg("mdLink", formatPath(ctx.cwd)));
					const memoryColor = memoryMB < 500 ? "success" : memoryMB < 1_000 ? "warning" : memoryMB < 2_000 ? "thinkingHigh" : "error";
					first.push(`${theme.fg(memoryColor, `${memoryMB}MB`)} ${theme.fg("muted", `(${process.pid})`)}`);

					const extensionStatuses = footerData.getExtensionStatuses();
					const fastStatus = extensionStatuses.get("openai-fast-mode");
					const now = Date.now();
					if (fastStatus) first.push(theme.fg(fastStatus.startsWith("fast: ON") ? "success" : "muted", "F"));
					const second = [
						theme.fg("mdLink", `↑${formatTokens(usage.input)} ↓${formatTokens(usage.output)} ~$${usage.cost.toFixed(3)}`),
						...(model?.provider === "openai-codex" || model?.provider === "openai" ? [renderWeeklyQuota(weeklyQuota, theme, now)] : []),
						renderContext(context, theme),
						theme.fg("muted", formatDuration(started, now)),
						theme.fg("muted", new Date(now).toTimeString().slice(0, 8)),
					];
					const lines = [first.join(separator), second.join(separator)];
					// 다른 확장의 setStatus() 정보 보존
					const statuses = [...extensionStatuses]
						.filter(([key]) => key !== "openai-fast-mode")
						.sort(([a], [b]) => a.localeCompare(b));
					if (statuses.length) lines.push(statuses.map(([, text]) => text.replace(/[\r\n\t]/g, " ")).join(separator));
					return lines.map((line) => truncateToWidth(line, Math.max(0, width), "…"));
				},
			};
		});
	}

	pi.on("session_start", (_event, ctx) => install(ctx));
	pi.on("session_shutdown", () => disposeFooter?.());
	pi.registerCommand("statusline", {
		description: "Toggle Claude-style footer: /statusline [on|off]",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("Statusline requires interactive TUI mode.", "warning");
				return;
			}
			const option = args.trim();
			if (option && option !== "on" && option !== "off") {
				ctx.ui.notify("Usage: /statusline [on|off]", "warning");
				return;
			}
			enabled = option ? option === "on" : !enabled;
			if (enabled) install(ctx);
			else {
				disposeFooter?.();
				ctx.ui.setFooter(undefined);
			}
		},
	});
}
