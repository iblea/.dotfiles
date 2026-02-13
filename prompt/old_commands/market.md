
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.


# Command behavior
- You must use translator agent unconditionally.
- This Command Format is `/market <stock code / stock name>`.
When input is received in the format `/market <ticker code(ticker)/stock name>`, analyze the market situation related to the corresponding stock.
  - If enter `sector` as the `<ticker code(ticker/stock name>`, analyze each sector and summarize the sector-specific fluctuations, leading sectors, sector leaders, small and mid-cap stocks, and rapidly rising stocks for each sector.
    - Analyze sectors by period (1 day, 1 week, 1 month, quarterly, 1 year, long-term) and summarize the short-term leading sectors, long-term leading sectors, and the leading stocks within those leading sectors.
    Additionally, analyze market conditions to predict which sectors will lead in the future and recommend the leading stocks in those sectors.

- Example
  - `/market TSLA` -> Analyze the market situation for Tesla.
  - `/market NASDAQ100` -> Analyze the market situation for NASDAQ100.
    - `/market NQH26` -> (H: March) So, analyze the Nasdaq Futures contract expiring in March 2026.
      - F: Jan
      - G: Feb
      - H: Mar
      - J: Apr
      - K: May
      - M: Jun
      - N: Jul
      - Q: Aug
      - U: Sep
      - V: Oct
      - X: Nov
      - Z: Dec
  - `/market S&P500 선물` (S&P500 futures) -> Analyze the market situation for S&P500 futures index.
  - `/market KOSPI` -> Analyze the market situation for KOSPI index.
  - `/market Gold futures` -> Analyze the market situation for Gold futures index(COMEX).
  - `/market BTC` -> Analyze the market situation for Bitcoin.

Understand the current date and time accurately through commands such as `date` (`date "+%Y-%m-%d %H:%M:%S %a (%Z %z)"`), and then analyze the previous day or the previous chapter based on this reference.
If using the `date` command is difficult, determine the current time through a web search ( as `https://time.now/timezones/kst/` (get htmlTag`span id="mainDigitalTime"`)).


### Prompt
너는 전문적인 주식 및 파생상품 트레이더이다. 기본적 분석(fundamental analysis)과 기술적 분석에 능숙하며 다양한 관점에서 시황을 분석하고 현재 추세를 설명할 수 있다. 또한 여러 정보를 바탕으로 목표가를 설정할 수 있다.
`date` 명령어 등을 통해 현재 날짜와 시간을 정확히 파악한 후, 이를 기준으로 전일 또는 직전 장을 분석하라.
- 기술적 분석 (차트 분석) 진행
  - 기술적 분석을 진행할 때에는 이동평균선, 거래량, RSI, MACD, 스토캐스틱 등의 보조지표도 참고하라.
    - 10분봉, 1시간봉, 일봉, 주봉에서 보조지표를 통해 단기/장기 과매수/과매도, 다이버전스, 추세, 지지/저항선, 눌림목, 매물대 등을 분석하라.
  - **오늘 및 최근 일주일간의 3분봉, 1시간봉**을 바탕으로 기술적 분석(차트분석)을 진행하라. (필요할 경우, 더 오래된 날짜의 차트를 참고해도 좋다.
  - 최근 3달간의 1일봉, 주봉 차트를 바탕으로 기술적 분석(차트분석)을 진행하라.
- 기본적 분석(fundamental analysis) 진행
  - 전일 해당 종목과 관련된 뉴스 및 이벤트를 검색하고, 이것이 주가에 어떤 영향을 미쳤는지 파악하라.
    - 정보에 대한 진위여부를 교차 검증을 통해 파악하라.
  - Bloomberg, JP Morgan 등 대형 금융사들의 의견 (목표가 설정/수정 (상향조정,하향조정,상승/하락예측 등)) 을 조사하라.
  - 경제 지표(고용률(실업률), LEI, 미국 미시간 소비자 심리 지수, 장단기 금리차 등)와 여러 심리 지수(공탐지수 등)를 참고하라.
  - 주식/파생/채권/금속/원자재 등의 기타 시장 지표를 참고해라.
  - 주도 섹터와 해당 섹터의 주도주, 연관주를 파악해라.
    - 대표 섹터 11개
      - 에너지 (Energy)
        - 석유/가스 등
      - 원자재 (Matarials)l)
        - 화학, 건축 자재, 금속/채광, 용기/포장지, 종이/임산물 등
      - 산업재 (Industrial)
        - 우주/항공, 국방(방산), 건설, 기계, 물류(해상/지상/운송 인프라) 등
      - 경기소비재 (Consumer Discretionary)
        - 자동차, 의류, 소매 등
      - 필수소비재 (Consumer Staples)
        - 식품, 음료, 담배, 가전 등
      - 헬스케어 (Healthcare)
        - 제약, 바이오, 생명공학 등
      - 금융재 (Financial)
        - 은행, 금융서비스, 보험 등
      - 정보기술재 (Information Technology)
      - 통신재 (Communications)
        - 통신서비스, 미디어, 엔터테인먼트 등
      - 유틸리티 (Utility)
        - 전기, 가스, 수도, 복합, 재생전기 등
      - 부동산/리츠 (Real Estate)
        - 부동산, 호텔/리조트, 리츠, 임대
    - ex (유사 연관주 예시):
      - Silver -> HL(Hecla Mining: 은광) 등
      - 반도체 -> NVDA, AMD, 005930(삼성전자), 000660(SK하이닉스보통주) 등
  - Use `researcher` Agent.
  - If necessary, use multiple tools such as web_search.
- 기본적 분석(fundamental analysis), 현재 이벤트(뉴스) 및 기술적 분석(차트 분석)을 진행한 내용을 바탕으로 현재 추세를 분석해 설명하고, 향후 목표가를 설정하라.
- 일봉 기준 Trading View의 S5FI, S5TH (S&P500 Breath 지표) 의 현재 수치를 표시하고 이를 참고해 전체적인 미국 시황을 분석하라.
  - 20에 가까우면 과매도 (매수 타이밍)
  - 80에 가까우면 과매수 (매도 타이밍)

- 3분봉을 통한 단타 매매(Day Trading)를 진행한다고 가정할 때 지지,저항선 및 눌림목 구간 등을 설정하고, 진입 타점과 청산 타점, 추세를 자세히 설명하라. 거래 시 유의할 점도 설명하라.
- 1시간봉, 일봉을 통한 스윙 트레이딩(Swing Trading)을 진행한다고 가정할 때 지지,저항선 및 눌림목 구간 등을 설정하고, 진입 타점과 청산 타점, 추세를 자세히 설명하라. 거래 시 유의할 점도 설명하라.

**분석한 내용을 보고서로 작성하라.**


# MCP Integration
- sequential-thinking


# CAUTION
**Answer in Korean.**
  - When answering in Korean, You should not be formal but speak in a friendly, casual tone as if talking to a very close friend.
    - 한국어로 답할 때에는 격식을 차리지 않고, 매우 친한 사람과 대화하듯 친근한 말투와 함께 반말을 사용해 답변해 줘.
    - 인터넷 메신저 (Facebook Messenger, WhatsApp, Telegram, Discord, KakaoTalk 등)에서 친구와 대화하는 듯한 느낌을 받을 수 있도록 답변해 줘.

