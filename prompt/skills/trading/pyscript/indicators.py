"""기술적 분석 공통 보조지표 모듈"""

import pandas as pd
import numpy as np


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
    percent_b = (series - lower) / (upper - lower)
    return sma, upper, lower, percent_b


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
        periods = [5, 10, 20, 40, 50, 60, 120, 200]
    for p in periods:
        if len(df) >= p:
            df[f'MA{p}'] = df['close'].rolling(window=p).mean()
    return df


def print_ma_line(label, ma_val, close, width=7):
    arrow = '▲' if close > ma_val else '▼'
    diff_pct = (close / ma_val - 1) * 100
    print(f"  {label:<{width}}: {ma_val:.2f}  {arrow} ({diff_pct:+.2f}%)")


def calc_dmi(df, period=14):
    """DMI (Directional Movement Index) 계산
    Returns: plus_di, minus_di, adx
    """
    high = df['high']
    low = df['low']
    close = df['close']

    up_move = high.diff()
    down_move = -low.diff()

    plus_dm = pd.Series(
        np.where((up_move > down_move) & (up_move > 0), up_move, 0.0),
        index=df.index,
    )
    minus_dm = pd.Series(
        np.where((down_move > up_move) & (down_move > 0), down_move, 0.0),
        index=df.index,
    )

    tr = np.maximum(
        high - low,
        np.maximum(abs(high - close.shift(1)), abs(low - close.shift(1)))
    )

    # Wilder smoothing (alpha=1/period)
    atr_s = tr.ewm(alpha=1 / period, adjust=False).mean()
    smooth_plus = plus_dm.ewm(alpha=1 / period, adjust=False).mean()
    smooth_minus = minus_dm.ewm(alpha=1 / period, adjust=False).mean()

    plus_di = 100 * smooth_plus / atr_s
    minus_di = 100 * smooth_minus / atr_s

    dx = 100 * abs(plus_di - minus_di) / (plus_di + minus_di)
    adx = dx.ewm(alpha=1 / period, adjust=False).mean()

    return plus_di, minus_di, adx


def calc_ichimoku(df, tenkan_p=9, kijun_p=26, senkou_b_p=52, displacement=26):
    """일목균형표 계산
    Returns: tenkan, kijun, senkou_a, senkou_b, chikou
    - tenkan: 전환선 (9봉 고저 중간값)
    - kijun: 기준선 (26봉 고저 중간값)
    - senkou_a: 선행스팬1 ((전환선+기준선)/2, 26봉 선행)
    - senkou_b: 선행스팬2 (52봉 고저 중간값, 26봉 선행)
    - chikou: 후행스팬 (종가를 26봉 후행)
    """
    tenkan = (df['high'].rolling(tenkan_p).max() + df['low'].rolling(tenkan_p).min()) / 2
    kijun = (df['high'].rolling(kijun_p).max() + df['low'].rolling(kijun_p).min()) / 2
    senkou_a = ((tenkan + kijun) / 2).shift(displacement)
    senkou_b = ((df['high'].rolling(senkou_b_p).max() + df['low'].rolling(senkou_b_p).min()) / 2).shift(displacement)
    chikou = df['close'].shift(-displacement)
    return tenkan, kijun, senkou_a, senkou_b, chikou


MA_PHASE_TABLE = {
    # (단>중, 단>장, 중>장) -> (phase, label)
    (True,  True,  False): (0, "Phase 0: 상승기 시작 (단>장>중)"),
    (True,  True,  True):  (1, "Phase 1: 상승기 - 정배열 (단>중>장)"),
    (False, True,  True):  (2, "Phase 2: 상승기 마무리 (중>단>장)"),
    (False, False, True):  (3, "Phase 3: 하락기 시작 (중>장>단)"),
    (False, False, False): (4, "Phase 4: 하락기 - 역배열 (장>중>단)"),
    (True,  False, False): (5, "Phase 5: 하락기 마무리 (장>단>중)"),
}


def get_ma_phase(ma5, ma20, ma40):
    """MA5/MA20/MA40 기반 MA Phase 판별
    Returns: (phase_number, description) or (None, description)
    """
    key = (ma5 > ma20, ma5 > ma40, ma20 > ma40)
    if key in MA_PHASE_TABLE:
        return MA_PHASE_TABLE[key]
    return (None, "판별 불가")


MACD_PHASE_TABLE = {
    # (단L, 중L, 장L) where L = hist > 0
    (True,  True,  False): (0, "Phase 0: 상승기 시작 (단L 중L 장S)"),
    (True,  True,  True):  (1, "Phase 1: 상승기 (단L 중L 장L)"),
    (False, True,  True):  (2, "Phase 2: 상승기 마무리 (단S 중L 장L)"),
    (False, False, True):  (3, "Phase 3: 하락기 시작 (단S 중S 장L)"),
    (False, False, False): (4, "Phase 4: 하락기 (단S 중S 장S)"),
    (True,  False, False): (5, "Phase 5: 하락기 마무리 (단L 중S 장S)"),
}


def get_macd_phase(hist_short, hist_mid, hist_long):
    """MACD 단기/중기/장기 히스토그램 기반 MACD Phase 판별
    - 단기 MACD: MACD(5, 20, 9)
    - 중기 MACD: MACD(5, 40, 9)
    - 장기 MACD: MACD(20, 40, 9)
    Returns: (phase_number, description) or (None, description)
    """
    key = (hist_short > 0, hist_mid > 0, hist_long > 0)
    if key in MACD_PHASE_TABLE:
        return MACD_PHASE_TABLE[key]
    return (None, "전환 구간")


def calc_phase_distance(prev_phase, curr_phase):
    """Phase 간 순환 거리 계산 (0~3)
    정상 순환: 0→1→2→3→4→5→0
    distance 1: 정상 순환 (인접)
    distance 2: 빠른 전환 (1단계 건너뜀)
    distance 3: 급변 (최대 거리, 정반대 Phase)
    """
    if prev_phase is None or curr_phase is None:
        return None
    fwd = (curr_phase - prev_phase) % 6
    bwd = (prev_phase - curr_phase) % 6
    return min(fwd, bwd)


def analyze_phase_stability(phases):
    """Phase 이력에서 횡보/추세 안정성 분석

    역전환(순환 역방향 이동) 빈도와 추세 Phase(1,4) 도달 여부,
    최근 안정 구간을 종합하여 횡보/추세를 판단한다.

    Args: phases - Phase 번호 리스트 (None 포함 가능)
    Returns: list of (level, message)
        level: 'info', 'warn', 'critical'
    """
    valid = [p for p in phases if p is not None]
    if len(valid) < 4:
        return []

    results = []

    # 1) 역전환 횟수 (순환 역방향 이동)
    # 순방향: (curr - prev) % 6 에서 1~3이면 순방향, 4~5이면 역방향
    reversals = 0
    for i in range(1, len(valid)):
        if valid[i] == valid[i - 1]:
            continue
        fwd = (valid[i] - valid[i - 1]) % 6
        if fwd > 3:
            reversals += 1

    # 2) 추세 확정 Phase(1=정배열 or 4=역배열) 도달 여부
    has_confirmed_trend = any(p in (1, 4) for p in valid)

    # 3) 최근 안정 구간 길이 (마지막부터 같은 Phase 연속)
    stable_len = 1
    for i in range(len(valid) - 2, -1, -1):
        if valid[i] == valid[-1]:
            stable_len += 1
        else:
            break
    current_phase = valid[-1]

    # 판단
    if reversals >= 2 and not has_confirmed_trend:
        # 역전환 빈발 + 추세(1,4) 미도달 → 횡보장
        if stable_len >= 3 and current_phase in (1, 4):
            results.append(('info',
                f"횡보에서 추세 Phase({current_phase}) 진입 - 안정 {stable_len}봉"))
        else:
            results.append(('critical',
                f"횡보장 (역전환 {reversals}회, 추세(1/4) 미도달)"))
    elif reversals >= 2:
        # 역전환 빈발하지만 추세 Phase 도달은 있었음
        if stable_len >= 3:
            results.append(('info',
                f"추세 안정화 (Phase {current_phase} 연속 {stable_len}봉)"))
        else:
            results.append(('warn',
                f"역전환 {reversals}회 - 추세 약화/횡보 전환 가능"))
    else:
        # 역전환 적음 (0~1회) - 정상 순환
        if stable_len >= 3:
            results.append(('info',
                f"추세 안정 (Phase {current_phase} 연속 {stable_len}봉)"))

    return results
