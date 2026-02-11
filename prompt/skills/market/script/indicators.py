"""기술적 분석 공통 보조지표 모듈"""

import os
import pandas as pd
import numpy as np


def load_csv(path):
    """CSV 파일을 로드하고, 종목명(label)을 파일명에서 추출"""
    df = pd.read_csv(path, index_col=0, parse_dates=True)
    basename = os.path.basename(path)
    # 파일명 형식: {label}_{interval}_{date}.csv
    parts = basename.replace(".csv", "").split("_")
    label = parts[0] if parts else basename
    return df, label


def calc_rsi(series, period=14):
    delta = series.diff()
    gain = delta.where(delta > 0, 0.0)
    loss = -delta.where(delta < 0, 0.0)
    avg_gain = gain.rolling(window=period).mean()
    avg_loss = loss.rolling(window=period).mean()
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))


def calc_macd(series, fast=12, slow=26, signal=9):
    ema_fast = series.ewm(span=fast, adjust=False).mean()
    ema_slow = series.ewm(span=slow, adjust=False).mean()
    macd_line = ema_fast - ema_slow
    signal_line = macd_line.ewm(span=signal, adjust=False).mean()
    histogram = macd_line - signal_line
    return macd_line, signal_line, histogram


def calc_stochastic(df, k_period=14, d_period=3):
    lowest_low = df['low'].rolling(window=k_period).min()
    highest_high = df['high'].rolling(window=k_period).max()
    k = 100 * (df['close'] - lowest_low) / (highest_high - lowest_low)
    d = k.rolling(window=d_period).mean()
    return k, d


def calc_bollinger(series, period=20, std_dev=2):
    sma = series.rolling(window=period).mean()
    std = series.rolling(window=period).std()
    upper = sma + (std_dev * std)
    lower = sma - (std_dev * std)
    return sma, upper, lower


def calc_atr(df, period=14):
    tr = np.maximum(
        df['high'] - df['low'],
        np.maximum(
            abs(df['high'] - df['close'].shift(1)),
            abs(df['low'] - df['close'].shift(1))
        )
    )
    return tr.rolling(period).mean()


def add_moving_averages(df, periods=None):
    if periods is None:
        periods = [5, 10, 20, 50, 60, 120, 200]
    for p in periods:
        df[f'MA{p}'] = df['close'].rolling(window=p).mean()
    return df


def print_ma_line(label, ma_val, close, width=7):
    arrow = '▲' if close > ma_val else '▼'
    print(f"  {label:<{width}}: {ma_val:.2f}  {arrow}")
