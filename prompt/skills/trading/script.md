# calc_indicators.py — OHLCV 보조지표 분석 스크립트

CSV 파일 또는 웹 API(`https://stock.iasdf.com/tradingview/detailcsv`)에서 OHLCV 데이터를 받아와 기술적 보조지표를 계산·출력한다.

- 위치: `pyscript/calc_indicators.py`
- 지표 모듈: `pyscript/indicators.py`
- 샘플 CSV: `pyscript/sample.csv`
- 의존성: `numpy`, `pandas` (웹 요청은 표준 라이브러리 `urllib` 사용)

---

## 1. 설치

`pyscript/install.sh`가 venv(`venv_market`) 생성 및 의존성 설치를 수행한다.

```bash
cd pyscript
./install.sh
```

스크립트 내부 동작:

1. `pyscript/venv_market` 없으면 `python3 -m venv venv_market`으로 생성
2. venv activate
3. `pip3 install -r requirements.txt` (numpy, pandas)
4. deactivate

실행 시에는 venv를 활성화한 뒤 호출한다.

```bash
source pyscript/venv_market/bin/activate
python pyscript/calc_indicators.py ...
deactivate
```

> 시스템 Python에 `pandas`/`numpy`가 이미 설치되어 있다면 venv 없이도 실행 가능.

---

## 2. 사용 방법

두 가지 입력 모드를 지원한다. 인자 개수로 모드가 자동 분기된다.

### 2-1. CSV 파일 모드 (인자 1개)

```bash
python calc_indicators.py <csv_path>
```

- `<csv_path>`: `sample.csv` 포맷을 따르는 CSV 파일 경로
- 메타(symbol / exchange / interval)는 CSV 첫 줄에서 읽는다
- `count`는 파일 내부의 실제 데이터 줄 수로 결정된다 (메타의 count 값은 참고용)

예:

```bash
python calc_indicators.py ./sample.csv
python calc_indicators.py /tmp/us100_1m.csv
```

### 2-2. 웹 API 모드 (인자 3~4개)

```bash
python calc_indicators.py <symbol> <exchange> <interval> [count]
```

- `<symbol>`: 종목/심볼 코드 (예: `US100`, `NAS100`, `BTCUSD`)
- `<exchange>`: 거래소 코드 (예: `FPMARKETS`, `BINANCE`)
- `<interval>`: 타임프레임 (아래 표 참조)
- `[count]`: 받아올 봉 개수. **생략 시 기본값 `500`봉**

내부적으로 다음 URL을 호출한다.

```
https://stock.iasdf.com/tradingview/detailcsv?symbol=<symbol>&exchange=<exchange>&interval=<interval>&count=<count>
```

예:

```bash
# 5분봉 최근 500봉 (count 미지정 시 기본값 500)
python calc_indicators.py US100 FPMARKETS 5

# 1분봉 최근 10봉
python calc_indicators.py US100 FPMARKETS 1 10

# 일봉 최근 300봉
python calc_indicators.py US100 FPMARKETS D 300
```

---

## 3. CSV 포맷 (`sample.csv`)

```
US100,FPMARKETS,5,10                              ← 1줄: symbol,exchange,interval,count (메타)
time,open,high,low,close,volume                    ← 2줄: 헤더 (고정)
2026-04-23 17:20:00,26861.15,26865.9,26848.15,26857.9,1226.0
2026-04-23 17:15:00,26847.9,26860.15,26842.65,26859.9,1256.0
...                                                ← 3줄~: OHLCV 데이터 (최신 → 과거 순)
```

포맷 규칙:

- **1줄 메타**: 쉼표 구분 4필드. `symbol`, `exchange`, `interval`, `count`
- **2줄 헤더**: `time,open,high,low,close,volume` 고정
- **3줄~ 데이터**: 최신이 위, 과거가 아래 (DESC). 스크립트가 내부에서 오름차순으로 재정렬함
- `time` 포맷: `pandas.to_datetime`이 파싱 가능한 형식(예: `YYYY-MM-DD HH:MM:SS`)

웹 API 응답도 동일한 포맷을 반환한다고 가정한다.

---

## 4. 지원 interval

| 값 | 의미 |
|----|------|
| `1` / `3` / `5` / `15` / `30` | 분봉 |
| `60` / `120` / `240` | 시간봉 (1h / 2h / 4h) |
| `D` / `1D` | 일봉 |
| `W` / `1W` | 주봉 |
| `M` / `1M` | 월봉 |

표에 없는 값도 웹 API가 받아준다면 그대로 전달되며, 출력 시 라벨만 `<interval>봉`으로 표시된다.

---

## 5. 출력 섹션

각 호출은 아래 지표를 순서대로 출력한다.

- 이동평균선 (MA5/10/20/40/50/60/120/200)
- RSI (14, 9)
- MACD (12,26,9)
- 스토캐스틱 (14,3)
- 볼린저밴드 (20,2) + %b
- ATR (14)
- 거래량 (20봉 평균 대비)
- 피봇 포인트 (R2/R1/Pivot/S1/S2)
- 피보나치 되돌림 (최근 30봉 기준)
- 일목균형표 (9,26,52) — 후행스팬 / 구름대 / 전환선·기준선 / 삼역 종합
- MA Phase (MA5/MA20/MA40 기반 1~4 단계 + Phase 전환·안정성)
- MACD Phase (5/20/40 히스토그램 조합)
- 추세/횡보 판별 (DMI + BB Bandwidth)
- 최근 캔들 패턴 (도지 / 망치형 / 장대양봉·음봉 등)

---

## 6. 데이터 개수 가이드

지표별로 필요한 최소 봉 개수가 다르다. 충분한 데이터가 없으면 해당 섹션이 `nan` 또는 `데이터 부족`으로 표시된다.

| 지표 | 최소 권장 |
|------|-----------|
| RSI(14), 스토캐스틱(14), ATR(14), DMI(14) | 15 이상 |
| 볼린저밴드(20), BB Bandwidth | 20 이상 |
| MA40 / MA Phase | 40 이상 |
| MACD(12,26,9) | 35 이상 |
| 일목균형표 (선행스팬 표시 포함) | 78 이상 (52+26) |
| MA200 | 200 이상 |

**권장:** 정밀한 분석은 `count >= 200` 이상에서 수행한다. 데이터가 200개 미만이면 `[WARN] 데이터 N개 - 일부 장기 지표 계산이 부정확할 수 있음` 경고가 뜬다.

---

## 7. 빠른 예시

```bash
# 1) 웹에서 5분봉 받아서 분석 (count 미지정 → 기본 500봉)
python pyscript/calc_indicators.py US100 FPMARKETS 5

# 2) 웹에서 4시간봉 최근 500봉
python pyscript/calc_indicators.py BTCUSD BINANCE 240 500

# 3) 로컬 CSV 분석
python pyscript/calc_indicators.py pyscript/sample.csv

# 4) 일봉 300봉 받아서 파일로 저장
python pyscript/calc_indicators.py US100 FPMARKETS D 300 > /tmp/us100_daily.txt
```

---

## 8. 에러 메시지

| 메시지 | 원인 |
|--------|------|
| `[ERROR] 파일 없음: <path>` | CSV 파일 경로 오류 |
| `[ERROR] CSV 데이터 부족 (라인 N개)` | 메타+헤더+데이터 최소 3줄 미만 |
| `[ERROR] CSV 메타 정보 형식 오류` | 1줄 메타 필드가 3개 미만 |
| `[ERROR] OHLCV 데이터 없음` | 헤더 이후 데이터 0줄 |
| `[ERROR] API 요청 실패: <url> -> <err>` | 네트워크/타임아웃/HTTP 에러 (30초 타임아웃) |
| `[ERROR] 데이터가 2개 미만` | 전봉 대비 비교 불가 |
