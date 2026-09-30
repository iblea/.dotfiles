import assert from "node:assert/strict";
import test from "node:test";
import fastExtension from "../extensions/fast.ts";

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

test("new sessions default to OFF and leave existing request settings untouched", () => {
	const h = setup();
	assert.match(h.statuses.get(STATE_TYPE), /OFF/);
	for (const service_tier of [undefined, "default", "flex", "priority"]) {
		const payload = { model: gpt.id, service_tier };
		assert.equal(h.request(payload), undefined);
		assert.equal(payload.service_tier, service_tier);
	}
	assert.deepEqual(h.entries, []);
});

test("bare /fast toggles on and off, persisting only changes", async () => {
	const h = setup();
	await h.command();
	assert.equal(h.request().service_tier, "priority");
	assert.match(h.statuses.get(STATE_TYPE), /ON/);
	assert.equal(h.notifications.at(-1).level, "warning");
	assert.match(h.notifications.at(-1).message, /추가 비용/);
	await h.command("on");
	assert.deepEqual(h.entries, [saved(true)]);
	await h.command();
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

test("restores the last valid state on the active branch, including reload and tree navigation", () => {
	const h = setup({ branch: [
		saved(false), saved(true),
		{ type: "custom", customType: "other", data: { enabled: false } },
		{ type: "message", customType: STATE_TYPE, data: { enabled: false } },
		{ type: "custom", customType: STATE_TYPE, data: null },
		{ type: "custom", customType: STATE_TYPE, data: { enabled: "false" } },
	] });
	assert.equal(h.request().service_tier, "priority");
	h.emit("session_start", { reason: "reload" });
	assert.equal(h.request().service_tier, "priority");
	h.entries.splice(0, h.entries.length, saved(false));
	h.emit("session_tree");
	assert.equal(h.request(), undefined);
});

test("switching to a new or unrelated session resets the default to OFF", async () => {
	for (const reason of ["new", "resume", "fork"]) {
		const h = setup();
		await h.command("on");
		h.entries.splice(0);
		h.emit("session_start", { reason });
		assert.equal(h.request(), undefined);
		assert.match(h.statuses.get(STATE_TYPE), /OFF/);
	}
});

test("non-interactive sessions apply restored state without touching the status UI", () => {
	const h = setup({ hasUI: false, branch: [saved(true)] });
	assert.equal(h.statuses.size, 0);
	assert.equal(h.request().service_tier, "priority");
});

test("offers argument completions without modifying state", () => {
	const h = setup();
	assert.deepEqual(h.complete("o").map((item) => item.value), ["on", "off"]);
	assert.deepEqual(h.complete("sta"), [{ value: "status", label: "status" }]);
	assert.equal(h.complete("invalid"), null);
	assert.equal(h.complete("").length, 3);
	assert.deepEqual(h.entries, []);
});
