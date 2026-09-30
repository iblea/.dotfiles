import type { ModelRegistry, Theme } from "@earendil-works/pi-coding-agent";

export const WEEKLY_QUOTA_REFRESH_MS = 180_000;
const WEEK_SECONDS = 7 * 24 * 60 * 60;
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";

export interface WeeklyQuota {
	remainingPercent: number;
	resetsAt: number | null;
}

function record(value: unknown): Record<string, unknown> | undefined {
	return value !== null && typeof value === "object" && !Array.isArray(value)
		? value as Record<string, unknown>
		: undefined;
}

export function parseWeeklyQuota(payload: unknown): WeeklyQuota | null {
	// Codex backend-client: rate_limit의 기본 Codex 한도만 사용 (추가 모델별 한도 제외)
	const limits = record(record(payload)?.rate_limit);
	for (const key of ["secondary_window", "primary_window"]) {
		const window = record(limits?.[key]);
		// secondary라는 이름만으로 주간 한도로 추정하지 않고 실제 기간 확인
		if (window?.limit_window_seconds !== WEEK_SECONDS) continue;
		const used = window.used_percent;
		if (typeof used !== "number" || !Number.isFinite(used)) continue;
		const reset = window.reset_at;
		return {
			remainingPercent: Math.round(Math.max(0, Math.min(100, 100 - used))),
			resetsAt: typeof reset === "number" && Number.isFinite(reset) && reset > 0 ? reset : null,
		};
	}
	return null;
}

export async function fetchWeeklyQuota(
	registry: Pick<ModelRegistry, "getApiKeyForProvider">,
	signal: AbortSignal,
): Promise<WeeklyQuota | null> {
	try {
		if (signal.aborted) return null;
		// pi 인증 경로 사용: OAuth 갱신을 pi에 위임, Codex CLI 인증 파일은 변경하지 않음
		const token = await registry.getApiKeyForProvider("openai-codex");
		if (!token || signal.aborted) return null;
		const parts = token.split(".");
		if (parts.length !== 3) return null;
		const claims = record(JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8")));
		const accountId = record(claims?.["https://api.openai.com/auth"])?.chatgpt_account_id;
		if (typeof accountId !== "string" || !accountId) return null;

		// Codex backend-client/src/client/rate_limit_resets.rs와 동일한 읽기 전용 API
		const response = await fetch(USAGE_URL, {
			headers: {
				Authorization: `Bearer ${token}`,
				"ChatGPT-Account-Id": accountId,
				Accept: "application/json",
				"User-Agent": "pi-statusline",
				originator: "pi",
			},
			redirect: "error",
			signal: AbortSignal.any([signal, AbortSignal.timeout(10_000)]),
		});
		if (!response.ok) {
			await response.body?.cancel();
			return null;
		}
		return parseWeeklyQuota(await response.json());
	} catch {
		// 네트워크/인증 오류로 TUI를 방해하지 않고 토큰과 응답 본문은 기록하지 않음
		return null;
	}
}

export function renderWeeklyQuota(quota: WeeklyQuota | null, theme: Theme, now = Date.now()): string {
	if (!quota || (quota.resetsAt !== null && quota.resetsAt * 1000 <= now)) {
		return theme.fg("dim", "7d ?");
	}
	const color = quota.remainingPercent < 10 ? "error" : quota.remainingPercent < 25 ? "warning" : "mdLink";
	const percent = theme.fg(color, `7d ${quota.remainingPercent}% left`);
	if (quota.resetsAt === null) return percent;
	const minutes = Math.ceil((quota.resetsAt * 1000 - now) / 60_000);
	const days = Math.floor(minutes / 1440);
	const hours = Math.floor(minutes / 60) % 24;
	const reset = days > 0 ? `${days}d ${hours}h` : minutes >= 60 ? `${hours}h ${minutes % 60}m` : `${minutes}m`;
	return `${percent} ${theme.fg("muted", `(reset ${reset})`)}`;
}
