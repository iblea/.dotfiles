import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmdirSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const agentDir = resolve(
	process.env.PI_CODING_AGENT_DIR?.replace(/^~(?=\/|$)/, homedir()) || join(homedir(), ".pi", "agent"),
);
const install = join(agentDir, "install");
const version = readFileSync(join(install, "current-version"), "utf8").trim();
const runtime = pathToFileURL(join(install, "releases", version,
	"node_modules/@earendil-works/pi-coding-agent/dist/extensions/mcp/runtime.js")).href;
const configPath = resolve(here, "../mcp.json");

// 실제 MCP 전송 경로로 환경 상속 확인. 서버·인증 파일·네트워크 대신 격리된 Node 프로세스 사용
const probe = `
import { readFileSync } from "node:fs";
const { createDefaultTransport } = await import(process.argv[2]);
const config = JSON.parse(readFileSync(process.argv[1], "utf8")).mcpServers.Context7;
const transport = createDefaultTransport({ name: "Context7", config: {
	...config,
	command: process.execPath,
	args: ["-e", 'console.log(JSON.stringify({ jsonrpc: "2.0", id: 1, result: process.env.CONTEXT7_API_KEY ?? null })); process.stdin.resume();'],
} }, process.cwd());
const result = new Promise((resolve, reject) => {
	transport.onMessage((message) => resolve(message.result));
	transport.onError(reject);
	transport.onClose(() => reject(new Error("probe closed without a result")));
});
try {
	await transport.start();
	console.log(JSON.stringify(await result));
} finally {
	await transport.close();
}
`;

for (const value of ["context7-test-key", undefined, ""]) {
	test(`Context7 환경 키 ${value === undefined ? "미설정" : value === "" ? "빈 값" : "설정"}: 추출 명령 없이 상속`, () => {
		const home = mkdtempSync(join(tmpdir(), "pi-context7-test-"));
		try {
			// 실제 사용자 환경 및 Codex 인증 파일에 접근하지 않도록 HOME과 환경 격리
			const env = { HOME: home, PATH: process.env.PATH ?? "" };
			if (value !== undefined) env.CONTEXT7_API_KEY = value;
			const result = spawnSync(process.execPath, ["--input-type=module", "-e", probe, configPath, runtime], {
				cwd: home, env, encoding: "utf8", timeout: 15_000,
			});
			assert.equal(result.status, 0, result.stderr);
			assert.equal(JSON.parse(result.stdout), value ?? null);
		} finally {
			rmdirSync(home);
		}
	});
}
