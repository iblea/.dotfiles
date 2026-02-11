#!/usr/bin/env python3
"""일봉 기술적 분석 (이동평균, RSI, MACD, 스토캐스틱, 볼린저밴드, 피봇, 52주 범위)

Usage:
    python daily_indicator.py <daily_csv>
    python daily_indicator.py AXTI_1d_20260211.csv
"""

import argparse

import pandas as pd
import numpy as np

from indicators import (
    load_csv, calc_rsi, calc_macd, calc_stochastic, calc_bollinger,
    add_moving_averages, print_ma_line,
)


def analyze(csv_path):
    df, label = load_csv(csv_path)

    if len(df) < 200:
        print(f"[WARN] 데이터가 {len(df)}개로 일부 장기 이평선 계산이 부정확할 수 있음")

    # ----- 이동평균선 -----
    df = add_moving_averages(df)

    latest = df.iloc[-1]
    prev = df.iloc[-2]

    print("=" * 70)
    print(f"  {label} 일봉 기술적 분석 (Daily)")
    print("=" * 70)

    print(f"\n[이동평균선]")
    chg = latest['close'] - prev['close']
    pct = (latest['close'] / prev['close'] - 1) * 100
    print(f"  현재가: {latest['close']:.2f} (전일대비: {chg:+.2f}, {pct:+.2f}%)")
    for p in [5, 10, 20, 50, 60, 120, 200]:
        col = f'MA{p}'
        if pd.notna(latest[col]):
            print_ma_line(f"{p}일선", latest[col], latest['close'])

    # ----- RSI -----
    df['RSI14'] = calc_rsi(df['close'], 14)
    df['RSI9'] = calc_rsi(df['close'], 9)
    print(f"\n[RSI]")
    print(f"  RSI(14): {df['RSI14'].iloc[-1]:.2f}  (전일: {df['RSI14'].iloc[-2]:.2f})")
    print(f"  RSI(9):  {df['RSI9'].iloc[-1]:.2f}  (전일: {df['RSI9'].iloc[-2]:.2f})")

    # ----- MACD -----
    macd, signal, hist = calc_macd(df['close'])
    df['MACD'], df['MACD_Signal'], df['MACD_Hist'] = macd, signal, hist
    print(f"\n[MACD (12,26,9)]")
    print(f"  MACD:   {macd.iloc[-1]:.4f}  (전일: {macd.iloc[-2]:.4f})")
    print(f"  Signal: {signal.iloc[-1]:.4f}  (전일: {signal.iloc[-2]:.4f})")
    print(f"  Hist:   {hist.iloc[-1]:.4f}  (전일: {hist.iloc[-2]:.4f})")
    if macd.iloc[-1] > signal.iloc[-1]:
        print(f"  -> MACD > Signal (매수 신호 유지)")
    else:
        print(f"  -> MACD < Signal (매도 신호)")

    # ----- 스토캐스틱 -----
    k, d = calc_stochastic(df)
    print(f"\n[스토캐스틱 (14,3)]")
    print(f"  %K: {k.iloc[-1]:.2f}  (전일: {k.iloc[-2]:.2f})")
    print(f"  %D: {d.iloc[-1]:.2f}  (전일: {d.iloc[-2]:.2f})")

    # ----- 볼린저밴드 -----
    bb_mid, bb_upper, bb_lower = calc_bollinger(df['close'])
    print(f"\n[볼린저밴드 (20,2)]")
    print(f"  상단: {bb_upper.iloc[-1]:.2f}")
    print(f"  중단: {bb_mid.iloc[-1]:.2f}")
    print(f"  하단: {bb_lower.iloc[-1]:.2f}")

    # ----- 거래량 -----
    avg_vol_20 = df['volume'].rolling(20).mean().iloc[-1]
    print(f"\n[거래량 분석]")
    print(f"  최근 거래량: {latest['volume']:,.0f}")
    print(f"  20일 평균:   {avg_vol_20:,.0f}")
    print(f"  비율: {latest['volume'] / avg_vol_20 * 100:.1f}%")

    # ----- 피봇 포인트 -----
    pivot = (latest['high'] + latest['low'] + latest['close']) / 3
    r1 = 2 * pivot - latest['low']
    s1 = 2 * pivot - latest['high']
    r2 = pivot + (latest['high'] - latest['low'])
    s2 = pivot - (latest['high'] - latest['low'])
    print(f"\n[피봇 포인트]")
    print(f"  R2: {r2:.2f}")
    print(f"  R1: {r1:.2f}")
    print(f"  Pivot: {pivot:.2f}")
    print(f"  S1: {s1:.2f}")
    print(f"  S2: {s2:.2f}")

    # ----- 52주 범위 -----
    tail_252 = df.tail(252)
    high_52w = tail_252['high'].max()
    low_52w = tail_252['low'].min()
    pos = (latest['close'] - low_52w) / (high_52w - low_52w) * 100 if high_52w != low_52w else 0
    print(f"\n[52주 범위]")
    print(f"  52주 고가: {high_52w:.2f}")
    print(f"  52주 저가: {low_52w:.2f}")
    print(f"  현재 위치: {pos:.1f}%")

    # ----- 최근 주요 가격대 -----
    print(f"\n[최근 주요 가격대]")
    for days in [60, 20]:
        tail = df.tail(days)
        hi_idx = tail['high'].idxmax()
        lo_idx = tail['low'].idxmin()
        print(f"  {days}일 고가: {tail['high'].max():.2f} ({hi_idx.strftime('%Y-%m-%d')})")
        print(f"  {days}일 저가: {tail['low'].min():.2f} ({lo_idx.strftime('%Y-%m-%d')})")

    # ----- 추세 요약 -----
    print(f"\n[추세 요약]")
    ma5 = latest.get('MA5', np.nan)
    ma20 = latest.get('MA20', np.nan)
    ma50 = latest.get('MA50', np.nan)
    if pd.notna(ma5) and pd.notna(ma20) and pd.notna(ma50):
        if ma5 > ma20 > ma50:
            print(f"  이동평균 정배열 (강세)")
        elif ma5 < ma20 < ma50:
            print(f"  이동평균 역배열 (약세)")
        else:
            print(f"  이동평균 혼조세")

    if len(df) >= 5 and pd.notna(df['MA5'].iloc[-3]):
        ma5_slope = (df['MA5'].iloc[-1] - df['MA5'].iloc[-3]) / 2
        print(f"  5일선 기울기: {ma5_slope:+.2f}")
    if len(df) >= 25 and pd.notna(df['MA20'].iloc[-5]):
        ma20_slope = (df['MA20'].iloc[-1] - df['MA20'].iloc[-5]) / 4
        print(f"  20일선 기울기: {ma20_slope:+.2f}")


def main():
    parser = argparse.ArgumentParser(description="일봉 기술적 분석")
    parser.add_argument("daily_csv", help="일봉 OHLCV CSV 파일 경로")
    args = parser.parse_args()

    analyze(args.daily_csv)


if __name__ == "__main__":
    main()
