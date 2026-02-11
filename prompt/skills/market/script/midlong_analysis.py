#!/usr/bin/env python3
"""중장기 기술적 분석 (가격변동, 급등급락, 갭, ATR, 피보나치, 캔들패턴)

Usage:
    python midlong_analysis.py <daily_csv>
    python midlong_analysis.py AXTI_1d_20260211.csv
"""

import argparse

from indicators import load_csv, calc_atr


def analyze(csv_path):
    df, label = load_csv(csv_path)
    current = df['close'].iloc[-1]

    print("=" * 70)
    print(f"  {label} 중장기 기술적 분석")
    print("=" * 70)

    # ----- 중장기 가격 변동 -----
    print(f"\n[중장기 가격 변동]")
    offsets = {
        '1주전': 6,
        '1개월전': 22,
        '3개월전': 63,
        '6개월전': 126,
        '1년전': 252,
    }
    for period_name, offset in offsets.items():
        if len(df) > offset:
            price = df.iloc[-offset]['close']
            chg = (current / price - 1) * 100
            print(f"  {period_name}: {price:.2f} -> {current:.2f} ({chg:+.1f}%)")

    # ----- 월별 가격 범위 -----
    print(f"\n[최근 월별 가격 범위]")
    last_date = df.index[-1]
    for month_offset in range(0, 3):
        m = last_date.month - month_offset
        y = last_date.year
        if m <= 0:
            m += 12
            y -= 1
        month_data = df[(df.index.month == m) & (df.index.year == y)]
        if len(month_data) > 0:
            month_name = f"{y}-{m:02d}"
            print(f"  {month_name}: {month_data['low'].min():.2f} ~ {month_data['high'].max():.2f}")

    # ----- 급등/급락 패턴 -----
    print(f"\n[최근 급등/급락일 (|변동| > 5%)]")
    df['pct_chg'] = df['close'].pct_change() * 100
    big_moves = df[abs(df['pct_chg']) > 5].tail(20)
    for idx, row in big_moves.iterrows():
        print(f"  {idx.strftime('%Y-%m-%d')}: {row['pct_chg']:+.1f}% "
              f"(종가 {row['close']:.2f}, 거래량 {row['volume']:,.0f})")

    # ----- 갭 분석 -----
    print(f"\n[최근 갭 분석 (최근 20일, |갭| > 2%)]")
    for i in range(-min(20, len(df) - 1), 0):
        prev_close = df.iloc[i - 1]['close']
        curr_open = df.iloc[i]['open']
        gap = (curr_open / prev_close - 1) * 100
        if abs(gap) > 2:
            date = df.index[i].strftime('%Y-%m-%d')
            print(f"  {date}: {gap:+.1f}% 갭 (전일종가 {prev_close:.2f} -> 시가 {curr_open:.2f})")

    # ----- ATR -----
    df['ATR14'] = calc_atr(df, 14)
    atr = df['ATR14'].iloc[-1]
    print(f"\n[ATR (변동성)]")
    print(f"  ATR(14): {atr:.2f} (일평균 변동폭)")
    print(f"  ATR/현재가 비율: {atr / current * 100:.1f}%")

    # ----- 피보나치 되돌림 -----
    tail_30 = df.tail(30)
    recent_low = tail_30['low'].min()
    recent_high = tail_30['high'].max()
    fib_range = recent_high - recent_low
    print(f"\n[피보나치 되돌림 (최근 30일: {recent_low:.2f} ~ {recent_high:.2f})]")
    fib_levels = [0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]
    for level in fib_levels:
        price = recent_high - fib_range * level
        marker = " << 현재가 근처" if abs(price - current) < fib_range * 0.03 + 0.01 else ""
        print(f"  {level * 100:5.1f}%: {price:.2f}{marker}")

    # ----- 캔들 패턴 분석 -----
    print(f"\n[최근 캔들 패턴 (3일)]")
    for i in [-3, -2, -1]:
        if abs(i) > len(df):
            continue
        row = df.iloc[i]
        body = row['close'] - row['open']
        body_size = abs(body)
        total_range = row['high'] - row['low']

        date = df.index[i].strftime('%Y-%m-%d')
        candle_type = "양봉" if body > 0 else "음봉"

        pattern = ""
        if total_range > 0:
            upper_wick = row['high'] - max(row['open'], row['close'])
            lower_wick = min(row['open'], row['close']) - row['low']
            if body_size < total_range * 0.1:
                pattern = "도지 (Doji)"
            elif body < 0 and lower_wick > body_size * 2:
                pattern = "망치형 (Hammer)"
            elif body > 0 and upper_wick > body_size * 2:
                pattern = "역망치형"
            elif body < 0 and body_size > total_range * 0.6:
                pattern = "장대음봉 (Bearish Marubozu)"
            elif body > 0 and body_size > total_range * 0.6:
                pattern = "장대양봉 (Bullish Marubozu)"

        print(f"  {date}: {candle_type} O:{row['open']:.2f} H:{row['high']:.2f} "
              f"L:{row['low']:.2f} C:{row['close']:.2f} (체결:{row['volume']:,.0f})")
        if pattern:
            print(f"           패턴: {pattern}")


def main():
    parser = argparse.ArgumentParser(description="중장기 기술적 분석")
    parser.add_argument("daily_csv", help="일봉 OHLCV CSV 파일 경로")
    args = parser.parse_args()

    analyze(args.daily_csv)


if __name__ == "__main__":
    main()
