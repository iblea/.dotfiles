import {
	CustomEditor,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import { Editor, isKeyRelease, isKeyRepeat, matchesKey, type EditorTheme, type TUI } from "@earendil-works/pi-tui";

const DOUBLE_CTRL_C_MS = 500;

/** 메인 입력창 전용: Ctrl+G 지우기, Ctrl+C 중단/두 번 종료. Esc는 기본 취소 유지 */
export class ShortcutEditor extends CustomEditor {
	private lastCtrlCAt: number | undefined;
	private exiting = false;

	constructor(
		tui: TUI,
		theme: EditorTheme,
		keys: KeybindingsManager,
		private readonly controls: Pick<ExtensionContext, "abort" | "shutdown">,
		private readonly now: () => number = () => performance.now(),
	) {
		super(tui, theme, keys, { embedWorkingStatus: true });
	}

	observeInput(data: string, editorFocused: boolean): void {
		if (isKeyRelease(data)) return;
		if (!editorFocused || !matchesKey(data, "ctrl+c")) this.lastCtrlCAt = undefined;
	}

	handleInput(data: string): void {
		if (this.exiting || isKeyRelease(data)) return;

		// Pi terminal은 bracketed paste를 완성된 패킷으로 전달. 내용 속 제어문자는 단축키로 처리하지 않음
		if (data.includes("\x1b[200~")) {
			this.lastCtrlCAt = undefined;
			Editor.prototype.handleInput.call(this, data);
			return;
		}

		if (matchesKey(data, "ctrl+c")) {
			// Kitty 키 반복 이벤트로 의도치 않게 종료되는 상황 방지
			if (isKeyRepeat(data)) return;
			const now = this.now();
			if (this.lastCtrlCAt !== undefined && now - this.lastCtrlCAt < DOUBLE_CTRL_C_MS) {
				this.lastCtrlCAt = undefined;
				this.exiting = true;
				// Pi가 연결한 정상 종료 경로 사용. 입력이 남아 있어도 두 번째 Ctrl+C로 종료
				if (this.onCtrlD) this.onCtrlD();
				else this.controls.shutdown();
				return;
			}
			this.lastCtrlCAt = now;
			// Ctrl+C의 copy 바인딩을 우회해 자동완성만 닫은 뒤, 같은 키 입력에서 작업 중단
			if (this.isShowingAutocomplete()) Editor.prototype.handleInput.call(this, "\x1b");
			// 동적 Pi 핸들러 유지: 스트리밍, !bash, 재시도, 압축 취소 및 대기 메시지 복원
			if (this.onEscape) this.onEscape();
			else this.controls.abort();
			return;
		}

		this.lastCtrlCAt = undefined;
		if (matchesKey(data, "ctrl+g")) {
			if (isKeyRepeat(data)) return;
			this.setText(""); // 기본 app.clear의 '두 번 종료'는 호출하지 않음. Undo 가능
			return;
		}

		// Ctrl+K 외부 편집기를 포함한 나머지 Pi/확장 단축키는 그대로 전달
		super.handleInput(data);
	}
}

export default function keyboardControls(pi: ExtensionAPI) {
	let cleanup = () => {};
	pi.on("session_start", (_event, ctx) => {
		cleanup();
		if (ctx.mode !== "tui") return;

		let editor: ShortcutEditor;
		let host: TUI;
		ctx.ui.setEditorComponent((tui, theme, keys) => {
			host = tui;
			editor = new ShortcutEditor(tui, theme, keys, ctx);
			return editor;
		});
		const unsubscribe = ctx.ui.onTerminalInput((data) => {
			// 메뉴·/btw·오버레이 입력은 가로채지 않고, 메인 입력창의 연속 누름만 초기화
			editor.observeInput(data, host.getFocusedComponent() === editor);
			return undefined;
		});
		cleanup = () => {
			unsubscribe();
			editor.observeInput("", false);
		};
	});
	pi.on("session_shutdown", () => cleanup());
}
