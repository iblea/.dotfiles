# Pi command guard

Codex의 `PreToolUse` Bash 검사기를 Pi의 `tool_call` 이벤트에 연결하는 로컬 확장.

## 동작

- AI가 `bash` 도구를 실행하기 전에 `dangerous_command_check.sh` 실행.
- `{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"…"},"cwd":"…"}`를 stdin으로 전달. 명령 문자열 자체는 검사 중 실행하지 않음.
- 종료 코드 `0`만 허용. `2` 및 다른 오류, 파일 누락, 입력 전달 실패, 취소, 5초 시간 초과, 64 KiB 초과 출력은 모두 차단.
- 시간 초과·취소 시 macOS/Linux에서는 검사기의 프로세스 그룹까지 종료.
- 차단 이유는 Pi의 실패한 도구 결과로 AI에 전달. 확인창으로 우회 허용하지 않음.

검사 스크립트는 `~/.codex/hooks/dangerous_command_check.sh`를 내용 변경 없이 복사한 스냅샷. 원본 변경은 자동 동기화하지 않으며, 실행 시 Codex 폴더에 의존하지 않음. 의존 실행 파일은 `/bin/bash`, `/usr/bin/python3`, `jq` 및 기본 Unix 유틸리티.

## 적용 범위

- 메인 세션: `~/.pi/agent/extensions/command-guard/index.ts` 자동 탐색.
- 네이티브 Pi 서브에이전트: `settings.json`의 `subagents.defaultSubagentOnlyExtensions`로 동일 확장 로드. 기존 `defaultExtensions: []`는 유지하므로 다른 전역 확장을 자식에 추가로 로드하지 않음.
- codemode 등 Pi 도구 파이프라인을 거치는 중첩 `bash` 호출도 검사.
- **제외:** 사용자가 직접 입력하는 `!`/`!!`, `powershell`, 다른 도구나 MCP 서버 내부의 프로세스 실행, 외부 CLI 에이전트. 에이전트/프로젝트별 확장 설정이 기본값을 덮어쓰면 적용되지 않을 수 있음.

기존 스크립트는 재귀 삭제 `rm/grm`, `curl` 파이프, `find -exec` 등을 보수적으로 검사하지만 완전한 셸 분석기나 OS 샌드박스는 아님. 동적 코드, 별칭·함수의 실행 결과, 다른 언어를 통한 동등 작업까지 보장하지 않음. 확장 비활성화 또는 파일 변경을 막는 보안 경계도 아님.

## 적용 및 검증

설정 변경 후 `/reload` 또는 Pi 재시작. 이미 실행 중인 자식은 기존 설정을 유지하므로 새 자식부터 적용.

```bash
node --test ~/.pi/agent/extensions/command-guard/command-guard.test.mjs
```

테스트는 설치된 Pi의 실제 확장 로더/이벤트 러너 및 pi-subagents 설정 해석기를 사용. 위험 명령은 검사 데이터로만 전달하며 실제로 실행하지 않음. 시간 초과/취소 테스트는 임시 검사기 프로세스만 실행.
