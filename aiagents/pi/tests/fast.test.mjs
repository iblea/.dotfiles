import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmdirSync, unlinkSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import test, { afterEach, beforeEach } from "node:test";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const originalAgentDir = process.env.PI_CODING_AGENT_DIR;
const agentDir = resolve(originalAgentDir?.replace(/^~(?=\/|$)/, homedir()) || join(homedir(), ".pi", "agent"));
const version = readFileSync(join(agentDir, "install/current-version"), "utf8").trim();
const modules = join(agentDir, "install/releases", version, "node_modules");
const { createJiti } = createRequire(join(modules, "jiti/package.json"))("jiti");
const jiti = createJiti(import.meta.url, {
	moduleCache: false,
	alias: { "@earendil-works/pi-coding-agent": join(modules, "@earendil-works/pi-coding-agent/dist/index.js") },
});
const fastExtension = await jiti.import(join(here, "../extensions/fast.ts"), { default: true });
let testDir;
let statePath;
beforeEach(() => {
	testDir = mkdtempSync(join(tmpdir(), "pi-fast-test-"));
	statePath = join(testDir, "fast.json");
	process.env.PI_CODING_AGENT_DIR = testDir;
});
afterEach(() => {
	if (originalAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
	else process.env.PI_CODING_AGENT_DIR = originalAgentDir;
	// 이 테스트가 만든 파일과 빈 디렉터리만 정리
	for (const entry of readdirSync(testDir, { withFileTypes: true })) {
		const path = join(testDir, entry.name);
		if (entry.isDirectory()) rmdirSync(path);
		else unlinkSync(path);
	}
	rmdirSync(testDir);
});

const STATE_TYPE = "openai-fast-mode";
const gpt = { provider: "openai", api: "openai-responses", id: "gpt-test" };
const saved = (enabled) => ({ type: "custom", customType: STATE_TYPE, data: { enabled } });

function setup({ model = gpt, branch = [], hasUI = true } = {}) {
	const handlers = new Map();
	const commands = new Map();
	const entries = [...branch];
	const notifications = [];
	const statuses = new Map();
	const ctx = {
		model,
		hasUI,
		sessionManager: { getBranch: () => entries },
		ui: {
			setStatus: (key, text) => statuses.set(key, text),
			notify: (message, level) => notifications.push({ message, level }),
		},
	};
	fastExtension({
		on: (name, handler) => handlers.set(name, handler),
		registerCommand: (name, command) => commands.set(name, command),
		appendEntry: (customType, data) => entries.push({ type: "custom", customType, data }),
	});
	const emit = (name, event = {}) => handlers.get(name)({ type: name, ...event }, ctx);
	emit("session_start", { reason: "startup" });
	return {
		ctx, entries, notifications, statuses, emit,
		command: (args = "") => commands.get("fast").handler(args, ctx),
		complete: (prefix) => commands.get("fast").getArgumentCompletions(prefix),
		request: (payload = { model: ctx.model?.id }) => emit("before_provider_request", { payload }),
	};
}

test("missing global settings default to OFF and leave existing request settings untouched", () => {
	const h = setup();
	assert.match(h.statuses.get(STATE_TYPE), /OFF/);
	for (const service_tier of [undefined, "default", "flex", "priority"]) {
		const payload = { model: gpt.id, service_tier };
		assert.equal(h.request(payload), undefined);
		assert.equal(payload.service_tier, service_tier);
	}
	assert.deepEqual(h.entries, []);
});

test("bare /fast saves ON/OFF globally and records only changed values in session history", async () => {
	const h = setup();
	await h.command();
	assert.deepEqual(JSON.parse(readFileSync(statePath, "utf8")), { enabled: true });
	assert.equal(h.request().service_tier, "priority");
	assert.match(h.statuses.get(STATE_TYPE), /ON/);
	assert.equal(h.notifications.at(-1).level, "warning");
	assert.match(h.notifications.at(-1).message, /추가 비용/);
	await h.command("on");
	assert.deepEqual(h.entries, [saved(true)]);
	await h.command();
	assert.deepEqual(JSON.parse(readFileSync(statePath, "utf8")), { enabled: false });
	assert.equal(h.request(), undefined);
	assert.deepEqual(h.entries, [saved(true), saved(false)]);
	await h.command("off");
	assert.equal(h.entries.length, 2);
});

test("explicit commands accept whitespace and case without changing reasoning", async () => {
	const h = setup();
	await h.command(" ON \n");
	const payload = Object.freeze({
		model: gpt.id,
		input: [{ role: "user", content: "test" }],
		reasoning: { effort: "high" },
		service_tier: "flex",
		stream: true,
	});
	assert.deepEqual(h.request(payload), { ...payload, service_tier: "priority" });
	assert.equal(payload.service_tier, "flex");
	await h.command(" OFF ");
	assert.equal(h.request(payload), undefined);
});

test("status and invalid arguments never toggle the mode", async () => {
	const h = setup();
	await h.command("status");
	assert.match(h.notifications.at(-1).message, /OFF/);
	for (const arg of ["enable", "on off", "true", "1"]) {
		await h.command(arg);
		assert.equal(h.request(), undefined);
		assert.equal(h.notifications.at(-1).level, "warning");
	}
	await h.command("on");
	await h.command("status");
	assert.match(h.notifications.at(-1).message, /priority 요청/);
	await h.command("invalid");
	assert.equal(h.request().service_tier, "priority");
	assert.deepEqual(h.entries, [saved(true)]);
});

for (const model of [
	gpt,
	{ ...gpt, api: "openai-completions" },
	{ ...gpt, provider: "openai-codex", api: "openai-codex-responses" },
]) {
	test(`adds priority for ${model.provider}/${model.api}`, async () => {
		const h = setup({ model });
		await h.command("on");
		assert.equal(h.request().service_tier, "priority");
	});
}

for (const model of [
	null,
	{ ...gpt, provider: "anthropic", api: "anthropic-messages", id: "claude-test" },
	{ ...gpt, provider: "openrouter" },
	{ ...gpt, api: "anthropic-messages" },
	{ ...gpt, provider: "openai-codex" },
	{ ...gpt, id: "o3" },
]) {
	test(`rejects enabling on unsupported model ${JSON.stringify(model)}`, async () => {
		const h = setup({ model });
		await h.command("on");
		assert.equal(h.request(), undefined);
		assert.deepEqual(h.entries, []);
		assert.equal(h.notifications.at(-1).level, "warning");
	});
}

test("malformed payloads and requests for another model are not modified", async () => {
	const h = setup();
	await h.command("on");
	for (const payload of [null, false, 0, "request", [], {}, { model: "gpt-other" }]) {
		assert.equal(h.request(payload), undefined);
	}
	assert.equal(h.emit("before_provider_request", { payload: undefined }), undefined);
});

test("model changes suspend application without losing the toggle; OFF always works", async () => {
	const h = setup();
	await h.command("on");
	h.ctx.model = { ...gpt, provider: "other" };
	h.emit("model_select");
	assert.match(h.statuses.get(STATE_TYPE), /미적용/);
	assert.equal(h.request(), undefined);
	h.ctx.model = gpt;
	h.emit("model_select");
	assert.equal(h.request().service_tier, "priority");
	h.ctx.model = undefined;
	await h.command("off");
	assert.match(h.statuses.get(STATE_TYPE), /OFF/);
});

test("global ON/OFF survives a fresh extension instance and overrides old session entries", async () => {
	const first = setup();
	await first.command("on");
	const restarted = setup({ branch: [saved(false)] });
	assert.equal(restarted.request()?.service_tier, "priority");
	assert.deepEqual(JSON.parse(readFileSync(statePath, "utf8")), { enabled: true });
	await restarted.command("off");
	const restartedAgain = setup({ branch: [saved(true)] });
	assert.equal(restartedAgain.request(), undefined);
	assert.deepEqual(JSON.parse(readFileSync(statePath, "utf8")), { enabled: false });
	assert.deepEqual(readdirSync(testDir), ["fast.json"]);
});

test("new, resumed, forked and reloaded sessions keep the global preference", async () => {
	const h = setup();
	await h.command("on");
	for (const reason of ["new", "resume", "fork", "reload"]) {
		h.entries.splice(0, h.entries.length, saved(false));
		h.emit("session_start", { reason });
		assert.equal(h.request()?.service_tier, "priority", reason);
		assert.match(h.statuses.get(STATE_TYPE), /ON/);
	}
});

test("tree navigation does not restore an older session choice", async () => {
	const h = setup();
	await h.command("on");
	h.entries.splice(0, h.entries.length, saved(false));
	h.emit("session_tree");
	assert.equal(h.request()?.service_tier, "priority");
	await h.command("off");
	h.entries.splice(0, h.entries.length, saved(true));
	h.emit("session_tree");
	assert.equal(h.request(), undefined);
});

test("missing global settings default to OFF even when an old session recorded ON", () => {
	const h = setup({ branch: [saved(true)] });
	assert.equal(h.request(), undefined);
	assert.match(h.statuses.get(STATE_TYPE), /OFF/);
	assert.equal(existsSync(statePath), false);
	assert.deepEqual(h.notifications, []);
});

test("non-interactive sessions apply the global preference without touching the status UI", () => {
	writeFileSync(statePath, '{"enabled":true}');
	const h = setup({ hasUI: false });
	assert.equal(h.statuses.size, 0);
	assert.equal(h.request()?.service_tier, "priority");
});

test("restoring ON on an unsupported model keeps the preference but does not apply priority", () => {
	writeFileSync(statePath, '{"enabled":true}');
	const h = setup({ model: { ...gpt, provider: "other" } });
	assert.match(h.statuses.get(STATE_TYPE), /미적용/);
	assert.equal(h.request(), undefined);
	h.ctx.model = gpt;
	h.emit("model_select");
	assert.equal(h.request()?.service_tier, "priority");
});

test("status, invalid commands and rejected ON do not write global settings", async () => {
	const h = setup({ model: null });
	for (const arg of ["status", "invalid", "on", ""]) await h.command(arg);
	assert.equal(existsSync(statePath), false);
});

test("repeating an explicit choice saves it even when this instance already has that state", async () => {
	const first = setup();
	const second = setup();
	await first.command("on");
	await second.command("off");
	assert.deepEqual(JSON.parse(readFileSync(statePath, "utf8")), { enabled: false });
	assert.equal(setup().request(), undefined);
});

for (const text of ["{", "null", "[]", "{}", '{"enabled":"true"}', '{"enabled":1}']) {
	test(`invalid global settings default to OFF and warn: ${text}`, () => {
		writeFileSync(statePath, text);
		const h = setup({ branch: [saved(true)] });
		assert.equal(h.request(), undefined);
		assert.match(h.statuses.get(STATE_TYPE), /OFF/);
		assert.equal(h.notifications.at(-1)?.level, "warning");
		assert.equal(readFileSync(statePath, "utf8"), text);
	});
}

test("unreadable settings warn and default to OFF", () => {
	mkdirSync(statePath);
	const h = setup({ branch: [saved(true)] });
	assert.equal(h.request(), undefined);
	assert.equal(h.notifications.at(-1)?.level, "warning");
});

test("failed saves warn but still apply the current choice, especially OFF", async () => {
	const h = setup();
	await h.command("on");
	unlinkSync(statePath);
	mkdirSync(statePath);
	await h.command("off");
	assert.equal(h.request(), undefined);
	assert.match(h.statuses.get(STATE_TYPE), /OFF/);
	assert.equal(h.notifications.at(-1)?.level, "warning");
	assert.match(h.notifications.at(-1).message, /저장/);
	assert.deepEqual(readdirSync(testDir), ["fast.json"]);
	await h.command("on");
	assert.equal(h.request()?.service_tier, "priority");
	assert.equal(h.notifications.at(-1)?.level, "warning");
	assert.deepEqual(readdirSync(testDir), ["fast.json"]);
});

test("offers argument completions without modifying state", () => {
	const h = setup();
	assert.deepEqual(h.complete("o").map((item) => item.value), ["on", "off"]);
	assert.deepEqual(h.complete("sta"), [{ value: "status", label: "status" }]);
	assert.equal(h.complete("invalid"), null);
	assert.equal(h.complete("").length, 3);
	assert.deepEqual(h.entries, []);
});
