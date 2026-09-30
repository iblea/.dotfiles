import { spawn } from "node:child_process";
import { stripVTControlCharacters } from "node:util";

interface HookOptions {
	command: string;
	cwd: string;
	scriptPath: string;
	signal?: AbortSignal;
	timeoutMs?: number;
}

type Blocked = { block: true; reason: string };
const OUTPUT_LIMIT = 64 * 1024;
const blocked = (reason: string): Blocked => ({ block: true, reason: `PreToolUse: ${reason}` });

/** 명령을 실행하지 않고 기존 Codex 검사기의 stdin/종료 코드 규약으로 검사 */
export function runHook({ command, cwd, scriptPath, signal, timeoutMs = 5000 }: HookOptions): Promise<Blocked | undefined> {
	if (signal?.aborted) return Promise.resolve(blocked("hook cancelled; command not executed"));

	return new Promise((resolve) => {
		const grouped = process.platform !== "win32";
		const child = spawn("/bin/bash", [scriptPath], {
			cwd,
			detached: grouped,
			stdio: ["pipe", "pipe", "pipe"],
		});
		let settled = false;
		let outputBytes = 0;
		let stderr = "";
		const timer = setTimeout(() => stop(`hook timed out after ${timeoutMs}ms; command not executed`), timeoutMs);

		function finish(result?: Blocked) {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			signal?.removeEventListener("abort", onAbort);
			resolve(result);
		}

		function stop(reason: string) {
			if (settled) return;
			// 검사기가 만든 jq/python 등 하위 프로세스까지 종료
			try {
				if (grouped && child.pid) process.kill(-child.pid, "SIGKILL");
				else child.kill("SIGKILL");
			} catch {
				// 이미 종료된 프로세스 그룹은 무시하되 원래 명령은 차단
				child.kill("SIGKILL");
			}
			finish(blocked(reason));
		}

		function onAbort() {
			stop("hook cancelled; command not executed");
		}

		function collect(chunk: Buffer, isStderr: boolean) {
			if (settled) return;
			outputBytes += chunk.length;
			if (outputBytes > OUTPUT_LIMIT) {
				stop("hook output exceeded limit; command not executed");
				return;
			}
			if (isStderr) stderr += chunk.toString("utf8");
		}

		child.stdout.on("data", (chunk: Buffer) => collect(chunk, false));
		child.stderr.on("data", (chunk: Buffer) => collect(chunk, true));
		child.on("error", () => stop("could not start hook; command not executed"));
		child.stdin.on("error", () => stop("could not send hook input; command not executed"));
		child.on("close", (code, exitSignal) => {
			if (code === 0 && !exitSignal) {
				finish();
				return;
			}
			const detail = stripVTControlCharacters(stderr).replace(/[\x00-\x08\x0b-\x1f\x7f]/g, "").trim().slice(0, 4000);
			finish(blocked(`hook rejected command (${exitSignal ?? `exit ${code}`})${detail ? `\n${detail}` : ""}`));
		});
		signal?.addEventListener("abort", onAbort, { once: true });
		if (signal?.aborted) {
			onAbort();
			return;
		}
		// 명령 문자열을 argv나 shell -c에 넣지 않고 JSON 데이터로만 전달
		child.stdin.end(`${JSON.stringify({
			hook_event_name: "PreToolUse",
			tool_name: "Bash",
			tool_input: { command },
			cwd,
		})}\n`);
	});
}
