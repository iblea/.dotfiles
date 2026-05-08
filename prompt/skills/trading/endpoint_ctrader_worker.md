# cTrader Worker HTTP API

`ctrader.py` 가 노출하는 HTTP 엔드포인트 명세.
**`http://127.0.0.1:8855` (localhost only, 외부 노출 X)**

`tradingview_alert` Flask 가 내부적으로 호출. 외부 (브라우저/서드파티) 는 `tradingview_alert` 의 `/ctrader/*` 프록시 경로 사용 (해당 프로젝트의 `endpoint.md` 참조).

> 7 ~ 11 번 엔드포인트(및 8b)의 모든 응답(성공/실패)에는 KST 기준 현재 서버 시각이 `servertime_kst` 필드로 포함된다.
> JSON 응답에서는 항상 **최상단 첫 번째 키**로 위치하며, 포맷은 `"yyyy-mm-dd HH:MM:SS (KST +09:00)"` 이다.
> 예: `"2026-05-08 17:31:37 (KST +09:00)"`
> 8b 의 CSV 응답에는 본문 첫 줄에 `servertime_kst,<value>` 단독 라인으로 표시되며, 그 다음 빈 줄 한 칸 뒤에 기존 섹션이 이어진다.

---

## 식별자 정리

| ID | 의미 | DB 컬럼 |
|----|------|---------|
| `token_id` | DB row id | `ctrader_oauth_tokens.id` |
| `ctrader_user_id` (cTID) | cTrader 사용자 단위 | `ctrader_oauth_tokens.ctrader_user_id` |
| `account_id` (ctidTraderAccountId) | cTrader 거래 계좌 단위 | `ctrader_account_alias.account_id` |
| `alias` | 사용자 지정 단축어 (`acaliastest` 등) | `ctrader_account_alias.alias` |

대부분의 조회 엔드포인트는 **`alias`** 또는 (`token_id` + `account_id`) 둘 중 하나로 식별 가능. `alias` 권장.

---

## 1. `GET /health`

worker 자체 + cTrader 연결 상태.

### 응답

```json
{
  "status":                 "ok",
  "ctrader_live_connected": "boolean",
  "ctrader_demo_connected": "boolean | \"disabled\"",
  "pid":                    "integer"
}
```

- `ctrader_demo_connected == \"disabled\"` 는 `worker.json` 의 `ctrader.enable_demo=false` 인 경우.

---

## 2. `POST /sync_token?token_id=N`

DB token row 의 `access_token` 으로 cTID 조회 후 `ctrader_user_id` 컬럼 UPDATE.
`/ctrader/api/callback` 에서 자동 호출됨 — 수동 재시도용.

### 응답

```json
{ "status": "ok", "ctrader_user_id": "integer" }
```

---

## 3. `POST /sync_accounts?token_id=N`

cTrader 계좌 리스트 조회 후 `ctrader_account_alias` 테이블 UPSERT.
**`alias` 컬럼은 보존** (재 sync 해도 별칭 안 사라짐).

### 응답

```json
{ "status": "ok", "synced_count": "integer" }
```

---

## 4. `GET /accounts?token_id=N`

`ctrader_account_alias` 에서 token 의 계좌 리스트 조회 (DB read).
**캐시가 비어있으면 자동으로 `/sync_accounts` 트리거 후 다시 조회** (응답에 `auto_synced: true`).

### 응답

```json
{
  "status":      "ok",
  "count":       "integer",
  "auto_synced": "boolean",
  "accounts": [
    {
      "account_id":     "integer",
      "trader_login":   "integer",
      "is_live":        "boolean",
      "broker_title":   "string",
      "alias":          "string | null",
      "last_synced_at": "ISO-8601 datetime"
    }
  ]
}
```

---

## 5. `PUT /account_alias?account_id=M&alias=acaliastest`

특정 `account_id` 에 별칭 설정/변경. alias 는 시스템 전체에서 unique.

### 응답

- `200 OK` `{"status":"ok","account_id":M,"alias":"acaliastest"}`
- `404 Not Found` `account_id` 가 `ctrader_account_alias` 에 없음 → 먼저 `/sync_accounts`
- `409 Conflict` 같은 alias 가 이미 다른 account 에 사용 중

---

## 6. `DELETE /account_alias?account_id=M`

별칭 해제 (alias = NULL).

### 응답

```json
{ "status": "ok", "account_id": M, "alias": null }
```

---

## 7. `GET /trader`

특정 계좌의 잔액/레버리지/equity 등.

### 요청

| 모드 | 파라미터 |
|------|---------|
| alias 모드 (권장) | `?alias=acaliastest` |
| 직접 ID | `?token_id=N&account_id=M` |

### 응답

```json
{
  "servertime_kst": "yyyy-mm-dd HH:MM:SS (KST +09:00)",
  "status": "ok",
  "trader": {
    "ctidTraderAccountId": "integer",
    "traderLogin":         "integer",
    "balance":             "number",
    "balanceRaw":          "integer (minor unit)",
    "moneyDigits":         "integer",
    "leverage":            "number",
    "depositAssetId":      "integer",
    "brokerName":          "string",
    "accessRights":        "integer",
    "equity":              "number | null",
    "unrealizedNetPnL":    "number | null",
    "unrealizedGrossPnL":  "number | null",
    "openPositionCount":   "integer | null"
  }
}
```

- `servertime_kst` 는 KST 기준 현재 서버 시각. 항상 최상단 첫 번째 키.
- `equity = balance + unrealizedNetPnL` (모든 포지션 즉시 청산 시 잔액).
- `unrealized*`, `equity`, `openPositionCount` 가 `null` 이면 PnL API 호출 실패 (best effort).
- 실패(`status=error`) 응답에도 `servertime_kst` 가 첫 키로 포함된다. (`{ "servertime_kst": "...", "status": "error", "message": "..." }`)

---

## 8. `GET /positions?alias=acaliastest`

`ProtoOAReconcileReq` → 현재 보유 포지션 + 대기 주문.
청산된 포지션은 안 줌 (그건 `/deals` 또는 `/position_detail` 사용).

### 응답

```json
{
  "servertime_kst": "yyyy-mm-dd HH:MM:SS (KST +09:00)",
  "status":         "ok",
  "position_count": "integer",
  "order_count":    "integer",
  "positions": [
    {
      "positionId":             "integer",
      "symbolId":               "integer",
      "symbolName":             "string",
      "symbolDescription":      "string",
      "tradeSide":              "LONG | SHORT",
      "tradeSideRaw":           "integer (1=LONG, 2=SHORT)",
      "volume":                 "integer (minor unit)",
      "volumeLots":             "number (volume / 100)",
      "openTimestamp":          "integer (ms)",
      "openTimestampKst":       "string",
      "label":                  "string",
      "openPrice":              "number",
      "stopLoss":               "number",
      "takeProfit":             "number",
      "swap":                   "number",
      "commission":             "number",
      "usedMargin":             "number",
      "moneyDigits":            "integer",
      "utcLastUpdateTimestamp": "integer (ms)",
      "utcLastUpdateTimestampKst": "string"
    }
  ],
  "orders": [
    {
      "orderId":                "integer",
      "symbolName":             "string",
      "tradeSide":              "LONG | SHORT",
      "volumeLots":             "number",
      "orderType":              "integer (1=MARKET, 2=LIMIT, 3=STOP, ...)",
      "orderStatus":            "integer",
      "limitPrice":             "number",
      "stopPrice":              "number",
      "stopLoss":               "number",
      "takeProfit":             "number",
      "expirationTimestamp":    "integer (ms)",
      "expirationTimestampKst": "string"
    }
  ]
}
```

- `servertime_kst` 는 KST 기준 현재 서버 시각. 항상 최상단 첫 번째 키.
- 실패 응답에도 `servertime_kst` 가 첫 키로 포함된다.

---

## 8b. `GET /positions` 의 CSV 변형: `GET /positionscsv`

`/positions` 와 동일한 식별자 (`alias` 또는 `token_id+account_id`) 를 받아 현재 보유 포지션 + 대기 주문을 **CSV** 로 반환. positions / orders 두 섹션을 빈 줄로 구분.

- **Content-Type**: `text/csv; charset=utf-8`

### Body 포맷 (성공)

```
servertime_kst,<yyyy-mm-dd HH:MM:SS (KST +09:00)>

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

- 1행: `servertime_kst,<KST 현재 서버 시각>` 단독 라인 (CSV 본문 최상단)
  - 시각 포맷은 `"yyyy-mm-dd HH:MM:SS (KST +09:00)"` — 공백/괄호는 있지만 콤마(`,`)가 없어 CSV 파싱에 영향 없음.
- 2행: 빈 줄 (servertime 라인과 본문 분리)
- 3행: positions 메타 (`positions,N`)
- 4행: positions 컬럼 헤더
- 5행 이후: positions 데이터 행
- 빈 줄 1개로 두 섹션 분리
- orders 메타 (`orders,M`) → 컬럼 헤더 → 데이터 행

### 실패

식별자 누락/계좌 not found 시 JSON 응답 (text/csv 가 아님). 동작은 `/positions` 의 에러와 동일하며 `servertime_kst` 가 첫 키로 포함된다.

---

## 9. `GET /deals`

`ProtoOADealListReq` → 시간 범위 안의 raw 거래 체결 내역.

### 시간 범위 파라미터 (택1)

| 파라미터 | 설명 |
|---------|------|
| `date` | `YYYY-MM-DD` 또는 `today` / `yesterday` (KST 기준). 생략 시 today |
| `cme` | `0` (default): KST 00:00~23:59:59 / `1`: KST 07:00~다음날 06:59:59 (CME 세션, 서머타임 무관) |
| `days` | 최근 N일 |
| `from`, `to` | Unix milliseconds |

우선순위: `from`+`to` > `days` > **date 모드 (default)**.

### `yesterday` 의 주말 백트랙

`yesterday` 결과가 토/일이면 직전 금요일로 자동 백트랙 (시장 휴장).
예: 월요일 → yesterday → 금요일.

### 식별자

`?alias=acaliastest` 또는 `?token_id=N&account_id=M`.

### 응답

```json
{
  "servertime_kst": "yyyy-mm-dd HH:MM:SS (KST +09:00)",
  "status":  "ok",
  "from":    "integer (ms)",
  "fromKst": "string",
  "to":      "integer (ms)",
  "toKst":   "string",
  "count":   "integer",
  "hasMore": "boolean",
  "deals": [
    {
      "dealId":             "integer",
      "orderId":            "integer",
      "positionId":         "integer",
      "symbolId":           "integer",
      "symbolName":         "string",
      "symbolDescription":  "string",
      "tradeSide":          "LONG | SHORT",
      "tradeSideRaw":       "integer",
      "volume":             "integer",
      "volumeLots":         "number",
      "filledVolume":       "integer",
      "filledVolumeLots":   "number",
      "executionPrice":     "number",
      "executionTimestamp": "integer (ms)",
      "executionTimestampKst": "string",
      "createTimestamp":    "integer (ms)",
      "createTimestampKst": "string",
      "dealStatus":         "integer",
      "commission":         "number",
      "moneyDigits":        "integer",
      "closePositionDetail": {
        "entryPrice":   "number",
        "profit":       "number",
        "swap":         "number",
        "commission":   "number",
        "balance":      "number (체결 후 잔액)",
        "moneyDigits":  "integer"
      }
    }
  ]
}
```

- `servertime_kst` 는 KST 기준 현재 서버 시각. 항상 최상단 첫 번째 키.
- `closePositionDetail` 은 **청산 deal 에만** 존재. 신규 진입 deal 엔 없음.
- 실패 응답(파라미터 오류 / 계좌 not found 등)에도 `servertime_kst` 가 첫 키로 포함된다.

> ⚠️ cTrader 정책상 한 번 호출의 시간 범위는 보통 **최대 1주일**.

---

## 10. `GET /position_list`

`/deals` 와 동일한 시간 범위 파라미터를 받아 **`positionId` 별로 그룹화 + 요약**.
raw deal 은 응답에 없음 (요약만).

같은 position 의 진입/추가매수/부분청산이 한 row 로 묶여서 매매일지 시각화에 적합.

### 응답

```json
{
  "servertime_kst": "yyyy-mm-dd HH:MM:SS (KST +09:00)",
  "status":         "ok",
  "from": ..., "fromKst": "...",
  "to":   ..., "toKst":   "...",
  "dealCount":      "integer",
  "positionCount":  "integer",
  "hasMore":        "boolean",
  "positions": [
    {
      "positionId":          "integer",
      "symbolId":            "integer",
      "symbolName":          "string",
      "symbolDescription":   "string",
      "tradeSide":           "LONG | SHORT",
      "status":              "OPEN | PARTIAL | CLOSED",
      "entryVolumeLots":     "number",
      "closeVolumeLots":     "number",
      "remainingVolumeLots": "number",
      "avgEntryPrice":       "number | null",
      "avgClosePrice":       "number | null",
      "totalProfit":         "number",
      "totalSwap":           "number",
      "totalCommission":     "number",
      "openedAt":            "integer (ms)",
      "openedAtKst":         "string",
      "closedAt":            "integer | null",
      "closedAtKst":         "string | null",
      "dealCount":           "integer"
    }
  ]
}
```

- `servertime_kst` 는 KST 기준 현재 서버 시각. 항상 최상단 첫 번째 키.
- `status`:
  - `OPEN`: 청산 deal 없음
  - `CLOSED`: `closeVolumeLots >= entryVolumeLots`
  - `PARTIAL`: 일부만 청산
- 시간 범위 밖의 deal 은 그룹에 포함 X. 진입이 어제, 청산이 오늘이면 `position_list?date=today` 결과는 한쪽 side 만 보일 수 있음 → 정확한 lifecycle 은 `/position_detail` 사용.
- 실패 응답에도 `servertime_kst` 가 첫 키로 포함된다.

---

## 11. `GET /position_detail`

`ProtoOADealListByPositionIdReq` → 특정 `positionId` 의 모든 deal lifecycle.
여러 날 걸친 position (오버나잇 등) 정확 추적용.

### 요청

| 구분 | 이름 | 타입 | 설명 |
|------|------|------|------|
| 식별자 (택1) | `alias` | string | 권장 |
| 식별자 (택1) | `token_id` + `account_id` | integer | |
| 필수 | `position_id` | integer | cTrader positionId |
| 시간 (택1) | `days` | integer | 최근 N일 (기본 7) |
| 시간 (택1) | `from`, `to` | integer | Unix milliseconds |

### 응답

```json
{
  "servertime_kst": "yyyy-mm-dd HH:MM:SS (KST +09:00)",
  "status":     "ok",
  "positionId": "integer",
  "from": ..., "fromKst": "...",
  "to":   ..., "toKst":   "...",
  "summary":   { ... /position_list 의 단일 position 객체 ... | null },
  "dealCount": "integer",
  "hasMore":   "boolean",
  "deals":     [ ... raw deal 배열 ... ]
}
```

- `servertime_kst` 는 KST 기준 현재 서버 시각. 항상 최상단 첫 번째 키.
- `dealCount == 0` 이면 `summary: null`, `deals: []`. (이 경우 `hasMore` 키는 응답에 포함되지 않음)
- `summary` schema 는 `/position_list` 와 동일.
- 실패 응답(`missing position_id`, `from < to 여야 함`, 계좌 not found 등)에도 `servertime_kst` 가 첫 키로 포함된다.

---

## 백그라운드 task: 토큰 자동 갱신

worker 시작 시 `TokenRefresher` LoopingCall 자동 시작.

| 설정 | default | 의미 |
|------|---------|------|
| `worker.json` ▸ `token_refresh.loop_interval_seconds` | 14400 (4h) | DB 체크 간격 |
| `worker.json` ▸ `token_refresh.renew_threshold_seconds` | 86400 (24h) | 만료 임박 임계값 |

만료까지 24시간 미만인 token 을 cTrader `/apps/token` 으로 refresh, DB UPDATE.
콘솔 로그: `[refresh] token_id=N OK new_expires_in=2628000s`.

---

## 사용 흐름 요약

```
[1] /ctrader/api/connect              → 사용자가 브라우저로 OAuth 시작 (Flask)
[2] /ctrader/api/callback             → token DB 저장 + worker /sync_token + /sync_accounts 자동 호출 (Flask)
[3] GET    /accounts?token_id=N       → 계좌 리스트 확인 (alias 모두 null)
[4] PUT    /account_alias?account_id=M&alias=acaliastest
                                      → 원하는 계좌에 별칭 부여
[5] GET    /trader?alias=acaliastest          → 잔액/레버리지/equity
[6] GET    /positions?alias=acaliastest       → 현재 보유 포지션 + 대기 주문
[7] GET    /deals?alias=acaliastest&date=today
                                      → 그날 raw 거래 체결 내역
[8] GET    /position_list?alias=acaliastest&date=today
                                      → 그날 거래를 positionId 로 그룹화 + 요약
[9] GET    /position_detail?alias=acaliastest&position_id=P
                                      → 특정 position 의 진입~청산 lifecycle 전체
```
