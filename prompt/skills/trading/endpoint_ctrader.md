# cTrader Flask Endpoints

`src/endpoint_ctrader.py` 가 노출하는 외부 HTTP 엔드포인트.
기본 도메인: `https://stock.iasdf.com/ctrader/*`

내부적으로 일부 엔드포인트는 `account_script/ctrader.py` worker (`http://127.0.0.1:8855`) 를 호출. worker 자체의 protobuf 엔드포인트 명세는 [`../account_script/endpoint.md`](../account_script/endpoint.md) 참조.

---

## 엔드포인트 한눈에

| Method | Path | 역할 |
|--------|------|------|
| GET    | `/ctrader/test` | Blueprint ping |
| GET    | `/ctrader/api/connect` | OAuth 시작 (cTrader 인증 페이지로 302) |
| GET    | `/ctrader/api/callback` | OAuth callback (token 교환 + DB 저장 + worker auto sync) |
| GET    | `/ctrader/health` | worker `/health` 프록시 |
| POST   | `/ctrader/sync_token?token_id=N` | worker `/sync_token` 프록시 |
| POST   | `/ctrader/sync_accounts?token_id=N` | worker `/sync_accounts` 프록시 |
| GET    | `/ctrader/accounts?token_id=N` | worker `/accounts` 프록시 |
| PUT    | `/ctrader/account_alias?account_id=M&alias=...` | worker `/account_alias` 프록시 |
| DELETE | `/ctrader/account_alias?account_id=M` | worker `/account_alias` 프록시 |
| GET    | `/ctrader/trader?alias=acaliastest` | worker `/trader` 프록시 |
| GET    | `/ctrader/positions?alias=acaliastest` | worker `/positions` 프록시 |
| GET    | `/ctrader/positionscsv?alias=acaliastest` | worker `/positionscsv` 프록시 (CSV 응답) |
| GET    | `/ctrader/deals?alias=acaliastest&date=today` | worker `/deals` 프록시 |
| GET    | `/ctrader/position_list?alias=acaliastest&date=today` | worker `/position_list` 프록시 |
| GET    | `/ctrader/position_detail?alias=acaliastest&position_id=P` | worker `/position_detail` 프록시 |

OAuth 인증만 `/api/` prefix, 나머지 worker 프록시는 평면 `/ctrader/*`.

> ⚠️ 현재 별도 인증 없음. 외부 노출되면 누구나 토큰/잔액 조회 가능.
> 운영 시 nginx basic auth / API key 헤더 / OAuth 사용자 매칭 필수.

---

## 1. `GET /ctrader/test`

Blueprint 동작 확인용 ping.

- **응답**: `200 OK`, `Content-Type: text/plain`, body `test`

---

## 2. `GET /ctrader/api/connect`

cTrader Open API OAuth 2.0 시작점. 사용자를 cTrader 인증 페이지로 302 redirect.

### 동작

1. `config.json` 의 `ctrader.client_id`, `redirect_uri`, `scope` 로드
2. `https://openapi.ctrader.com/apps/auth?client_id=...&redirect_uri=...&scope=...` 로 302 redirect

> ⚠️ cTrader OAuth 는 표준 `state` 파라미터를 지원 안 함. CSRF 방어는 code 자체의 1분 유효 + 일회성 특성에 의존.

### 응답

- **성공**: `302 Found` → cTrader 인증 페이지
- **실패**: `500` — `config.json` 의 `ctrader` 섹션 누락 / `client_id` 비어 있음
  ```json
  { "status": "error", "message": "config.json 의 ctrader.client_id 가 비어 있음" }
  ```

---

## 3. `GET /ctrader/api/callback`

cTrader OAuth redirect 콜백. cTrader 인증 페이지에서 승인 시 자동 호출.

### 요청

| 구분 | 이름 | 설명 |
|------|------|------|
| 성공 시 | `code` | 1분 유효 일회성 authorization code |
| 실패 시 | `error` | cTrader 에러 코드 (`access_denied` 등) |
| 실패 시 | `error_description` | 사람용 설명 |

### 동작

1. `code` 검증 (없으면 400)
2. `https://openapi.ctrader.com/apps/token` POST → access/refresh token 교환
3. `ctrader_oauth_tokens` INSERT (`ctrader_user_id` 는 NULL)
4. **worker `POST /sync_token` 자동 호출** → `ctrader_user_id` 채움 (silent fail)
5. **worker `POST /sync_accounts` 자동 호출** → `ctrader_account_alias` 캐시 채움 (silent fail)

### 응답

#### 성공 (200)

```json
{
  "status":          "ok",
  "token_id":        "integer",
  "ctrader_user_id": "integer | null",
  "accounts_synced": "integer | null",
  "expires_in":      "integer (~30일 / 2628000s)"
}
```

- `ctrader_user_id`, `accounts_synced` 가 `null` 이면 worker 호출 실패 (worker 다운 등). DB 에 token 자체는 저장됨 → 사용자가 worker 띄운 후 `/ctrader/sync_token`, `/ctrader/sync_accounts` 수동 호출하면 복구됨.

#### 실패

| 코드 | 케이스 |
|-----|-------|
| `400` | `code` 누락 / cTrader 가 `error=` 로 응답 |
| `500` | `config.json` 누락 / DB 저장 실패 |
| `502` | cTrader `/apps/token` HTTP/네트워크 실패 또는 응답 형식 오류 |

```json
{ "status": "error", "error": "access_denied", "error_description": "..." }
{ "status": "error", "message": "missing 'code' query parameter" }
{ "status": "error", "message": "cTrader token endpoint HTTP 401", "body": "..." }
```

---

## 4. `* /ctrader/*` (worker proxy)

OAuth 인증 (`/api/connect`, `/api/callback`) 외 나머지 cTrader 관련 엔드포인트는 모두 worker 로의 단순 프록시.

### 동작

1. Flask 가 받은 `request.args` (query string) 그대로 worker URL 로 forwarding
2. worker 응답 (status code + body + Content-Type) 그대로 클라이언트에 반환
3. worker 가 4xx/5xx 응답해도 그대로 통과 (예: alias not found = 404)
4. worker 호출 자체 실패 (네트워크, worker 미기동) → `502 Bad Gateway`

### 프록시 경로 매핑

| Public path | 내부 worker path |
|-------------|------------------|
| `GET /ctrader/health` | `GET /health` |
| `POST /ctrader/sync_token` | `POST /sync_token` |
| `POST /ctrader/sync_accounts` | `POST /sync_accounts` |
| `GET /ctrader/accounts` | `GET /accounts` |
| `PUT/DELETE /ctrader/account_alias` | `PUT/DELETE /account_alias` |
| `GET /ctrader/trader` | `GET /trader` |
| `GET /ctrader/positions` | `GET /positions` |
| `GET /ctrader/positionscsv` | `GET /positionscsv` (Content-Type: text/csv) |
| `GET /ctrader/deals` | `GET /deals` |
| `GET /ctrader/position_list` | `GET /position_list` |
| `GET /ctrader/position_detail` | `GET /position_detail` |

각 엔드포인트의 query 파라미터 / 응답 schema 는 [`../account_script/endpoint.md`](../account_script/endpoint.md) 의 동일 path 섹션 참조.

### 식별자

worker proxy 엔드포인트들은 거의 모두 다음 식별자 중 하나로 호출:

| 모드 | 파라미터 | 비고 |
|------|---------|------|
| **alias 모드 (권장)** | `?alias=acaliastest` | `ctrader_account_alias.alias` |
| 직접 ID | `?token_id=N&account_id=M` | DB 캐시 row 가 있어야 함 |

### 시간 범위 파라미터 (`/deals`, `/position_list`, `/position_detail` 만)

| 파라미터 | 설명 |
|---------|------|
| `date` | `YYYY-MM-DD` / `today` / `yesterday` (KST 기준). 기본 today |
| `cme` | `0` (default): KST 자정 ~ 자정 / `1`: KST 07:00 ~ 다음날 06:59:59 (CME 세션) |
| `days` | 최근 N일 |
| `from`, `to` | Unix milliseconds |

우선순위: `from`+`to` > `days` > date 모드 (default).

`yesterday` 가 토/일이면 직전 금요일로 자동 백트랙 (시장 휴장 처리).

### 502 응답 (worker 미기동/네트워크 장애 시)

```json
{ "status": "error", "message": "worker 호출 실패: ..." }
```

---

## 4-1. `GET /ctrader/positionscsv` (CSV 응답)

`/ctrader/positions` 와 동일한 식별자 (`alias` 또는 `token_id+account_id`) 를 받아 현재 보유 포지션 + 대기 주문을 **CSV** 로 반환. 두 섹션 (positions / orders) 을 빈 줄로 구분.

- **Content-Type**: `text/csv; charset=utf-8`

### Body 포맷 (성공)

```
positions,<count>
positionId,symbolName,tradeSide,volume,volumeLots,openPrice,stopLoss,takeProfit,swap,commission,usedMargin,openTimestampKst,utcLastUpdateTimestampKst
<row1>
<row2>
...

orders,<count>
orderId,symbolName,tradeSide,volume,volumeLots,orderType,orderStatus,limitPrice,stopPrice,stopLoss,takeProfit,expirationTimestampKst
<row1>
<row2>
...
```

### 예시

```bash
curl 'https://stock.iasdf.com/ctrader/positionscsv?alias=acaliastest' > positions.csv
```

```
positions,1
positionId,symbolName,tradeSide,volume,volumeLots,openPrice,stopLoss,takeProfit,swap,commission,usedMargin,openTimestampKst,utcLastUpdateTimestampKst
101095461,US100,LONG,3,0.03,27389.71666666667,0.0,0.0,0.0,0.0,4.11,2026-04-27 12:51:42,2026-04-27 14:13:42

orders,2
orderId,symbolName,tradeSide,volume,volumeLots,orderType,orderStatus,limitPrice,stopPrice,stopLoss,takeProfit,expirationTimestampKst
45431683,US100,LONG,10,0.1,2,1,27265.23,0.0,0.0,0.0,
45431679,US100,LONG,10,0.1,2,1,27295.05,0.0,0.0,0.0,
```

### 실패

식별자 누락 / 계좌 not found / worker 호출 실패 시엔 일반 worker 프록시와 동일하게 **JSON 응답** (text/csv 가 아님).

---

## 사용 흐름 요약 (외부 사용자 관점)

```
[1] 브라우저: https://stock.iasdf.com/ctrader/api/connect
       → cTrader 인증 페이지로 redirect
[2] cTrader 인증 페이지에서 "액세스 허용"
       → /ctrader/api/callback 자동 호출
       → token 자동 저장 + worker /sync_token + /sync_accounts 자동 실행
       → 응답에 token_id / ctrader_user_id / accounts_synced
[3] curl 'https://stock.iasdf.com/ctrader/accounts?token_id=1'
       → 계좌 리스트 확인 (alias 모두 null)
[4] curl -X PUT 'https://stock.iasdf.com/ctrader/account_alias?account_id=M&alias=acaliastest'
       → 원하는 계좌에 별칭 부여
[5] curl 'https://stock.iasdf.com/ctrader/trader?alias=acaliastest'
       → 잔액/equity
[6] curl 'https://stock.iasdf.com/ctrader/positions?alias=acaliastest'
       → 현재 오픈 포지션
[7] curl 'https://stock.iasdf.com/ctrader/deals?alias=acaliastest&date=today'
       → 그날 raw 거래 체결 내역
[8] curl 'https://stock.iasdf.com/ctrader/position_list?alias=acaliastest&date=today'
       → 그날 거래를 positionId 로 그룹화 + 요약
[9] curl 'https://stock.iasdf.com/ctrader/position_detail?alias=acaliastest&position_id=P'
       → 특정 position 의 진입~청산 lifecycle 전체
```

---

## 설정 (config.json)

`conf/config.json` 의 `ctrader` 섹션 필요:

```json
"ctrader": {
    "client_id":     "...",
    "client_secret": "...",
    "redirect_uri":  "https://stock.iasdf.com/ctrader/api/callback",
    "scope":         "trading"
}
```

worker 호출 URL 은 `endpoint_ctrader.py` 상단 상수:

```python
CTRADER_WORKER_URL = "http://127.0.0.1:8855"
CTRADER_WORKER_TIMEOUT = 10
```

worker 가 다른 호스트/포트면 직접 수정.
