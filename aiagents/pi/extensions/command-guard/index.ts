import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { runHook } from "./runner.ts";

const scriptPath = fileURLToPath(new URL("./dangerous_command_check.sh", import.meta.url));

export default function commandGuard(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return;
		const command = event.input?.command;
		if (typeof command !== "string") {
			return { block: true, reason: "PreToolUse: invalid bash command; command not executed" };
		}
		return runHook({ command, cwd: ctx.cwd, scriptPath, signal: ctx.signal });
	});
}
