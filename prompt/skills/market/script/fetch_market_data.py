#!/usr/bin/env python3
"""
TradingView OHLCV 데이터 수집 스크립트

환경변수:
  TRADINGVIEW_MARKET_ID - TradingView 로그인 ID (선택)
  TRADINGVIEW_MARKET_PW - TradingView 로그인 PW (선택)

의존성:
  pip install --upgrade --no-cache-dir git+https://github.com/rongardF/tvdatafeed.git

사용법:
  python fetch_nq_futures.py -f NQ              # 심볼 검색
  python fetch_nq_futures.py -f CRUDE MCX       # 심볼 검색 (거래소 지정)
  python fetch_nq_futures.py -t NQ1! CME_MINI   # 데이터 수집 (심볼 거래소)
  python fetch_nq_futures.py -t NQ1! CME_MINI NQ1  # 데이터 수집 (심볼 거래소 라벨)
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

import requests

# pip install --upgrade --no-cache-dir git+https://github.com/rongardF/tvdatafeed.git
from tvDatafeed import TvDatafeed, Interval

SEARCH_URL = "https://symbol-search.tradingview.com/symbol_search/?text={}&hl=1&exchange={}&lang=en&type=&domain=production"
SEARCH_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Origin": "https://www.tradingview.com",
    "Referer": "https://www.tradingview.com/",
}

SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "output"

INTERVALS = [
    # (Interval, 라벨, 최대 봉 수)
    (Interval.in_15_minute, "15m", 1000),   # 약 2주
    (Interval.in_1_hour,    "1h",  1600),   # 약 3개월
    (Interval.in_daily,     "1d",  800),    # 약 3년
]


def create_tv_client():
    uid = os.environ.get("TRADINGVIEW_MARKET_ID")
    pw = os.environ.get("TRADINGVIEW_MARKET_PW")
    if uid and pw:
        print(f"[INFO] TradingView 로그인 모드 (ID: {uid})")
        return TvDatafeed(username=uid, password=pw)
    print("[INFO] 환경변수 미설정 -> 비로그인 모드")
    return TvDatafeed()


def find_symbol(keyword, exchange=None):
    print(f"심볼 검색: '{keyword}'" + (f" (거래소: {exchange})" if exchange else ""))
    print("=" * 70)

    url = SEARCH_URL.format(keyword, exchange or "")
    try:
        resp = requests.get(url, headers=SEARCH_HEADERS, timeout=10)
        resp.raise_for_status()
        clean_text = re.sub(r"</?em>", "", resp.text)
        results = json.loads(clean_text)
    except Exception as e:
        print(f"ERROR: {e}")
        return

    if not results:
        print("검색 결과 없음")
        return

    for i, item in enumerate(results):
        symbol = item.get("symbol", "")
        exchange_name = item.get("exchange", "")
        desc = item.get("description", "")
        item_type = item.get("type", "")
        print(f"  [{i+1:>3d}] {symbol:<20s} @ {exchange_name:<15s} ({item_type}) {desc}")

    print(f"\n총 {len(results)}개 결과")


def fetch_and_save(tv, symbol, exchange, label, interval, interval_name, n_bars):
    print(f"  {interval_name:>4s} ...", end=" ", flush=True)
    try:
        df = tv.get_hist(
            symbol=symbol,
            exchange=exchange,
            interval=interval,
            n_bars=n_bars,
        )
    except Exception as e:
        print(f"ERROR: {e}")
        return

    if df is None or df.empty:
        print("데이터 없음 (심볼/거래소 확인 필요)")
        return

    ohlcv_cols = ["open", "close", "high", "low", "volume"]
    df = df[[c for c in ohlcv_cols if c in df.columns]]

    today = datetime.now().strftime("%Y%m%d")
    filename = OUTPUT_DIR / f"{label}_{interval_name}_{today}.csv"
    df.to_csv(filename)
    print(f"OK ({len(df)} bars) -> {filename.name}")


def get_data(symbol, exchange, label=None, day=None):
    if label is None:
        label = re.sub(r"[!@#$%^&*]", "", symbol)

    tv = create_tv_client()
    OUTPUT_DIR.mkdir(exist_ok=True)

    print(f"\n{'='*50}")
    print(f" {label} ({symbol} @ {exchange})")
    print(f"{'='*50}")

    if day is not None:
        fetch_and_save(tv, symbol, exchange, label, Interval.in_daily, "1d", day)
    else:
        for interval, name, bars in INTERVALS:
            fetch_and_save(tv, symbol, exchange, label, interval, name, bars)

    print(f"\n완료! CSV 저장 위치: {OUTPUT_DIR.resolve()}")


def parse_args():
    parser = argparse.ArgumentParser(
        description="TradingView OHLCV 데이터 수집 & 심볼 검색",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""사용 예시:
  %(prog)s -f NQ                    심볼 검색
  %(prog)s -f CRUDE MCX             심볼 검색 (거래소 지정)
  %(prog)s -t NQ1! CME_MINI         데이터 수집 (심볼 거래소)
  %(prog)s -t NQ1! CME_MINI NQ1     데이터 수집 (심볼 거래소 라벨)
""",
    )

    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "-f", "--find-symbol",
        nargs="+",
        metavar="ARG",
        help="심볼 검색: -f KEYWORD [EXCHANGE]",
    )
    group.add_argument(
        "-t", "--get-ticker-data",
        nargs="+",
        metavar="ARG",
        help="해당 티커의 데이터 수집: -t SYMBOL EXCHANGE [LABEL]",
    )
    parser.add_argument(
        "-d", "--day",
        nargs="?",
        const=7,
        default=None,
        type=int,
        metavar="N",
        help="일봉 데이터만 수집 (기본: 7, 범위: 1~5000)",
    )

    return parser, parser.parse_args()


def main():
    parser, args = parse_args()

    if not args.find_symbol and not args.get_data:
        parser.print_help()
        sys.exit(0)

    if args.find_symbol:
        keyword = args.find_symbol[0]
        exchange = args.find_symbol[1] if len(args.find_symbol) > 1 else None
        find_symbol(keyword, exchange)
        return

    if args.get_data:
        if len(args.get_data) < 2:
            print("ERROR: -t 옵션은 최소 SYMBOL EXCHANGE 2개 인자가 필요합니다.")
            print("  예: -t NQ1! CME_MINI")
            sys.exit(1)

        day = args.day
        if day is not None and not (1 <= day <= 5000):
            print("ERROR: -d 옵션의 값은 1~5000 사이여야 합니다.")
            sys.exit(1)

        symbol = args.get_data[0]
        exchange = args.get_data[1]
        label = args.get_data[2] if len(args.get_data) > 2 else None
        get_data(symbol, exchange, label, day=day)


if __name__ == "__main__":
    main()
