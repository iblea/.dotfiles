# TradingView Alert API Endpoints

`src/webserver_flask.py` 기반 HTTP API 문서.

---

## 1. `GET /tradingview/recent_data`

각 `symbol/exchange/interval` 조합의 최신 OHLCV 1건과 최신 Fear & Greed Index를 함께 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음 (별도 인증 없음)
- **Query Parameter**

  | 구분 | 이름 | 타입 | 설명 |
  |------|------|------|------|
  | 선택 | `interval` | string | `"5"`, `"15"`, `"1h"`, `"1d"` 등. 미지정 시 모든 interval 조회 |
  | 선택 | `symbol` | string | 특정 심볼 필터 (예: `NQ1!`) |
  | 선택 | `exchange` | string | 특정 거래소 필터 (예: `CME_MINI`) |

  > 세 파라미터 모두 생략 가능. 조합해서 WHERE 조건이 AND 로 붙는다.

### 응답

- **성공**: `200 OK`, `application/json`
- **실패**: `500 Internal Server Error` (DB 조회 실패)

#### Schema (성공)

```json
{
  "status": "success",
  "data": {
    "<SYMBOL>:<EXCHANGE>": {
      "nickname": "string",
      "<interval>": {
        "start_time": "ISO-8601 datetime string",
        "last_time":  "ISO-8601 datetime string",
        "open":   "number",
        "high":   "number",
        "low":    "number",
        "close":  "number",
        "volume": "number"
      }
    }
  },
  "fear_greed_index": {
    "fetched_at": "ISO-8601 datetime string",
    "score":  "number",
    "rating": "string"
  }
}
```

- `data` 의 key 는 `"symbol:exchange"` 포맷.
- 각 key 아래로 `nickname` 과 여러 interval 키(`"5"`, `"15"`, `"1h"`, `"1d"` 등)가 함께 들어있다.
- `last_time` = `start_time + interval - 1초`.
- `fear_greed_index` 는 DB 에 데이터가 없으면 `null`.

#### Schema (실패)

```json
{ "status": "error", "message": "DB 조회 실패" }
```

---

## 2. `GET /tradingview/symbols`

파싱 대상(`parse >= 1`) 심볼 목록과 interval 별 최근 업데이트 시각, `detail` 조회용 URL 을 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음
- **Query Parameter**: 없음

### 응답

- **성공**: `200 OK`, `application/json`
- **실패**: `500 Internal Server Error` (DB 조회 실패)

#### Schema (성공)

```json
{
  "description": "symbol:exchange 형태로 나타냅니다.",
  "<SYMBOL>:<EXCHANGE>": {
    "nickname":    "string",
    "nickname_kr": "string",
    "interval": {
      "<interval>": {
        "updatetime": "ISO-8601 datetime string | null",
        "url":        "string | null"
      }
    }
  }
}
```

- 최상위 key 중 `"description"` 은 설명 필드이고, 나머지 key 는 모두 `"symbol:exchange"` 포맷.
- `interval` 은 DB 에 저장된 값이며 매핑 테이블은 다음과 같다.

  | interval | detail count |
  |----------|-------------:|
  | `"5"`    | 3000 |
  | `"15"`   | 1500 |
  | `"1h"`   | 1000 |
  | `"1d"`   |  700 |

- `url` 예시: `https://stock.iasdf.com/tradingview/detail?symbol=NQ1!&exchange=CME_MINI&interval=1h&count=1000`
- 위 매핑에 없는 interval 은 `url` 이 `null`.
- 해당 interval 로 저장된 OHLCV 가 없으면 `updatetime` 이 `null`.

#### Schema (실패)

```json
{ "status": "error", "message": "DB 조회 실패" }
```

---

## 3. `GET /tradingview/find_symbol`

TradingView 공식 `symbol_search` API 프록시. 입력한 문자열로 심볼을 검색해 결과를 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음
- **Query Parameter**

  | 구분 | 이름 | 타입 | 설명 |
  |------|------|------|------|
  | 필수 | `query` | string | 검색어. 공백은 자동 trim. 빈 문자열이면 400 |

### 응답

- **성공**: `200 OK`, `application/json`
- **실패**:
  - `400 Bad Request`: `query` 파라미터 누락/빈 문자열
  - `502 Bad Gateway`: TradingView 호출/파싱 실패

#### Schema (성공)

```json
{
  "status":  "success",
  "query":   "string",
  "count":   "integer",
  "data": [
    {
      "symbol":      "string",
      "exchange":    "string",
      "type":        "string",
      "description": "string"
    }
  ]
}
```

- TradingView 원본 응답의 `<em>` / `</em>` 태그는 제거되어 반환된다.

#### Schema (실패)

```json
{ "status": "error", "message": "query 파라미터가 필요합니다." }
```
```json
{ "status": "error", "message": "TradingView HTTPError: ... | URLError: ... | JSON 파싱 실패: ..." }
```

---

## 4. `GET /tradingview/detail`

특정 `symbol/exchange/interval` 의 최신순 OHLCV `count` 개를 JSON 으로 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음
- **Query Parameter**

  | 구분 | 이름 | 타입 | 설명 |
  |------|------|------|------|
  | 필수 | `symbol`   | string  | 심볼명 (예: `NQ1!`) |
  | 필수 | `exchange` | string  | 거래소 (예: `CME_MINI`) |
  | 필수 | `interval` | string  | `"5"`, `"15"`, `"1h"`, `"1d"` 등 |
  | 필수 | `count`    | integer | 1 ~ 3000. 범위 벗어나면 자동 클램프 (min 1, max 3000) |

### 응답

- **성공**: `200 OK`, `application/json`
- **실패**:
  - `400 Bad Request`: 필수 파라미터 누락, `count` 가 정수 아님, 데이터 없음
  - `500 Internal Server Error`: DB 조회 실패

#### Schema (성공)

```json
{
  "symbol":   "string",
  "exchange": "string",
  "interval": "string",
  "count":    "string (실제 반환된 row 개수)",
  "data": [
    {
      "time":   "YYYY-MM-DD HH:MM:SS",
      "open":   "string (숫자 문자열)",
      "high":   "string",
      "low":    "string",
      "close":  "string",
      "volume": "string"
    }
  ]
}
```

> `data` 내부 값은 모두 `str(float)` 로 직렬화된다. 숫자 비교가 필요하면 클라이언트에서 파싱해야 한다.
> `data` 는 `datetime DESC` 정렬 (최신 → 과거).

#### Schema (실패)

```json
{ "status": "error", "message": "symbol, exchange, interval, count 파라미터가 필요합니다." }
```
```json
{ "status": "error", "message": "count는 정수여야 합니다." }
```
```json
{ "status": "error", "message": "데이터를 찾을 수 없습니다. symbol=..., exchange=..., interval=..." }
```
```json
{ "status": "error", "message": "DB 조회 실패" }
```

---

## 5. `GET /tradingview/detailcsv`

`/tradingview/detail` 과 동일한 입력을 받아 CSV 포맷으로 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음
- **Query Parameter**: `/tradingview/detail` 과 완전히 동일
  (`symbol`, `exchange`, `interval`, `count` 모두 필수)

### 응답

- **성공**: `200 OK`, `Content-Type: text/csv; charset=utf-8`
- **실패**:
  - `400 Bad Request`: 필수 파라미터 누락, `count` 정수 변환 실패, 데이터 없음 → JSON 반환
  - `500 Internal Server Error`: DB 조회 실패 → JSON 반환

#### Body 포맷 (성공, CSV)

```
<symbol>,<exchange>,<interval>,<rowCount>
time,open,high,low,close,volume
YYYY-MM-DD HH:MM:SS,<open>,<high>,<low>,<close>,<volume>
YYYY-MM-DD HH:MM:SS,<open>,<high>,<low>,<close>,<volume>
...
```

- 1행: 메타데이터 (`symbol,exchange,interval,row개수`)
- 2행: 컬럼 헤더
- 3행 이후: OHLCV 데이터 (최신 → 과거 순)
- 마지막 라인 끝에 개행(`\n`) 1개 포함

#### Schema (실패, JSON)

`/tradingview/detail` 과 동일한 에러 응답 포맷.

---

## 6. `GET /tradingview/exlist`

`ex_nickname` 테이블 조회. 인자 없이 호출하면 전체 목록을, `symbol` + `exchange` 를 함께 주면 해당 PK 의 단일 행(없으면 빈 배열)을 반환한다.

### 요청

- **Method**: `GET`
- **Headers**: 없음
- **Query Parameter**

  | 구분 | 이름 | 타입 | 설명 |
  |------|------|------|------|
  | 선택 | `symbol`   | string | `exchange` 와 **함께** 주어져야 한다. `exchange` 와 쌍이 맞아야 PK 필터 모드로 진입 |
  | 선택 | `exchange` | string | `symbol` 과 **함께** 주어져야 한다 |

  - 둘 다 생략(또는 둘 다 빈 문자열) → 전체 목록 모드
  - 둘 다 존재(공백 trim 후 비어있지 않음) → PK 필터 모드
  - **둘 중 한쪽만 존재 → `400 Bad Request`**

### 응답

- **성공**: `200 OK`, `application/json`
- **실패**:
  - `400 Bad Request`: `symbol` / `exchange` 중 한쪽만 입력된 경우 (plain text body)
  - `500 Internal Server Error`: DB 조회 실패

#### Schema (성공 — 전체 목록 모드, 인자 없음)

```json
{
  "list": [
    {
      "symbol":         "string",
      "exchange":       "string",
      "nickname":       "string",
      "nickname_kr":    "string",
      "lastupdatetime": "YYYY-MM-DD HH:MM:SS"
    }
  ]
}
```

#### Schema (성공 — PK 필터 모드, `symbol` + `exchange` 둘 다 입력)

```json
{
  "list": [
    {
      "symbol":         "string",
      "exchange":       "string",
      "nickname":       "string",
      "nickname_kr":    "string",
      "lastupdatetime": "YYYY-MM-DD HH:MM:SS",
      "parsing":        "boolean"
    }
  ]
}
```

- **PK 필터 모드에서만 `parsing` 필드가 추가**된다. 전체 목록 모드에서는 포함되지 않는다.
- `list` 는 `(symbol, exchange)` 오름차순 정렬.
- PK 필터 모드 결과는 매칭되는 행이 있으면 정확히 1개, 없으면 `{"list": []}` (빈 배열).
- `lastupdatetime` 은 `ex_nickname.lastupdatetime` 컬럼 값을 `YYYY-MM-DD HH:MM:SS` (공백 구분자, 초 단위) 포맷으로 직렬화.
- 실제 차트 데이터가 아직 수집되지 않은 행은 센티넬 값 `"0001-01-01 00:00:00"` 을 가진다. (PostgreSQL `timestamp` 는 `0000-00-00` 을 허용하지 않기 때문)
- 단일 행이 반환되더라도 최상위 구조는 항상 `{"list": [ ... ]}` 포맷으로 유지된다.

#### Body (실패, 400)

```
Bad Request: symbol과 exchange는 둘 다 입력하거나 둘 다 생략해야 합니다.
```

#### Schema (실패, 500)

```json
{ "list": [], "error": "DB 조회 실패" }
```

---

## 7. `POST /tradingview/exsymbol`

`ex_nickname` 테이블에 대한 `insert` / `update` / `delete` 단일 엔드포인트. 요청 body 의 `type` 필드로 동작을 선택한다.

### 요청

- **Method**: `POST`
- **Headers**: `Content-Type: application/json`
- **Body (JSON)**

  | 구분 | 필드 | 타입 | 설명 |
  |------|------|------|------|
  | 필수 | `type`        | string | `"insert"`, `"update"`, `"delete"` 중 하나. 그 외 값은 `400` |
  | 필수 | `symbol`      | string | 공백 trim 후 빈 문자열이면 `fail` |
  | 필수 | `exchange`    | string | 공백 trim 후 빈 문자열이면 `fail` |
  | 선택 | `nickname`    | string | `insert` / `update` 에서 사용. `delete` 시 무시 |
  | 선택 | `nickname_kr` | string | `insert` / `update` 에서 사용. `delete` 시 무시 |

### 동작 상세

| `type` | 동작 |
|--------|------|
| `insert` | `(symbol, exchange)` 기준 **UPSERT**. 이미 존재하면 `nickname` / `nickname_kr` 을 덮어쓴다. `lastupdatetime` 은 건드리지 않는다. |
| `update` | `(symbol, exchange)` 의 `nickname` / `nickname_kr` 업데이트. **빈 문자열인 필드는 업데이트 대상에서 제외**. 둘 다 빈 문자열이면 `fail` ("업데이트할 값이 없음"). 해당 row 가 없으면 `fail` ("not found"). `lastupdatetime` 은 건드리지 않는다. |
| `delete` | `(symbol, exchange)` row 삭제. 해당 row 가 없으면 `fail` ("not found"). |

> `lastupdatetime` 은 이 엔드포인트에서 **절대 갱신되지 않는다**. 실제 차트 데이터가 수집되는 별도 경로에서만 현재 시각으로 갱신한다.

### 응답

- **성공 / 비즈니스 로직 실패**: `200 OK`, `application/json`
- **잘못된 요청**: `400 Bad Request` (plain text body)
  - `type` 값이 `insert` / `update` / `delete` 가 아닐 때
  - JSON body 파싱 실패 / `Content-Type` 이 `application/json` 이 아닌 경우

#### Schema (200)

```json
{
  "result":  "success | fail",
  "message": "string"
}
```

- `result == "success"` 일 때 `message` 는 빈 문자열.
- `result == "fail"` 일 때 `message` 에는 다음 중 하나가 들어간다.
  - `"symbol/exchange는 필수입니다."`
  - `"업데이트할 값이 없음"`
  - `"not found"`
  - `"DB 연결 실패"` / `"DB 연결 오류: ..."`
  - `"upsert_ex_nickname 실패: ..."` / `"update_ex_nickname 실패: ..."` / `"delete_ex_nickname 실패: ..."`

#### Body (400)

```
Bad Request: type은 insert/delete/update 중 하나여야 합니다.
```
```
Bad Request: JSON 파싱 실패
```

### 요청 / 응답 예시

#### insert (UPSERT)

```json
// request
{
  "type": "insert",
  "symbol": "NQ",
  "exchange": "CME",
  "nickname": "E-mini Nasdaq-100 Futures",
  "nickname_kr": "이미니 나스닥100 선물"
}
// response (200)
{ "result": "success", "message": "" }
```

#### update (일부 필드만)

```json
// request — nickname 은 유지, nickname_kr 만 변경
{
  "type": "update",
  "symbol": "005930",
  "exchange": "KRX",
  "nickname": "",
  "nickname_kr": "삼전"
}
// response (200)
{ "result": "success", "message": "" }
```

#### delete

```json
// request
{ "type": "delete", "symbol": "NQ", "exchange": "CME" }
// response (200, row 존재)
{ "result": "success", "message": "" }
// response (200, row 없음)
{ "result": "fail", "message": "not found" }
```

#### 잘못된 type

```json
// request
{ "type": "foo", "symbol": "A", "exchange": "B" }
// response (400, text/plain)
Bad Request: type은 insert/delete/update 중 하나여야 합니다.
```
