#!/usr/bin/env python3
"""1시간봉/15분봉 보조지표 + 매물대/VWAP/다이버전스 분석

Usage:
    python intraday_indicator.py <15m_csv> <1h_csv> [--daily <daily_csv>]
    python intraday_indicator.py AXTI_15m_20260211.csv AXTI_1h_20260211.csv --daily AXTI_1d_20260211.csv
"""

import argparse

import pandas as pd
import numpy as np

from indicators import (
    load_csv, calc_rsi, calc_macd, calc_stochastic,
    add_moving_averages, print_ma_line,
)


def analyze_timeframe(csv_path, tf_name):
    """단일 타임프레임 보조지표 분석"""
    df, label = load_csv(csv_path)
    df = add_moving_averages(df)
    latest = df.iloc[-1]

    print("=" * 70)
    print(f"  {label} {tf_name} 기술적 분석")
    print("=" * 70)

    # ----- 이동평균선 -----
    print(f"\n[이동평균선 ({tf_name})]")
    print(f"  현재가: {latest['close']:.2f}")
    for p in [5, 10, 20, 50, 120, 200]:
        col = f'MA{p}'
        if pd.notna(latest[col]):
            print_ma_line(f"{p}봉선", latest[col], latest['close'])

    # ----- RSI -----
    df['RSI14'] = calc_rsi(df['close'], 14)
    df['RSI9'] = calc_rsi(df['close'], 9)
    print(f"\n[RSI ({tf_name})]")
    print(f"  RSI(14): {df['RSI14'].iloc[-1]:.2f}")
    print(f"  RSI(9):  {df['RSI9'].iloc[-1]:.2f}")

    # ----- MACD -----
    macd, sig, hist = calc_macd(df['close'])
    print(f"\n[MACD ({tf_name})]")
    print(f"  MACD:   {macd.iloc[-1]:.4f}")
    print(f"  Signal: {sig.iloc[-1]:.4f}")
    print(f"  Hist:   {hist.iloc[-1]:.4f}")
    if macd.iloc[-1] > sig.iloc[-1]:
        print(f"  -> MACD > Signal (매수)")
    else:
        print(f"  -> MACD < Signal (매도)")

    # ----- 스토캐스틱 -----
    k, d = calc_stochastic(df)
    print(f"\n[스토캐스틱 ({tf_name})]")
    print(f"  %K: {k.iloc[-1]:.2f}")
    print(f"  %D: {d.iloc[-1]:.2f}")

    return df, label


def analyze_volume_profile(daily_csv, tail_days=60):
    """일봉 기반 매물대/VWAP/다이버전스 분석"""
    df, label = load_csv(daily_csv)
    df_recent = df.tail(tail_days)

    print("\n" + "=" * 70)
    print(f"  주요 지지/저항대 분석 (일봉 {tail_days}일 기준)")
    print("=" * 70)

    # ----- VWAP -----
    vwap_sum = 0
    vol_sum = 0
    for _, row in df_recent.iterrows():
        mid = (row['high'] + row['low'] + row['close']) / 3
        vwap_sum += mid * row['volume']
        vol_sum += row['volume']
    vwap = vwap_sum / vol_sum if vol_sum > 0 else 0
    print(f"\n  {tail_days}일 VWAP: {vwap:.2f}")

    # ----- 가격대별 거래량 프로필 -----
    price_floor = int(df_recent['low'].min())
    price_ceil = int(df_recent['high'].max()) + 2
    price_bins = np.arange(price_floor, price_ceil, 1)

    vol_profile = []
    for i in range(len(price_bins) - 1):
        lo, hi = price_bins[i], price_bins[i + 1]
        mask = (df_recent['low'] <= hi) & (df_recent['high'] >= lo)
        v = df_recent.loc[mask, 'volume'].sum()
        vol_profile.append((lo, hi, v))

    if vol_profile:
        max_v = max(vp[2] for vp in vol_profile)
        print(f"\n  가격대별 거래량 프로필 ({tail_days}일):")
        for lo, hi, v in sorted(vol_profile, key=lambda x: x[2], reverse=True):
            bar_len = int(v / max_v * 30) if max_v > 0 else 0
            bar = "█" * bar_len
            print(f"    ${lo:5.0f}-${hi:5.0f}: {v:>12,.0f} {bar}")

    # ----- 다이버전스 체크 -----
    print(f"\n[다이버전스 체크 (일봉)]")
    rsi_d = calc_rsi(df_recent['close'], 14)
    recent_20 = df_recent.tail(20)
    if len(recent_20) > 0:
        max_idx = recent_20['high'].idxmax()
        max_price = recent_20.loc[max_idx, 'high']
        print(f"  최근 20일 고가: {max_price:.2f} ({max_idx.strftime('%Y-%m-%d')})")
        if max_idx in rsi_d.index and pd.notna(rsi_d.loc[max_idx]):
            print(f"  해당일 RSI(14): {rsi_d.loc[max_idx]:.2f}")
        else:
            print(f"  RSI 데이터 없음")

    # 직전 월/당월 고점
    last_date = df_recent.index[-1]
    cur_month = last_date.month
    cur_year = last_date.year
    prev_month = cur_month - 1 if cur_month > 1 else 12
    prev_year = cur_year if cur_month > 1 else cur_year - 1

    prev_month_data = df_recent[
        (df_recent.index.month == prev_month) & (df_recent.index.year == prev_year)
    ]
    if len(prev_month_data) > 0:
        pm_max_idx = prev_month_data['high'].idxmax()
        print(f"  전월 고가: {prev_month_data.loc[pm_max_idx, 'high']:.2f} ({pm_max_idx.strftime('%Y-%m-%d')})")


def main():
    parser = argparse.ArgumentParser(description="1시간봉/15분봉 보조지표 + 매물대 분석")
    parser.add_argument("csv_15m", help="15분봉 OHLCV CSV 파일 경로")
    parser.add_argument("csv_1h", help="1시간봉 OHLCV CSV 파일 경로")
    parser.add_argument("--daily", dest="csv_daily", default=None,
                        help="일봉 OHLCV CSV (매물대/VWAP/다이버전스 분석용, 선택)")
    args = parser.parse_args()

    analyze_timeframe(args.csv_1h, "1시간봉")
    print()
    analyze_timeframe(args.csv_15m, "15분봉")

    if args.csv_daily:
        analyze_volume_profile(args.csv_daily)


if __name__ == "__main__":
    main()
