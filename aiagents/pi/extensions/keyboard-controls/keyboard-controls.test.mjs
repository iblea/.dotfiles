import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { setImmediate } from "node:timers/promises";
import test from "node:test";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const agentDir = resolve(
	process.env.PI_CODING_AGENT_DIR?.replace(/^~(?=\/|$)/, homedir()) || join(homedir(), ".pi", "agent"),
);
const version = readFileSync(join(agentDir, "install/current-version"), "utf8").trim();
const modules = join(agentDir, "install/releases", version, "node_modules");
const host = join(modules, "@earendil-works/pi-coding-agent");
const require = createRequire(join(modules, "jiti/package.json"));
const { createJiti } = require("jiti");
const jiti = createJiti(import.meta.url, {
	moduleCache: false,
	alias: {
		"@earendil-works/pi-coding-agent": join(host, "dist/index.js"),
		"@earendil-works/pi-tui": join(modules, "@earendil-works/pi-tui/dist/index.js"),
	},
});
const { default: install, ShortcutEditor } = await jiti.import(join(here, "index.ts"));
const { KeybindingsManager } = await import(join(host, "dist/core/keybindings.js"));
const { getEditorTheme } = await import(join(host, "dist/modes/interactive/theme/theme.js"));
const { SessionSelectorComponent } = await import(join(host, "dist/modes/interactive/components/session-selector.js"));
const { SelectList, setKeybindings, isKeyRelease, isKeyRepeat, setKittyProtocolActive } =
	await import(join(modules, "@earendil-works/pi-tui/dist/index.js"));
const bindings = JSON.parse(readFileSync(join(agentDir, "keybindings.json"), "utf8"));

function setup() {
	const keys = new KeybindingsManager(bindings);
	setKeybindings(keys);
	let now = 1000;
	const events = [];
	const controls = { abort: () => events.push("fallback-abort"), shutdown: () => events.push("fallback-exit") };
	const tui = { requestRender() {}, getFocusedComponent: () => editor };
	const editor = new ShortcutEditor(tui, getEditorTheme(), keys, controls, () => now);
	editor.onEscape = () => events.push("interrupt");
	editor.onCtrlD = () => events.push("exit");
	editor.onAction("app.clear", () => { throw new Error("Native clear/double-exit handler must not run"); });
	editor.onAction("app.editor.external", () => events.push("external"));
	return { editor, events, keys, at: (value) => { now = value; } };
}

async function openAutocomplete(editor) {
	editor.setAutocompleteProvider({
		getSuggestions: async () => ({
			prefix: "/s", items: [{ value: "/session", label: "session" }, { value: "/settings", label: "settings" }],
		}),
		applyCompletion: () => { throw new Error("Should cancel, not apply completion"); },
	});
	editor.setText("/s");
	editor.handleInput("\t");
	await setImmediate();
	assert.equal(editor.isShowingAutocomplete(), true);
}

test("실제 설정 및 기존 메뉴 취소/복사 보존", () => {
	const { keys } = setup();
	assert.deepEqual(keys.getKeys("app.interrupt"), ["ctrl+c"]);
	assert.deepEqual(keys.getKeys("app.clear"), ["ctrl+g"]);
	assert.deepEqual(keys.getKeys("tui.altScreen.searchNext"), ["enter", "ctrl+g"]);
	assert.deepEqual(keys.getKeys("app.editor.external"), ["ctrl+k"]);
	assert.deepEqual(keys.getKeys("tui.editor.deleteToLineEnd"), ["alt+k"]);
	assert.deepEqual(keys.getKeys("tui.select.cancel"), ["escape", "ctrl+c"]);
	assert.deepEqual(keys.getKeys("tui.input.copy"), ["ctrl+c"]);
	assert.equal(JSON.parse(readFileSync(join(agentDir, "settings.json"), "utf8")).doubleEscapeAction, "none");
});

test("모델 이전/다음 단축키는 모두 해제되고 Ctrl+P/N은 목록 이동에만 할당", () => {
	const { editor, keys, events } = setup();
	editor.onAction("app.model.cycleForward", () => events.push("next-model"));
	editor.onAction("app.model.cycleBackward", () => events.push("previous-model"));
	editor.handleInput("\x10");
	editor.handleInput("\x1b[112;6u");
	assert.deepEqual(events, []);
	assert.deepEqual(keys.getKeys("app.model.cycleForward"), []);
	assert.deepEqual(keys.getKeys("app.model.cycleBackward"), []);
	for (const [key, expected] of [["ctrl+p", "tui.select.up"], ["ctrl+n", "tui.select.down"]]) {
		const owners = Object.entries(keys.getResolvedBindings())
			.filter(([, bindings]) => (Array.isArray(bindings) ? bindings : [bindings]).includes(key))
			.map(([action]) => action);
		assert.deepEqual(owners, [expected]);
	}
});

test("실제 선택 목록에서 Ctrl+P/N 위아래 이동 및 방향키 유지", () => {
	setup();
	const items = ["first", "second", "third"].map(value => ({ value, label: value }));
	const list = new SelectList(items, 5, {});
	list.setSelectedIndex(1);
	for (const [input, expected] of [["\x10", "first"], ["\x0e", "second"], ["\x1b[B", "third"], ["\x1b[A", "second"]]) {
		list.handleInput(input);
		assert.equal(list.getSelectedItem().value, expected);
	}
});

test("자동완성 목록에서도 Ctrl+P/N으로 선택하고 모델은 변경하지 않음", async () => {
	for (const [input, expected] of [["\x0e", "/settings"], ["\x10", "/settings"]]) {
		const { editor, events } = setup();
		editor.onAction("app.model.cycleForward", () => events.push("next-model"));
		editor.setAutocompleteProvider({
			getSuggestions: async () => ({ prefix: "/s", items: [
				{ value: "/session", label: "session" }, { value: "/settings", label: "settings" },
			] }),
			applyCompletion: (_lines, _line, _col, item) => ({ lines: [item.value], cursorLine: 0, cursorCol: item.value.length }),
		});
		editor.setText("/s");
		editor.handleInput("\t");
		await setImmediate();
		editor.handleInput(input);
		editor.handleInput("\t");
		assert.equal(editor.getText(), expected);
		assert.deepEqual(events, []);
	}
});

test("세션 목록에서도 Ctrl+P/N은 경로/필터 토글 대신 선택 이동", async () => {
	const { keys } = setup();
	const sessions = ["first", "second", "third"].map((id, index) => ({
		id, path: `/tmp/pi-keyboard-fixture-${id}.jsonl`, cwd: agentDir,
		created: new Date(0), modified: new Date(3000 - index * 1000),
		messageCount: 1, firstMessage: id, allMessagesText: id, name: id,
	}));
	const selector = new SessionSelectorComponent(async () => sessions, async () => sessions,
		() => {}, () => {}, () => {}, () => {}, { keybindings: keys });
	await setImmediate();
	const list = selector.getSessionList();
	assert.equal(list.getSelectedSessionPath(), sessions[0].path);
	selector.handleInput("\x0e");
	assert.equal(list.getSelectedSessionPath(), sessions[1].path);
	selector.handleInput("\x10");
	assert.equal(list.getSelectedSessionPath(), sessions[0].path);
	assert.equal(keys.matches("\x1bp", "app.session.togglePath"), true);
	assert.equal(keys.matches("\x1bn", "app.session.toggleNamedFilter"), true);
	assert.equal(keys.matches("\x1bo", "app.models.toggleProvider"), true);
});

test("Ctrl+G는 입력만 지우고 반복해도 종료하지 않으며 Undo 가능", () => {
	const { editor, events } = setup();
	editor.setText("첫 줄\n둘째 줄");
	editor.handleInput("\x07");
	editor.handleInput("\x07");
	assert.equal(editor.getText(), "");
	assert.deepEqual(events, []);
	editor.handleInput("\x1f"); // Ctrl+- / Ctrl+_의 legacy 입력
	assert.equal(editor.getText(), "첫 줄\n둘째 줄");
});

test("Esc를 반복해도 입력을 지우거나 중단/종료하지 않음", () => {
	const { editor, events } = setup();
	editor.setText("첫 줄\n둘째 줄");
	editor.handleInput("\x1b");
	editor.handleInput("\x1b");
	assert.equal(editor.getText(), "첫 줄\n둘째 줄");
	assert.deepEqual(events, []);
});

test("Esc는 자동완성만 닫으며 이후 Esc도 입력 보존", async () => {
	const { editor, events } = setup();
	await openAutocomplete(editor);
	editor.handleInput("\x1b");
	assert.equal(editor.isShowingAutocomplete(), false);
	assert.equal(editor.getText(), "/s");
	editor.handleInput("\x1b");
	assert.equal(editor.getText(), "/s");
	assert.deepEqual(events, []);
});

test("자동완성이 열려 있어도 Ctrl+G는 입력 전체 지우기", async () => {
	const { editor, events } = setup();
	await openAutocomplete(editor);
	editor.handleInput("\x07");
	assert.equal(editor.isShowingAutocomplete(), false);
	assert.equal(editor.getText(), "");
	assert.deepEqual(events, []);
});

test("Ctrl+C 한 번은 입력 보존 및 Pi 중단 핸들러 호출", () => {
	const { editor, events } = setup();
	editor.setText("아직 보내지 않은 입력");
	editor.handleInput("\x03");
	assert.deepEqual(events, ["interrupt"]);
	assert.equal(editor.getText(), "아직 보내지 않은 입력");
});

test("자동완성이 열려도 Ctrl+C 한 번으로 닫기와 작업 중단 모두 실행", async () => {
	const { editor, events } = setup();
	await openAutocomplete(editor);
	editor.handleInput("\x03");
	assert.equal(editor.isShowingAutocomplete(), false);
	assert.equal(editor.getText(), "/s");
	assert.deepEqual(events, ["interrupt"]);
});

test("499ms 안의 Ctrl+C 두 번으로 정상 종료, 추가 입력에서 중복 종료 없음", () => {
	const { editor, events, at } = setup();
	editor.setText("남아 있는 입력");
	editor.handleInput("\x03");
	at(1499);
	editor.handleInput("\x03");
	editor.handleInput("\x03");
	assert.deepEqual(events, ["interrupt", "exit"]);
});

test("500ms 경계에서는 종료하지 않고 새 연속 누름 시작", () => {
	const { editor, events, at } = setup();
	editor.handleInput("\x03");
	at(1500);
	editor.handleInput("\x03");
	assert.deepEqual(events, ["interrupt", "interrupt"]);
	at(1999);
	editor.handleInput("\x03");
	assert.deepEqual(events, ["interrupt", "interrupt", "exit"]);
});

test("중간의 문자/다른 단축키는 연속 Ctrl+C 판정 초기화", () => {
	for (const middle of ["a", "\x1b", "\x0b", "\x07"]) {
		const { editor, events, at } = setup();
		editor.handleInput("\x03");
		at(1100);
		editor.handleInput(middle);
		at(1200);
		editor.handleInput("\x03");
		assert.equal(events.includes("exit"), false, JSON.stringify(middle));
		assert.equal(events.filter(event => event === "interrupt").length, 2);
	}
});

test("Kitty 키 해제/자동 반복은 두 번째 누름으로 세지 않음", (t) => {
	setKittyProtocolActive(true);
	t.after(() => setKittyProtocolActive(false));
	const { editor, events, at } = setup();
	const press = "\x1b[99;5:1u", repeat = "\x1b[99;5:2u", release = "\x1b[99;5:3u";
	assert.equal(isKeyRepeat(repeat), true);
	assert.equal(isKeyRelease(release), true);
	editor.handleInput(press);
	at(1100);
	editor.handleInput(repeat);
	editor.handleInput(release);
	assert.deepEqual(events, ["interrupt"]);
	at(1200);
	editor.handleInput(press);
	assert.deepEqual(events, ["interrupt", "exit"]);
});

test("bracketed paste 안의 Ctrl+C/Ctrl+G/Esc는 단축키가 아님", () => {
	const { editor, events } = setup();
	editor.handleInput("\x03");
	editor.handleInput("\x1b[200~pasted\x03\x03\x07\x1b text\x1b[201~");
	assert.ok(editor.getText().includes("pasted"));
	assert.deepEqual(events, ["interrupt"]);
	editor.handleInput("\x03");
	assert.deepEqual(events, ["interrupt", "interrupt"]);
});

test("Ctrl+K는 외부 편집, Alt+K는 줄 끝 삭제, Ctrl+G는 외부 편집하지 않음", () => {
	const { editor, events } = setup();
	editor.setText("abc def");
	editor.handleInput("\x0b");
	assert.deepEqual(events, ["external"]);
	assert.equal(editor.getText(), "abc def");
	editor.handleInput("\x07");
	assert.deepEqual(events, ["external"]);
	assert.equal(editor.getText(), "");
	editor.setText("abc def");
	editor.handleInput("\x01");
	for (let i = 0; i < 3; i++) editor.handleInput("\x1b[C");
	editor.handleInput("\x1bk");
	assert.equal(editor.getText(), "abc");
});

test("동적 중단 핸들러와 기존 Ctrl+D 및 확장 단축키 유지", () => {
	const { editor, events, at } = setup();
	const native = { onEscape: () => events.push("stream-abort") };
	editor.onEscape = () => native.onEscape();
	editor.handleInput("\x03");
	at(2000);
	native.onEscape = () => events.push("compaction-or-bash-abort");
	editor.handleInput("\x03");
	assert.deepEqual(events, ["stream-abort", "compaction-or-bash-abort"]);
	editor.onExtensionShortcut = (data) => {
		if (data === "\x1bz") { events.push("extension"); return true; }
		return false;
	};
	editor.handleInput("\x1bz");
	editor.setText("ab");
	editor.handleInput("\x01");
	editor.handleInput("\x04");
	assert.equal(editor.getText(), "b");
	editor.handleInput("\x07");
	editor.handleInput("\x04");
	assert.deepEqual(events, ["stream-abort", "compaction-or-bash-abort", "extension", "exit"]);
	assert.equal(editor.embedWorkingStatus, true);
});

test("메뉴/BTW는 입력을 가로채지 않으며 메인 종료 연속 누름 초기화", () => {
	const handlers = new Map();
	let editor, listener, focused, unsubscribed = 0;
	const events = [];
	const keys = new KeybindingsManager(bindings);
	setKeybindings(keys);
	const ctx = {
		mode: "tui", abort: () => events.push("abort"), shutdown: () => events.push("exit"),
		ui: {
			setEditorComponent: (factory) => {
				editor = factory({ requestRender() {}, getFocusedComponent: () => focused }, getEditorTheme(), keys);
				focused = editor;
			},
			onTerminalInput: (handler) => { listener = handler; return () => { unsubscribed++; }; },
		},
	};
	install({ on: (event, handler) => handlers.set(event, handler) });
	handlers.get("session_start")({}, ctx);
	listener("\x03"); editor.handleInput("\x03");
	focused = { handleInput() {} }; // 메뉴 또는 BTW가 입력 소유
	assert.equal(listener("\x03"), undefined);
	assert.equal(listener("\x1b"), undefined);
	focused = editor;
	listener("\x03"); editor.handleInput("\x03");
	assert.deepEqual(events, ["abort", "abort"]);
	handlers.get("session_shutdown")();
	assert.equal(unsubscribed, 1);
});

test("비대화형 모드에서는 UI 및 전역 입력 후크를 설치하지 않음", () => {
	for (const mode of ["rpc", "json", "print"]) {
		const handlers = new Map();
		install({ on: (event, handler) => handlers.set(event, handler) });
		handlers.get("session_start")({}, { mode, ui: {} });
		handlers.get("session_shutdown")();
	}
});

test("pi 실제 확장 로더에서 오류 없이 등록", async () => {
	const { loadExtensions } = await import(join(host, "dist/core/extensions/loader.js"));
	const result = await loadExtensions([join(here, "index.ts")], agentDir);
	assert.deepEqual(result.errors, []);
	assert.equal(result.extensions.length, 1);
});
