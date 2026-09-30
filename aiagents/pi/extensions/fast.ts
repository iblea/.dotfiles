import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATE_TYPE = "openai-fast-mode";

function supportsPriorityRequest(model: ExtensionContext["model"]): boolean {
	if (!model || !model.id.startsWith("gpt-")) return false;
	return (
		(model.provider === "openai" &&
			(model.api === "openai-responses" || model.api === "openai-completions")) ||
		(model.provider === "openai-codex" && model.api === "openai-codex-responses")
	);
}

export default function fastExtension(pi: ExtensionAPI) {
	let enabled = false;

	const statusText = (ctx: ExtensionContext) => {
		if (!enabled) return "fast: OFF";
		return supportsPriorityRequest(ctx.model) ? "fast: ON (priority 요청)" : "fast: ON (현재 모델 미적용)";
	};

	const updateStatus = (ctx: ExtensionContext) => {
		if (ctx.hasUI) ctx.ui.setStatus(STATE_TYPE, statusText(ctx));
	};

	const restoreState = (ctx: ExtensionContext) => {
		enabled = false;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "custom" || entry.customType !== STATE_TYPE) continue;
			const data = entry.data as { enabled?: unknown } | undefined;
			if (typeof data?.enabled === "boolean") enabled = data.enabled;
		}
		updateStatus(ctx);
	};

	pi.on("session_start", (_event, ctx) => restoreState(ctx));
	pi.on("session_tree", (_event, ctx) => restoreState(ctx));
	pi.on("model_select", (_event, ctx) => updateStatus(ctx));

	pi.on("before_provider_request", (event, ctx) => {
		if (!enabled || !supportsPriorityRequest(ctx.model)) return;
		const payload = event.payload;
		if (!payload || typeof payload !== "object" || Array.isArray(payload)) return;
		// 다른 모델의 중첩 요청 제외, 추론 수준과 나머지 요청 필드 유지
		if (!("model" in payload) || payload.model !== ctx.model?.id) return;
		return { ...payload, service_tier: "priority" };
	});

	pi.registerCommand("fast", {
		description: "OpenAI GPT priority 요청 토글 (추가 비용 가능): /fast [on|off|status]",
		getArgumentCompletions: (prefix) => {
			const matches = ["on", "off", "status"].filter((value) => value.startsWith(prefix));
			return matches.length ? matches.map((value) => ({ value, label: value })) : null;
		},
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase();
			if (action === "status") {
				ctx.ui.notify(statusText(ctx), "info");
				return;
			}
			if (action !== "" && action !== "on" && action !== "off") {
				ctx.ui.notify("사용법: /fast [on|off|status]", "warning");
				return;
			}

			const nextEnabled = action === "" ? !enabled : action === "on";
			if (nextEnabled && !supportsPriorityRequest(ctx.model)) {
				ctx.ui.notify("OpenAI 또는 OpenAI Codex의 GPT 모델에서만 켤 수 있어.", "warning");
				return;
			}

			if (enabled !== nextEnabled) {
				enabled = nextEnabled;
				pi.appendEntry(STATE_TYPE, { enabled });
			}
			updateStatus(ctx);
			ctx.ui.notify(
				enabled
					? "FAST ON: 다음 요청부터 priority를 요청해. 추가 비용/사용량이 발생할 수 있어. 서버가 거부하거나 무시할 수 있고, Pi 비용 표시는 실제 청구와 다를 수 있어."
					: "FAST OFF: priority 추가를 중단하고 기존 요청 설정을 사용해.",
				enabled ? "warning" : "info",
			);
		},
	});
}
