import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { setImmediate } from "node:timers/promises";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { stripVTControlCharacters } from "node:util";

const here = dirname(fileURLToPath(import.meta.url));
const agentDir = resolve(
	process.env.PI_CODING_AGENT_DIR?.replace(/^~(?=\/|$)/, homedir()) || join(homedir(), ".pi", "agent"),
);
const install = join(agentDir, "install");
const version = readFileSync(join(install, "current-version"), "utf8").trim();
const modules = join(install, "releases", version, "node_modules");
const { createJiti } = createRequire(join(modules, "jiti/package.json"))("jiti");
const jiti = createJiti(import.meta.url, {
	moduleCache: false,
	alias: { "@earendil-works/pi-tui": join(modules, "@earendil-works/pi-tui/dist/index.js") },
});
const { parseWeeklyQuota, fetchWeeklyQuota, renderWeeklyQuota, WEEKLY_QUOTA_REFRESH_MS } =
	await jiti.import(join(here, "weekly-quota.ts"));
const statusline = await jiti.import(join(here, "index.ts"), { default: true });
const { visibleWidth } = await import(join(modules, "@earendil-works/pi-tui/dist/index.js"));
const plainTheme = { fg: (_color, text) => text };
const now = 1_800_000_000_000;
const reset = now / 1000 + 2 * 86400;
const window = (seconds, used = 14) => ({ limit_window_seconds: seconds, used_percent: used, reset_at: reset });
const payload = {
	rate_limit: { primary_window: window(18000, 99), secondary_window: window(604800) },
};
const claims = Buffer.from(JSON.stringify({ "https://api.openai.com/auth": { chatgpt_account_id: "test-account" } })).toString("base64url");
const token = `test.${claims}.test`;
const registry = { getApiKeyForProvider: async (provider) => {
	assert.equal(provider, "openai-codex");
	return token;
} };

test("7일 기간만 선택하고 5시간 및 추가 모델별 한도 제외", () => {
	assert.deepEqual(parseWeeklyQuota(payload), { remainingPercent: 86, resetsAt: reset });
	assert.deepEqual(parseWeeklyQuota({ rate_limit: { primary_window: window(604800), secondary_window: window(18000) } }),
		{ remainingPercent: 86, resetsAt: reset });
	assert.equal(parseWeeklyQuota({ rate_limit: { primary_window: window(18000), secondary_window: window(3600) } }), null);
	assert.equal(parseWeeklyQuota({ additional_rate_limits: [{ rate_limit: payload.rate_limit }] }), null);
});

test("잘못된 응답 및 사용률 경곗값", () => {
	for (const value of [null, undefined, [], "invalid", {}, { rate_limit: null }]) {
		assert.equal(parseWeeklyQuota(value), null);
	}
	for (const used of [null, "14", NaN, Infinity]) {
		assert.equal(parseWeeklyQuota({ rate_limit: { secondary_window: window(604800, used) } }), null);
	}
	for (const [used, remaining] of [[0, 100], [100, 0], [120, 0], [-5, 100], [14.2, 86]]) {
		assert.deepEqual(parseWeeklyQuota({ rate_limit: { secondary_window: { ...window(604800, used), reset_at: null } } }),
			{ remainingPercent: remaining, resetsAt: null });
	}
});

test("남은 비율과 리셋까지의 시간 표시, 만료된 값은 숨김", () => {
	const quota = { remainingPercent: 86, resetsAt: reset };
	assert.equal(renderWeeklyQuota(quota, plainTheme, now), "7d 86% left (reset 2d 0h)");
	assert.equal(renderWeeklyQuota({ ...quota, resetsAt: now / 1000 + 3660 }, plainTheme, now), "7d 86% left (reset 1h 1m)");
	assert.equal(renderWeeklyQuota({ ...quota, resetsAt: now / 1000 + 1 }, plainTheme, now), "7d 86% left (reset 1m)");
	assert.equal(renderWeeklyQuota({ ...quota, resetsAt: null }, plainTheme, now), "7d 86% left");
	assert.equal(renderWeeklyQuota(quota, plainTheme, reset * 1000), "7d ?");
	assert.equal(renderWeeklyQuota(null, plainTheme, now), "7d ?");
	const taggedTheme = { fg: (color, text) => `${color}:${text}` };
	assert.match(renderWeeklyQuota({ remainingPercent: 9, resetsAt: null }, taggedTheme), /^error:/);
	assert.match(renderWeeklyQuota({ remainingPercent: 10, resetsAt: null }, taggedTheme), /^warning:/);
	assert.match(renderWeeklyQuota({ remainingPercent: 25, resetsAt: null }, taggedTheme), /^mdLink:/);
});

test("pi OAuth를 통해 Codex usage API 조회, 리디렉션 금지", async (t) => {
	let calls = 0;
	t.mock.method(globalThis, "fetch", async (url, options) => {
		calls++;
		assert.equal(url, "https://chatgpt.com/backend-api/wham/usage");
		assert.equal(options.headers.Authorization, `Bearer ${token}`);
		assert.equal(options.headers["ChatGPT-Account-Id"], "test-account");
		assert.equal(options.redirect, "error");
		assert.equal(options.signal.aborted, false);
		return Response.json(payload);
	});
	assert.deepEqual(await fetchWeeklyQuota(registry, new AbortController().signal), { remainingPercent: 86, resetsAt: reset });
	assert.equal(calls, 1);
});

test("인증 없음, 취소, HTTP 오류, 비정상 응답에서 안전하게 미확인 처리", async (t) => {
	const fetchMock = t.mock.method(globalThis, "fetch", async () => { throw new Error("network unavailable"); });
	const signal = new AbortController().signal;
	for (const access of [undefined, "not-a-token", "x.e30.y", "x.!.y"]) {
		assert.equal(await fetchWeeklyQuota({ getApiKeyForProvider: async () => access }, signal), null);
	}
	assert.equal(await fetchWeeklyQuota(registry, AbortSignal.abort()), null);
	assert.equal(fetchMock.mock.callCount(), 0);
	assert.equal(await fetchWeeklyQuota(registry, signal), null);
	for (const status of [401, 403, 429, 500]) {
		fetchMock.mock.mockImplementation(async () => new Response("error", { status }));
		assert.equal(await fetchWeeklyQuota(registry, signal), null);
	}
	fetchMock.mock.mockImplementation(async () => new Response("not json"));
	assert.equal(await fetchWeeklyQuota(registry, signal), null);
	fetchMock.mock.mockImplementation(async () => Response.json({ rate_limit: null }));
	assert.equal(await fetchWeeklyQuota(registry, signal), null);
});

for (const provider of ["openai-codex", "openai"]) test(`footer: ${provider} 주간 한도·캐시·전환, 제공자 및 두 번째 줄 시간 표시`, async (t) => {
	let time = now;
	t.mock.method(Date, "now", () => time);
	const timers = new Set();
	t.mock.method(globalThis, "setInterval", (callback, ms) => {
		const timer = { callback, ms, unref() {} };
		timers.add(timer);
		return timer;
	});
	t.mock.method(globalThis, "clearInterval", (timer) => timers.delete(timer));
	let requests = 0;
	let requestSignal;
	let fail = false;
	t.mock.method(globalThis, "fetch", async (_url, options) => {
		requests++;
		requestSignal = options.signal;
		return fail ? new Response("error", { status: 429 }) : Response.json(payload);
	});
	const handlers = new Map();
	let footer;
	const ctx = {
		mode: "tui", cwd: resolve(here, "../../.."),
		model: { provider: "anthropic", id: "gpt-test", reasoning: true, contextWindow: 400000 },
		modelRegistry: registry,
		sessionManager: {
			getHeader: () => ({ timestamp: new Date(time - 300000).toISOString() }),
			getLeafId: () => "leaf", getEntries: () => [],
		},
		getContextUsage: () => ({ tokens: 96000, contextWindow: 400000, percent: 24 }),
		ui: {
			theme: plainTheme,
			setFooter: (factory) => {
				footer?.dispose();
				footer = factory?.({ requestRender() {} }, plainTheme, {
					onBranchChange: () => () => {}, getGitBranch: () => null,
					getExtensionStatuses: () => new Map([["openai-fast-mode", "fast: OFF"], ["other", "other status"]]),
				});
			},
		},
	};
	statusline({ on: (event, handler) => handlers.set(event, handler), registerCommand() {}, getThinkingLevel: () => "high" });
	try {
		handlers.get("session_start")({}, ctx);
		const clock = [...timers].find((timer) => timer.ms === 1000);
		await setImmediate();
		assert.equal(requests, 0);
		assert.doesNotMatch(footer.render(300)[1], /7d/);
		ctx.model.provider = provider;
		clock.callback();
		await setImmediate();
		assert.equal(requests, 1);
		const [firstLine, line] = footer.render(300).map(stripVTControlCharacters);
		assert.deepEqual(firstLine.split(" | ").slice(0, 3), ["🧠 gpt-test", "💪 high", provider]);
		assert.match(firstLine, /\| F$/);
		assert.doesNotMatch(firstLine, /\| 5m|\d{2}:\d{2}:\d{2}/);
		assert.match(line, /7d 86% left \(reset 2d 0h\) \| CTX /);
		assert.match(line, /\| 5m \| \d{2}:\d{2}:\d{2}$/);
		assert.doesNotMatch(line, /5h|99%|fast:|\| F \|/);
		assert.equal(footer.render(300)[2], "other status");
		for (const width of [1, 20, 80, 160]) assert.ok(footer.render(width).every((row) => visibleWidth(row) <= width));
		clock.callback();
		await setImmediate();
		assert.equal(requests, 1);
		time += WEEKLY_QUOTA_REFRESH_MS;
		fail = true;
		clock.callback();
		await setImmediate();
		assert.equal(requests, 2);
		assert.match(footer.render(300)[1], /7d \?/);
		clock.callback();
		await setImmediate();
		assert.equal(requests, 2);
		ctx.model.provider = "anthropic";
		clock.callback();
		await setImmediate();
		assert.equal(requests, 2);
		assert.doesNotMatch(footer.render(300)[1], /7d/);
		ctx.model.provider = provider;
		fail = false;
		clock.callback();
		await setImmediate();
		assert.equal(requests, 3);
		assert.match(footer.render(300)[1], /7d 86% left/);
		ctx.model.provider = provider === "openai" ? "openai-codex" : "openai";
		clock.callback();
		await setImmediate();
		assert.equal(requests, 4);
		assert.match(footer.render(300)[1], /7d 86% left/);
		assert.equal(footer.render(300)[0].split(" | ")[2], ctx.model.provider);
	} finally {
		handlers.get("session_shutdown")();
		footer?.dispose();
	}
	assert.equal(timers.size, 0);
	assert.equal(requestSignal.aborted, true);
});
