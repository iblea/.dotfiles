# Pi Sites

pi의 ChatGPT OAuth로 Sites API와 Git 저장소에 직접 연결하는 로컬 확장이야. Codex CLI나 추가 모델 호출은 사용하지 않아.

## 설치 및 시작

현재 위치인 `~/.pi/agent/extensions/sites/index.ts`는 pi가 자동 발견해. 실행 중인 세션에서는 **`/reload`** 또는 새 pi 세션으로 불러와. `settings.json`에 중복으로 추가할 필요는 없어.

- 검증 기준: pi `0.87.1`, Node `22.21.1`
- `/login openai-codex`로 연결된 ChatGPT OAuth 필요
- 현재 선택한 대화 모델은 OpenAI일 필요가 없어
- Sites 접근 권한·이용약관·워크스페이스 정책은 서버에서 검사해

## 명령

```text
/sites doctor
/sites list {"limit":10}
/sites get {"project_id":"서버에서 받은 정확한 ID"}
/sites create {"path":"/absolute/site","title":"테스트 보고서","slug":"my-report-test"}
/sites publish {"path":"/absolute/site","wait_seconds":30}
/sites publish {"path":"/absolute/site","save_only":true}
/sites status {"path":"/absolute/site","wait_seconds":60}
```

모델에는 `sites_doctor`, `sites_list`, `sites_get`, `sites_create`, `sites_publish`, `sites_status`가 등록돼. 명령 뒤 인자는 JSON 객체야.

### 새 사이트

1. 다른 작업과 분리된 사이트 디렉터리에 소스와 Git 저장소를 준비해.
2. `sites_create`로 비공개 Site를 등록해. 정확한 `project_id`를 `.openai/hosting.json`에 병합하고, 다른 필드는 보존해.
3. `.openai/hosting.json`을 포함한 게시 대상 파일만 검토·커밋해.
4. `sites_publish`로 업로드·버전 저장·비공개 배포를 진행해.
5. 아직 배포 중이면 `sites_status`로 확인해. 성공한 서버 응답의 URL만 완료 결과로 제공해.

확장은 Git 저장소 생성, 의존성 설치, 자동 커밋을 하지 않아. `package.json`에 build 스크립트가 있으면 `npm run build`를 실행해. 다른 패키지 매니저나 검사가 필요하면 `check_command`에 실행 파일과 인자 배열을 넣어:

```text
/sites publish {"path":"/absolute/site","check_command":["pnpm","run","build"]}
```

## 쓰기 승인

등록·게시 도구와 명령은 대화형 승인창을 표시해. 명시적인 생성·게시 요청에만 사용해야 하고, 조사나 HTML 작성만 요청받았을 때 호출하면 안 돼.

대화형 승인이 없는 모드에서는 기본적으로 쓰기가 차단돼. 자동화 운영자가 의도적으로 `PI_SITES_ALLOW_WRITE=1` 환경으로 pi를 실행한 경우에만 쓰기가 허용돼. 모델이 이 설정을 대신 켜면 안 돼. 조회에는 이 설정이 필요 없어.

기존 사이트도 현재 계정의 소유자 전용 상태가 확인된 경우에만 게시해. 공유·공개 배포나 접근 범위 변경은 지원하지 않아.

OAuth의 `chatgpt_account_user_id`와 Sites 접근 목록의 `account_user_id`는 서로 다른 식별자 체계일 수 있어. OAuth ID를 Sites ID라고 단정하지 않아. 실제 소유자 역할, 비어 있지 않은 단일 접근 대상 ID, 그룹·외부 방문자 부재, 검증된 OAuth 이메일의 일치를 함께 확인해. 별도로 확인된 Sites ID가 있다면 그 ID의 충돌을 이메일로 무시하지 않아.

## 현재 범위와 제한

- 지원: 목록·상태 조회, 신규 등록, 소스 Git push, 원격 빌드용 버전 저장, 비공개 배포, 중단된 저장·배포 요청의 읽기 전용 상태 대조
- 소스는 clean Git HEAD와 커밋된 hosting.json이 필요해
- 서버에서 발급한 단기 토큰과 정확한 저장소·브랜치만 사용해
- `auth_mode=http_extra_header`만 지원하고 모르는 인증 방식으로 우회하지 않아
- v0.1은 검증된 **명시적 저장·배포 + 원격 빌드 경로**만 제공해
- 로컬 아카이브 업로드, 자동 publish-on-push, 공개 전환, 환경변수·도메인 수정, 삭제, 토큰 회전은 미지원
- 프론트엔드 파일 생성·프레임워크 변환·HTML 디자인은 pi의 일반 코딩 도구가 맡아
- API는 안정된 공개 API 계약이 아니야. 최신 live schema와 맞지 않으면 실패하고 자동으로 다른 작업을 시도하지 않아
- 초기 안전 정책상 `git.chatgpt-team.site`의 HTTPS Git 목적지만 지원해
- 비밀정보 파일명·패턴 검사는 보조 수단이며 완전한 비밀정보 탐지 보장은 아니야

## 상태·오류 복구

게시 영수증과 프로세스 잠금은 `<pi agent dir>/sites/state/`에 저장돼. 저장소 밖이므로 Site 소스에 포함되지 않아. 영수증에는 계정/프로젝트/커밋/버전/배포 식별자만 남기고 인증 토큰은 남기지 않아. 세션 분기는 외부 배포를 되돌리지 않아.

- push 중단: 재호출 시 원격 HEAD를 먼저 확인해. 이미 같은 커밋이면 중복 push하지 않아.
- 버전 저장·배포 중단: `sites_status`로 서버 상태를 먼저 대조해. 결과가 불명확하면 요청을 재전송하지 않아.
- Site 생성 응답 유실: 새 Site를 자동 생성하지 않아. `sites_list`로 정확한 ID를 찾아 hosting.json을 연결해야 해.
- `save_only`로 저장을 마친 버전은 이후 같은 커밋을 배포하거나 새 커밋을 새 버전으로 저장할 수 있어. 배포 도중 멈춘 상태와는 구분해.
- 동일 커밋의 빌드 실패: 원인을 수정한 새 커밋으로 게시해.
- 프로세스 강제 종료 후 잠금이 남으면 오류에 나온 잠금 파일의 PID가 종료됐는지 확인한 뒤 **그 파일만** 제거해. 잠금을 자동 탈취하지 않아.

오류 응답·도구 details·세션 기록에 OAuth, Git 쓰기 토큰, 사이트 API 토큰을 반환하지 않아. 기존 인증정보 파일을 직접 읽거나 갱신하는 별도 로직도 없어. pi의 `getProviderAuth` 갱신 경로를 사용해.

## 개발

```sh
cd ~/.pi/agent/extensions/sites
npm test
```

테스트는 가짜 HTTP 응답과 임시 로컬 저장소를 사용해. 실계정 Site 생성·push·배포는 자동 테스트에 포함하지 않아. 설치 검증에서는 별도로 pi SDK의 실제 자동 발견·로더와 읽기 전용 실연결을 확인해.

유지보수 시 개발 의존성을 설치한 환경에서는 `npm run typecheck`로 엄격한 타입 검사도 실행할 수 있어. 실행 자체는 pi가 제공하는 peer 패키지와 Node 내장 모듈만 사용해.

이 구현은 독립 작성한 로컬 확장이야. 기존 `@juvio15/pi-sites`나 공식 Sites 번들 코드를 복제해서 배포하지 않아. 외부 배포를 결정할 때 패키지명·라이선스·호환성 범위를 별도로 정해야 해.
