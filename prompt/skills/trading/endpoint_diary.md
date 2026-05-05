# 매매 일지 API 명세

이 디렉토리(`ccpage/diary/<alias>/`) 의 매매 일지 데이터를 조회/수정하는 PHP 엔드포인트 명세.

- `alias` = 디렉토리 이름 (`acaliastest` 등). cTrader 계좌 별칭과 매핑.
- 모든 응답은 `Content-Type: application/json; charset=utf-8`.
- 한글은 `JSON_UNESCAPED_UNICODE` 로 escape 안 됨.
- 에러는 `{"error": "..."}` 형식 + 적절한 HTTP status.
- 인증/CSRF 없음 (localhost 가정). 외부 노출 시 reverse proxy 단에서 보호 필요.

## 거래일 정의 (KST 기반)

`KST 07:00 ~ 다음날 06:59:59` = 1 거래일 (CME 선물 세션).
KST 07시 이전이면 전일자 거래일로 간주.

| 현재 KST | 거래일 |
|---|---|
| 2026-04-28 06:59 | 2026-04-27 |
| 2026-04-28 07:00 | 2026-04-28 |
| 2026-04-29 06:59 | 2026-04-28 |

---

## 1. `GET diaryjson.php` — 매매 일지 조회 (read-only)

### 요청

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `date` | `YYYY-MM-DD` \| `today` \| `yesterday` | X | 조회할 거래일. 생략 시 오늘 (KST 거래일). `today`/`yesterday` 는 KST 거래일 기준 alias |
| `gid` | non-negative integer | X | 매매 단위 ID. 생략 시 또는 `0` 이면 그 날 모든 매매 |

| 케이스 | URL 예시 | 결과 |
|---|---|---|
| 1. 오늘 전체 | `/diaryjson.php` | 오늘 (KST 거래일) 모든 매매 + summary |
| 2. 특정 날짜 전체 | `/diaryjson.php?date=2026-04-27` | 그 날 모든 매매 + summary |
| 3. 특정 매매 | `/diaryjson.php?date=2026-04-27&gid=1` | 단일 review |
| 4. `gid=0` (전체 alias) | `/diaryjson.php?date=2026-04-27&gid=0` | 케이스 2 와 동일 (그 날 모든 매매 + summary) |
| 5. today / yesterday | `/diaryjson.php?date=today` , `?date=yesterday` | KST 거래일 기준 today / 전일 |

### gid 의미

| gid | 의미 |
|---|---|
| `0` | 일별 종합 회고 (`summary` 필드로 별도 표시, `gids` 에서는 제외). **조회 요청에서 `gid=0` 은 미지정과 동일하게 그 날 전체를 반환** |
| `1` ~ `9999` | 개별 매매 review |
| `10000+` | 오버나잇 자동 이전된 매매 (다른 진입일에서 청산일로 이전) — `gids` 에 포함 |

### 응답 — 케이스 1, 2 (날짜 단위)

```json
{
    "date": "2026-04-27",
    "trade_count": 3,
    "trade_count_detail": "2/1/0",
    "winrate": "66.67%",
    "total_profit": "10.99",
    "trade_time_avg": "3h 41m",
    "avg_lot": 0.343,
    "summary": {
        "review": "오늘 전체 회고...",
        "aireview": "AI 종합 의견...",
        "wl_record": "win"
    },
    "gidlist": [1, 2, 3],
    "gids": {
        "1": { "...review object..." },
        "2": { "...review object..." },
        "3": { "...review object..." }
    }
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `date` | string | 조회한 거래일 |
| `trade_count` | integer | gid≥1 매매 갯수 |
| `trade_count_detail` | string | `"승/패/무"` (진행중 제외) |
| `winrate` | string | `"NN.NN%"` 또는 `"—"`. 승/(승+패), 무 제외 |
| `total_profit` | string | 모든 review 의 `profit_loss` 합 (소수 2자리, 부호 없음). 진행중 review 의 부분 청산 손익도 포함 |
| `trade_time_avg` | string | 청산 완료 review 의 보유시간 평균. `"Xh Ym"` 또는 `"—"` |
| `avg_lot` | number | 매 review 의 `total_lot` 평균 (소수 3자리 반올림) |
| `summary` | object \| null | gid=0 데이터. 없으면 `null` |
| `gidlist` | integer[] | 포함된 gid 정렬 (오름차순) |
| `gids` | object | `gid: review_object` 매핑. 비면 `{}` |

### 응답 — 케이스 3 (단일 gid ≥ 1) — review object

```json
{
    "wl_record": "win",
    "profit_loss": "4.73",
    "total_lot": "0.130",
    "holding_time": "8h 19m",
    "RR": "1.33",
    "positions": [
        {
            "product": "US100",
            "entry": "LONG",
            "first_entry_time": "2026-04-27 12:51",
            "avg_price": "27389.71667",
            "lots": "0.030",
            "TP": "",
            "SL": "",
            "detail": [
                {
                    "type": "ENTRY",
                    "entry": "LONG",
                    "lot": "0.01",
                    "price": "27413.05",
                    "time": "2026-04-27 12:51"
                },
                {
                    "type": "CLOSE",
                    "entry": "SHORT",
                    "lot": "0.03",
                    "price": "27354.95",
                    "profit_loss": "-1.04",
                    "time": "2026-04-27 21:10"
                }
            ]
        }
    ],
    "review": "진입근거 / 회고...",
    "aireview": "AI 의견..."
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `wl_record` | string | `"win"` \| `"lose"` \| `"draw"` \| `"open"`. `outcome_override` 우선, 없으면 deals 합산으로 자동 판정 |
| `profit_loss` | string | 청산 deal `profit` 합 (소수 2자리). cTrader profit=0 케이스 fallback `(entry-close)*lots` |
| `total_lot` | string | `SUM(volume_lots)` 소수 3자리 |
| `holding_time` | string | union 합산 (대기 시간 제외) `"Xh Ym"` / `"Xm"` |
| `RR` | string | TP+SL+EP 모두 입력된 position 평균 R:R, 없으면 `"—"` |
| `positions` | array | 진입 시간 오름차순 |
| `review` | string | 진입근거 / 회고 (사용자 입력) |
| `aireview` | string | AI 의견 (사용자 입력 또는 `update_aireview.php` 로 갱신) |

### position 객체

| 필드 | 타입 | 설명 |
|---|---|---|
| `product` | string | symbol_name (예: `"US100"`) |
| `entry` | string | `"LONG"` \| `"SHORT"` (포지션 방향) |
| `first_entry_time` | string | 첫 진입 시각 `"YYYY-MM-DD HH:MM"` (KST) |
| `avg_price` | string | 평균 진입가 |
| `lots` | string | 진입 랏수 |
| `TP` | string | take_profit (없으면 `""`) |
| `SL` | string | stop_loss (없으면 `""`) |
| `detail` | array | deal 목록 (executionTimestamp 오름차순). `_deleted` 마크 제외 |

### deal 객체

| 필드 | 타입 | 설명 |
|---|---|---|
| `type` | string | `"ENTRY"` (진입) \| `"CLOSE"` (청산) |
| `entry` | string | cTrader `tradeSide` 그대로 (`"LONG"` \| `"SHORT"`). LONG 포지션의 청산 deal 은 `"SHORT"` |
| `lot` | string | 체결 랏수 |
| `price` | string | 체결가 |
| `time` | string | `"YYYY-MM-DD HH:MM"` (KST) |
| `profit_loss` | string | **`CLOSE` deal 에만**. cTrader profit (0 이면 fallback 계산) |

### 응답 — 케이스 4 (`gid=0`)

`gid=0` 은 **미지정과 동일하게 처리** 되어 케이스 1, 2 와 같은 날짜 단위 응답 (`{ date, trade_count, ..., summary, gidlist, gids }`) 이 반환된다.
일별 종합 데이터(thesis/ai_opinion/outcome_override)는 `summary` 필드로 함께 묶여 나온다 (없으면 `summary: null`).

`summary` object 구조 (날짜 단위 응답의 한 필드로 등장):

```json
{
    "review": "오늘 전체 회고",
    "aireview": "AI 종합 의견",
    "wl_record": "win"
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `review` | string | thesis (일별 종합 회고) |
| `aireview` | string | ai_opinion (AI 종합 의견) |
| `wl_record` | string \| null | `outcome_override` 만 사용. 없으면 `null` |

### 에러 응답

| HTTP | Body | 케이스 |
|---|---|---|
| `400` | `{"error":"invalid date (expected YYYY-MM-DD)"}` | date 형식 위배 |
| `400` | `{"error":"invalid gid (expected non-negative integer)"}` | gid 음수/문자 |
| `404` | `{"error":"not found"}` | 단일 gid 요청, review 없음 |
| `500` | `{"error":"internal error","message":"..."}` | DB/PHP 예외 |

### 예시

```bash
# 오늘 매매
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php'

# 특정 날짜 전체
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php?date=2026-04-27'

# 단일 매매
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php?date=2026-04-27&gid=1'

# gid=0 (미지정과 동일 — 그 날 전체)
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php?date=2026-04-27&gid=0'

# today / yesterday alias (KST 거래일 기준)
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php?date=today'
curl 'http://example/ccpage/diary/acaliastest/diaryjson.php?date=yesterday'
```

---

## 2. `POST update_aireview.php` — AI 의견 갱신

특정 review 의 `ai_opinion` (= JSON 응답의 `aireview`) 을 외부에서 업데이트.

### 요청

- Method: **POST**
- Content-Type: `application/json`
- Body:

```json
{
    "date": "2026-04-27",
    "gid": 0,
    "aireview": "AI 의견 본문\n개행은 \\n 으로"
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `date` | string `YYYY-MM-DD` \| `"today"` \| `"yesterday"` | O | 거래일. `"today"`/`"yesterday"` 는 KST 거래일 기준 alias |
| `gid` | non-negative integer | O | `0` = 일별 종합, `≥1` = 개별 매매 |
| `aireview` | string | O | AI 의견 본문 (개행은 JSON `\n`) |

### 동작

| gid | 동작 |
|---|---|
| `0` | UPSERT — `trade_gid` row 없으면 INSERT (lazy-init), 있으면 UPDATE |
| `≥1` | UPDATE 만. row 없으면 404 |

### 응답 (성공)

```json
{
    "ok": true,
    "date": "2026-04-27",
    "gid": 0,
    "length": 56
}
```

| 필드 | 타입 | 설명 |
|---|---|---|
| `ok` | boolean | 항상 `true` |
| `date` | string | echo |
| `gid` | integer | echo |
| `length` | integer | 저장된 `aireview` byte 길이 |

### 에러 응답

| HTTP | Body | 케이스 |
|---|---|---|
| `400` | `{"error":"invalid JSON body"}` | body 가 JSON 객체가 아님 |
| `400` | `{"error":"invalid date (expected \"YYYY-MM-DD\" \| \"today\" \| \"yesterday\")"}` | date 형식 위배 |
| `400` | `{"error":"invalid date (calendar)"}` | 달력에 없는 날짜 (예: 2026-02-30) |
| `400` | `{"error":"invalid gid (non-negative integer required)"}` | gid 음수/문자 |
| `400` | `{"error":"invalid aireview (string required)"}` | aireview 누락/non-string |
| `404` | `{"error":"review not found","date":"...","gid":N}` | gid≥1 인데 review 없음 |
| `405` | `{"error":"POST only"}` (`Allow: POST` 헤더 포함) | GET 등 다른 메소드 |
| `500` | `{"error":"internal error","message":"..."}` | DB/PHP 예외 |

### 예시

```bash
# 일별 종합 AI 의견 갱신 (gid=0)
curl -X POST -H 'Content-Type: application/json' \
     -d '{"date":"2026-04-28","gid":0,"aireview":"오늘 매매 종합 분석\n1. 추세 상향\n2. ..."}' \
     'http://example/ccpage/diary/acaliastest/update_aireview.php'

# 단일 매매 AI 의견 갱신 (gid=1)
curl -X POST -H 'Content-Type: application/json' \
     -d '{"date":"2026-04-28","gid":1,"aireview":"진입가 양호\n손절 라인은 보수적으로..."}' \
     'http://example/ccpage/diary/acaliastest/update_aireview.php'

# date alias 사용 (KST 거래일 기준 today / yesterday)
curl -X POST -H 'Content-Type: application/json' \
     -d '{"date":"today","gid":0,"aireview":"오늘 종합..."}' \
     'http://example/ccpage/diary/acaliastest/update_aireview.php'
curl -X POST -H 'Content-Type: application/json' \
     -d '{"date":"yesterday","gid":1,"aireview":"어제 매매 회고..."}' \
     'http://example/ccpage/diary/acaliastest/update_aireview.php'
```

### 주의사항

- `aireview` 는 **전체 덮어쓰기** (append 아님)
- `\n` 으로 개행 보존됨. DB 에 newline 그대로 저장, 응답에서 다시 `\n` 으로 escape
- gid≥1 review 는 먼저 `diary.php` UI 에서 만들어야 함 (`update_aireview.php` 로는 신규 review 생성 불가)

---

## 부록: 데이터 모델 요약

| 컬럼 | 의미 |
|---|---|
| `trade_gid.thesis` | API 응답의 `review` (사용자 작성 회고) |
| `trade_gid.ai_opinion` | API 응답의 `aireview` (AI 의견) |
| `trade_gid.outcome_override` | API 응답의 `wl_record` 우선 결정 (`win`/`lose`/`draw`/null) |
| `trade_gid_position.deals` (JSONB) | API 응답의 `positions[].detail` 원천. cTrader raw deal + 사용자 마크 (`_manual`/`_edited`/`_deleted`) |
