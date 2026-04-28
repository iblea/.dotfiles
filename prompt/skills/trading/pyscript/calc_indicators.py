#!/usr/bin/env python3
"""CSV 파일 또는 웹 API에서 OHLCV 데이터를 읽어 보조지표 분석

Usage:
    python calc_indicators.py <csv_path>
    python calc_indicators.py <symbol> <exchange> <interval> [count]
"""

import io
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

import pandas as pd
import numpy as np

from indicators import (
    calc_rsi, calc_macd, calc_stochastic, calc_bollinger,
    calc_atr, calc_dmi, add_moving_averages, print_ma_line,
    get_ma_phase, get_macd_phase, calc_phase_distance,
    analyze_phase_stability, calc_ichimoku,
)

API_URL = "https://stock.iasdf.com/tradingview/detailcsv"

INTERVAL_LABELS = {
    '1': '1분봉', '3': '3분봉', '5': '5분봉',
    '15': '15분봉', '30': '30분봉',
    '60': '1시간봉', '120': '2시간봉', '240': '4시간봉',
    'D': '일봉', '1D': '일봉',
    'W': '주봉', '1W': '주봉',
    'M': '월봉', '1M': '월봉',
}

DAILY_INTERVALS = ('D', '1D', 'W', '1W', 'M', '1M')


def parse_csv_text(text):
    """sample.csv 포맷 문자열을 파싱하여 (symbol, exchange, interval, df) 반환

    1번째 라인: symbol,exchange,interval,count
    2번째 라인: time,open,high,low,close,volume (헤더)
    3번째 라인~: OHLCV 데이터 (최신 순)
    """
    lines = text.strip().splitlines()
    if len(lines) < 3:
        print(f"[ERROR] CSV 데이터 부족 (라인 {len(lines)}개)")
        sys.exit(1)

    meta = [x.strip() for x in lines[0].split(',')]
    if len(meta) < 3:
        print(f"[ERROR] CSV 메타 정보 형식 오류: {lines[0]!r}")
        sys.exit(1)
    symbol, exchange, interval = meta[0], meta[1], meta[2]

    data_text = "\n".join(lines[1:])
    df = pd.read_csv(io.StringIO(data_text))

    if df.empty:
        print(f"[ERROR] OHLCV 데이터 없음: {symbol} / {exchange} / {interval}")
        sys.exit(1)

    if 'time' in df.columns:
        df.rename(columns={'time': 'datetime'}, inplace=True)

    df['datetime'] = pd.to_datetime(df['datetime'])
    df = df.sort_values('datetime').reset_index(drop=True)
    df.set_index('datetime', inplace=True)

    for col in ['open', 'high', 'low', 'close', 'volume']:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    return symbol, exchange, interval, df


def fetch_from_file(csv_path):
    """CSV 파일에서 OHLCV 데이터를 읽어 (symbol, exchange, interval, df) 반환"""
    if not os.path.exists(csv_path):
        print(f"[ERROR] 파일 없음: {csv_path}")
        sys.exit(1)
    with open(csv_path, encoding='utf-8') as f:
        text = f.read()
    return parse_csv_text(text)


def fetch_from_web(symbol, exchange, interval, count):
    """웹 API에서 OHLCV 데이터를 받아 (symbol, exchange, interval, df) 반환"""
    params = urllib.parse.urlencode({
        'symbol': symbol,
        'exchange': exchange,
        'interval': interval,
        'count': count,
    })
    url = f"{API_URL}?{params}"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            text = resp.read().decode('utf-8')
    except urllib.error.URLError as e:
        print(f"[ERROR] API 요청 실패: {url} -> {e}")
        sys.exit(1)
    return parse_csv_text(text)


def fmt_date(idx, interval):
    """interval에 따라 날짜 포맷 결정"""
    if interval in DAILY_INTERVALS:
        return idx.strftime('%Y-%m-%d')
    return idx.strftime('%Y-%m-%d %H:%M')


def section_moving_averages(df, latest, prev):
    """이동평균선 섹션"""
    print(f"\n[이동평균선]")
    chg = latest['close'] - prev['close']
    pct = (latest['close'] / prev['close'] - 1) * 100
    print(f"  현재가: {latest['close']:.2f} (전봉대비: {chg:+.2f}, {pct:+.2f}%)")
    for p in [5, 10, 20, 40, 50, 60, 120, 200]:
        col = f'MA{p}'
        if col in df.columns and pd.notna(latest.get(col, np.nan)):
            print_ma_line(f"MA{p}", latest[col], latest['close'])


def section_rsi(df):
    """RSI 섹션"""
    df['RSI14'] = calc_rsi(df['close'], 14)
    df['RSI9'] = calc_rsi(df['close'], 9)
    rsi14 = df['RSI14'].iloc[-1]
    rsi14_prev = df['RSI14'].iloc[-2]
    rsi9 = df['RSI9'].iloc[-1]
    rsi9_prev = df['RSI9'].iloc[-2]

    print(f"\n[RSI]")
    print(f"  RSI(14): {rsi14:.2f}  (전봉: {rsi14_prev:.2f})")
    print(f"  RSI(9):  {rsi9:.2f}  (전봉: {rsi9_prev:.2f})")
    if rsi14 > 70:
        print(f"  -> 과매수 구간")
    elif rsi14 < 30:
        print(f"  -> 과매도 구간")


def section_macd(df):
    """MACD 섹션"""
    macd, signal, hist = calc_macd(df['close'])
    print(f"\n[MACD (12,26,9)]")
    print(f"  MACD:   {macd.iloc[-1]:.4f}  (전봉: {macd.iloc[-2]:.4f})")
    print(f"  Signal: {signal.iloc[-1]:.4f}  (전봉: {signal.iloc[-2]:.4f})")
    print(f"  Hist:   {hist.iloc[-1]:.4f}  (전봉: {hist.iloc[-2]:.4f})")

    if macd.iloc[-1] > signal.iloc[-1]:
        print(f"  -> MACD > Signal (매수 신호)")
    else:
        print(f"  -> MACD < Signal (매도 신호)")

    if macd.iloc[-2] <= signal.iloc[-2] and macd.iloc[-1] > signal.iloc[-1]:
        print(f"  ** 골든크로스 발생 **")
    elif macd.iloc[-2] >= signal.iloc[-2] and macd.iloc[-1] < signal.iloc[-1]:
        print(f"  ** 데드크로스 발생 **")


def section_stochastic(df):
    """스토캐스틱 섹션"""
    k, d = calc_stochastic(df)
    print(f"\n[스토캐스틱 (14,3)]")
    print(f"  %K: {k.iloc[-1]:.2f}  (전봉: {k.iloc[-2]:.2f})")
    print(f"  %D: {d.iloc[-1]:.2f}  (전봉: {d.iloc[-2]:.2f})")
    if k.iloc[-1] > 80:
        print(f"  -> 과매수 구간")
    elif k.iloc[-1] < 20:
        print(f"  -> 과매도 구간")


def section_bollinger(df, latest):
    """볼린저밴드 섹션"""
    bb_mid, bb_upper, bb_lower, bb_pct_b = calc_bollinger(df['close'])
    print(f"\n[볼린저밴드 (20,2)]")
    print(f"  상단: {bb_upper.iloc[-1]:.2f}")
    print(f"  중단: {bb_mid.iloc[-1]:.2f}")
    print(f"  하단: {bb_lower.iloc[-1]:.2f}")

    if pd.notna(bb_mid.iloc[-1]) and bb_mid.iloc[-1] != 0:
        bb_width = bb_upper.iloc[-1] - bb_lower.iloc[-1]
        print(f"  밴드폭: {bb_width:.2f} ({bb_width / bb_mid.iloc[-1] * 100:.1f}%)")

    pct_b_now = bb_pct_b.iloc[-1]
    if pd.notna(pct_b_now):
        print(f"  %b: {pct_b_now:.3f}")
        if pct_b_now > 1.0:
            print(f"  -> 상단 돌파 (과매수 가능)")
        elif pct_b_now >= 0.8:
            print(f"  -> 상단 근접 (과매수 주의)")
        elif pct_b_now < 0.0:
            print(f"  -> 하단 이탈 (과매도 가능)")
        elif pct_b_now <= 0.2:
            print(f"  -> 하단 근접 (과매도 주의)")


def section_atr(df, latest):
    """ATR 섹션"""
    df['ATR14'] = calc_atr(df, 14)
    atr = df['ATR14'].iloc[-1]
    if pd.notna(atr):
        print(f"\n[ATR (변동성)]")
        print(f"  ATR(14): {atr:.2f}")
        print(f"  ATR/현재가: {atr / latest['close'] * 100:.2f}%")


def section_volume(df, latest):
    """거래량 섹션"""
    avg_vol_20 = df['volume'].rolling(20).mean().iloc[-1]
    print(f"\n[거래량]")
    print(f"  최근 거래량: {latest['volume']:,.0f}")
    if pd.notna(avg_vol_20) and avg_vol_20 > 0:
        print(f"  20봉 평균:   {avg_vol_20:,.0f}")
        print(f"  비율: {latest['volume'] / avg_vol_20 * 100:.1f}%")


def section_pivot(latest):
    """피봇 포인트 섹션"""
    pivot = (latest['high'] + latest['low'] + latest['close']) / 3
    r1 = 2 * pivot - latest['low']
    s1 = 2 * pivot - latest['high']
    r2 = pivot + (latest['high'] - latest['low'])
    s2 = pivot - (latest['high'] - latest['low'])
    print(f"\n[피봇 포인트]")
    print(f"  R2:    {r2:.2f}")
    print(f"  R1:    {r1:.2f}")
    print(f"  Pivot: {pivot:.2f}")
    print(f"  S1:    {s1:.2f}")
    print(f"  S2:    {s2:.2f}")


def section_fibonacci(df, latest):
    """피보나치 되돌림 섹션"""
    n = min(30, len(df))
    tail = df.tail(n)
    recent_low = tail['low'].min()
    recent_high = tail['high'].max()
    fib_range = recent_high - recent_low
    if fib_range <= 0:
        return
    print(f"\n[피보나치 되돌림 (최근 {n}봉: {recent_low:.2f} ~ {recent_high:.2f})]")
    for level in [0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0]:
        price = recent_high - fib_range * level
        marker = " << 현재가" if abs(price - latest['close']) < fib_range * 0.03 + 0.01 else ""
        print(f"  {level * 100:5.1f}%: {price:.2f}{marker}")


def _collect_ma_phases(df, n=10):
    """최근 n봉의 MA Phase 이력 수집"""
    phases = []
    start = max(0, len(df) - n)
    for i in range(start, len(df)):
        row = df.iloc[i]
        m5 = row.get('MA5', np.nan)
        m20 = row.get('MA20', np.nan)
        m40 = row.get('MA40', np.nan)
        if pd.notna(m5) and pd.notna(m20) and pd.notna(m40):
            p, _ = get_ma_phase(m5, m20, m40)
            phases.append(p)
        else:
            phases.append(None)
    return phases


def section_ma_phase(df, latest):
    """MA Phase 섹션 (MA5/MA20/MA40 기반 추세 단계)"""
    ma5 = latest.get('MA5', np.nan)
    ma20 = latest.get('MA20', np.nan)
    ma40 = latest.get('MA40', np.nan)

    print(f"\n[MA Phase (MA5/MA20/MA40)]")
    if not (pd.notna(ma5) and pd.notna(ma20) and pd.notna(ma40)):
        print(f"  데이터 부족 (MA40 계산에 최소 40개 필요)")
        return

    print(f"  MA5(단):  {ma5:.2f}")
    print(f"  MA20(중): {ma20:.2f}")
    print(f"  MA40(장): {ma40:.2f}")
    phase, desc = get_ma_phase(ma5, ma20, ma40)
    print(f"  >> {desc}")

    # 전봉 대비 Phase 전환 + 거리
    if len(df) >= 2:
        prev = df.iloc[-2]
        p_ma5 = prev.get('MA5', np.nan)
        p_ma20 = prev.get('MA20', np.nan)
        p_ma40 = prev.get('MA40', np.nan)
        if pd.notna(p_ma5) and pd.notna(p_ma20) and pd.notna(p_ma40):
            prev_phase, _ = get_ma_phase(p_ma5, p_ma20, p_ma40)
            if prev_phase != phase:
                dist = calc_phase_distance(prev_phase, phase)
                print(f"  ** Phase 전환: {prev_phase} -> {phase} (거리: {dist}) **")
                if dist is not None and dist >= 3:
                    print(f"  !! 급변 (정반대 Phase) - 급격한 악재/호재 또는 노이즈 가능 !!")
                elif dist is not None and dist >= 2:
                    print(f"  ! 빠른 전환 (1단계 건너뜀) !")

    # 최근 10봉 Phase 이력 + 안정성 분석
    phases = _collect_ma_phases(df, 10)
    valid = [p for p in phases if p is not None]
    if len(valid) >= 2:
        trail = " -> ".join(str(p) for p in valid)
        print(f"  최근 이력: [{trail}]")
        for level, msg in analyze_phase_stability(phases):
            if level == 'critical':
                print(f"  !! {msg} !!")
            elif level == 'warn':
                print(f"  ! {msg} !")
            else:
                print(f"  {msg}")

    # MA 기울기
    if len(df) >= 5 and 'MA5' in df.columns and pd.notna(df['MA5'].iloc[-3]):
        ma5_slope = (df['MA5'].iloc[-1] - df['MA5'].iloc[-3]) / 2
        print(f"  MA5 기울기: {ma5_slope:+.4f}")
    if len(df) >= 25 and 'MA20' in df.columns and pd.notna(df['MA20'].iloc[-5]):
        ma20_slope = (df['MA20'].iloc[-1] - df['MA20'].iloc[-5]) / 4
        print(f"  MA20 기울기: {ma20_slope:+.4f}")


def section_macd_phase(df):
    """MACD Phase 섹션 (MACD 5/20/40 기반 선행 추세 단계)"""
    # 단기 MACD (5-20)
    macd_s, sig_s, hist_s = calc_macd(df['close'], fast=5, slow=20, signal=9)
    # 중기 MACD (5-40)
    macd_m, sig_m, hist_m = calc_macd(df['close'], fast=5, slow=40, signal=9)
    # 장기 MACD (20-40)
    macd_l, sig_l, hist_l = calc_macd(df['close'], fast=20, slow=40, signal=9)

    print(f"\n[MACD Phase (5/20/40)]")
    print(f"  단기 MACD(5,20,9):  Hist {hist_s.iloc[-1]:+.4f}  {'L' if hist_s.iloc[-1] > 0 else 'S'}")
    print(f"  중기 MACD(5,40,9):  Hist {hist_m.iloc[-1]:+.4f}  {'L' if hist_m.iloc[-1] > 0 else 'S'}")
    print(f"  장기 MACD(20,40,9): Hist {hist_l.iloc[-1]:+.4f}  {'L' if hist_l.iloc[-1] > 0 else 'S'}")

    phase, desc = get_macd_phase(hist_s.iloc[-1], hist_m.iloc[-1], hist_l.iloc[-1])
    print(f"  >> {desc}")

    # 전봉 대비 Phase 전환 + 거리
    if len(df) >= 2:
        prev_phase, _ = get_macd_phase(hist_s.iloc[-2], hist_m.iloc[-2], hist_l.iloc[-2])
        if prev_phase != phase:
            dist = calc_phase_distance(prev_phase, phase)
            print(f"  ** Phase 전환: {prev_phase} -> {phase} (거리: {dist}) **")
            if dist is not None and dist >= 3:
                print(f"  !! 급변 - 급격한 악재/호재 또는 횡보 노이즈 가능 !!")
            elif dist is not None and dist >= 2:
                print(f"  ! 빠른 전환 (1단계 건너뜀) !")

    # 최근 10봉 MACD Phase 이력 + 안정성 분석
    n = min(10, len(df))
    macd_phases = []
    for i in range(len(df) - n, len(df)):
        p, _ = get_macd_phase(hist_s.iloc[i], hist_m.iloc[i], hist_l.iloc[i])
        macd_phases.append(p)
    valid = [p for p in macd_phases if p is not None]
    if len(valid) >= 2:
        trail = " -> ".join(str(p) if p is not None else "?" for p in valid)
        print(f"  최근 이력: [{trail}]")
        for level, msg in analyze_phase_stability(macd_phases):
            if level == 'critical':
                print(f"  !! {msg} !!")
            elif level == 'warn':
                print(f"  ! {msg} !")
            else:
                print(f"  {msg}")


def section_ichimoku(df, latest):
    """일목균형표 섹션"""
    DISP = 26
    if len(df) < 52 + DISP:
        print(f"\n[일목균형표]")
        print(f"  데이터 부족 (최소 {52 + DISP}개 필요, 현재 {len(df)}개)")
        return

    tenkan, kijun, senkou_a, senkou_b, chikou = calc_ichimoku(df)
    close = latest['close']

    tenkan_now = tenkan.iloc[-1]
    kijun_now = kijun.iloc[-1]
    sa_now = senkou_a.iloc[-1]
    sb_now = senkou_b.iloc[-1]

    print(f"\n[일목균형표 (9,26,52)]")
    print(f"  전환선:   {tenkan_now:.2f}")
    print(f"  기준선:   {kijun_now:.2f}")
    print(f"  선행스팬1: {sa_now:.2f}")
    print(f"  선행스팬2: {sb_now:.2f}")

    # ── 1) 후행스팬 분석 (최우선) ──
    print(f"\n  [후행스팬 분석] (우선 신호)")
    # 후행스팬 = 현재 종가를 26봉 전에 표시
    # → 현재 종가 vs 26봉 전 종가로 비교
    if len(df) > DISP:
        past_close = df['close'].iloc[-1 - DISP]
        diff = close - past_close
        diff_pct = diff / past_close * 100
        print(f"  현재 종가:    {close:.2f}")
        print(f"  {DISP}봉전 종가: {past_close:.2f}  (차이: {diff:+.2f}, {diff_pct:+.2f}%)")
        if close > past_close:
            print(f"  >> 후행스팬 상향돌파 (강세)")
        elif close < past_close:
            print(f"  >> 후행스팬 하향돌파 (약세)")
        else:
            print(f"  >> 후행스팬 = 과거 주가 (중립)")

        # 직전 봉의 후행스팬 상태 비교로 전환 감지
        if len(df) > DISP + 1:
            prev_close = df['close'].iloc[-2]
            prev_past = df['close'].iloc[-2 - DISP]
            prev_above = prev_close > prev_past
            curr_above = close > past_close
            if not prev_above and curr_above:
                print(f"  ** 후행스팬 상향돌파 전환 (매수 신호) **")
            elif prev_above and not curr_above:
                print(f"  ** 후행스팬 하향돌파 전환 (매도 신호) **")

    # ── 2) 구름대 분석 (선행스팬) ──
    print(f"\n  [구름대 분석]")
    if pd.notna(sa_now) and pd.notna(sb_now):
        cloud_top = max(sa_now, sb_now)
        cloud_bottom = min(sa_now, sb_now)
        cloud_thickness = cloud_top - cloud_bottom
        cloud_pct = cloud_thickness / close * 100

        # 양구름/음구름
        if sa_now > sb_now:
            print(f"  구름: 양운 (선행1 > 선행2)")
        elif sa_now < sb_now:
            print(f"  구름: 음운 (선행1 < 선행2)")
        else:
            print(f"  구름: 꼬임 (선행1 = 선행2)")

        # 구름 두께
        print(f"  구름 상단: {cloud_top:.2f}")
        print(f"  구름 하단: {cloud_bottom:.2f}")
        print(f"  구름 두께: {cloud_thickness:.2f} ({cloud_pct:.2f}%)")
        if cloud_pct > 1.0:
            print(f"  -> 두꺼운 구름 (강한 추세/강한 지지저항)")
        elif cloud_pct > 0.3:
            print(f"  -> 보통 구름")
        else:
            print(f"  -> 얇은 구름 (약한 추세/횡보 가능)")

        # 현재가 vs 구름대
        if close > cloud_top:
            print(f"  >> 주가 구름대 위 (강세)")
        elif close < cloud_bottom:
            print(f"  >> 주가 구름대 아래 (약세)")
        else:
            pos_in_cloud = (close - cloud_bottom) / cloud_thickness * 100 if cloud_thickness > 0 else 50
            print(f"  >> 주가 구름대 안 (중립, 구름 내 위치 {pos_in_cloud:.0f}%)")

        # 구름대 돌파 전환 감지
        if len(df) >= 2:
            sa_prev = senkou_a.iloc[-2]
            sb_prev = senkou_b.iloc[-2]
            if pd.notna(sa_prev) and pd.notna(sb_prev):
                prev_top = max(sa_prev, sb_prev)
                prev_bottom = min(sa_prev, sb_prev)
                prev_close = df['close'].iloc[-2]
                if prev_close <= prev_top and close > cloud_top:
                    print(f"  ** 구름대 상향 돌파 (매수 신호) **")
                elif prev_close >= prev_bottom and close < cloud_bottom:
                    print(f"  ** 구름대 하향 돌파 (매도 신호) **")

    # ── 3) 전환선/기준선 분석 ──
    print(f"\n  [전환선/기준선]")
    if pd.notna(tenkan_now) and pd.notna(kijun_now):
        diff_tk = tenkan_now - kijun_now
        print(f"  전환선 - 기준선: {diff_tk:+.2f}")
        if tenkan_now > kijun_now:
            print(f"  >> 전환선 > 기준선 (강세)")
        elif tenkan_now < kijun_now:
            print(f"  >> 전환선 < 기준선 (약세)")
        else:
            print(f"  >> 전환선 = 기준선 (중립)")

        # 크로스 감지
        if len(df) >= 2:
            tenkan_prev = tenkan.iloc[-2]
            kijun_prev = kijun.iloc[-2]
            if pd.notna(tenkan_prev) and pd.notna(kijun_prev):
                if tenkan_prev <= kijun_prev and tenkan_now > kijun_now:
                    print(f"  ** 전환선 상향돌파 (호전 - 매수 신호) **")
                elif tenkan_prev >= kijun_prev and tenkan_now < kijun_now:
                    print(f"  ** 전환선 하향돌파 (역전 - 매도 신호) **")

    # ── 종합 ──
    print(f"\n  [일목 종합]")
    signals = []
    # 후행스팬 (우선)
    if len(df) > DISP:
        past_close = df['close'].iloc[-1 - DISP]
        if close > past_close:
            signals.append(("후행스팬", "강세"))
        else:
            signals.append(("후행스팬", "약세"))
    # 구름대
    if pd.notna(sa_now) and pd.notna(sb_now):
        cloud_top = max(sa_now, sb_now)
        cloud_bottom = min(sa_now, sb_now)
        if close > cloud_top:
            signals.append(("구름대", "강세"))
        elif close < cloud_bottom:
            signals.append(("구름대", "약세"))
        else:
            signals.append(("구름대", "중립"))
    # 전환선/기준선
    if pd.notna(tenkan_now) and pd.notna(kijun_now):
        if tenkan_now > kijun_now:
            signals.append(("전환/기준", "강세"))
        elif tenkan_now < kijun_now:
            signals.append(("전환/기준", "약세"))
        else:
            signals.append(("전환/기준", "중립"))

    bullish = sum(1 for _, s in signals if s == "강세")
    bearish = sum(1 for _, s in signals if s == "약세")
    for name, sig in signals:
        mark = "▲" if sig == "강세" else ("▼" if sig == "약세" else "─")
        print(f"  {mark} {name}: {sig}")
    if bullish == 3:
        print(f"  >> 삼역호전 (강한 매수)")
    elif bearish == 3:
        print(f"  >> 삼역역전 (강한 매도)")
    elif bullish > bearish:
        print(f"  >> 매수 우위 ({bullish}/{len(signals)})")
    elif bearish > bullish:
        print(f"  >> 매도 우위 ({bearish}/{len(signals)})")
    else:
        print(f"  >> 혼조 (관망)")


def section_trend_strength(df, latest):
    """추세/횡보 판별 섹션 (DMI + BB Bandwidth)"""
    print(f"\n[추세/횡보 판별 (DMI + BB Bandwidth)]")

    # ── DMI ──
    plus_di, minus_di, adx = calc_dmi(df)
    di_p = plus_di.iloc[-1]
    di_m = minus_di.iloc[-1]
    adx_now = adx.iloc[-1]

    print(f"\n  [DMI (14)]")
    print(f"  DI+: {di_p:.2f}   DI-: {di_m:.2f}   ADX: {adx_now:.2f}")

    # ADX 과거 비교
    if len(df) >= 10 and pd.notna(adx.iloc[-6]):
        adx_5ago = adx.iloc[-6]
        adx_chg = adx_now - adx_5ago
        print(f"  ADX 5봉전: {adx_5ago:.2f}  (변화: {adx_chg:+.2f})")
        if adx_chg > 2:
            print(f"  -> ADX 상승 중 (추세 강화)")
        elif adx_chg < -2:
            print(f"  -> ADX 하락 중 (추세 약화)")

    # DI 크로스 감지
    if len(df) >= 2:
        prev_di_p = plus_di.iloc[-2]
        prev_di_m = minus_di.iloc[-2]
        if pd.notna(prev_di_p) and pd.notna(prev_di_m):
            if prev_di_p <= prev_di_m and di_p > di_m:
                print(f"  ** DI+ 상향돌파 (매수 신호) **")
            elif prev_di_p >= prev_di_m and di_p < di_m:
                print(f"  ** DI- 상향돌파 (매도 신호) **")

    # ── BB Bandwidth ──
    bb_mid, bb_upper, bb_lower, _ = calc_bollinger(df['close'])
    bw = (bb_upper - bb_lower) / bb_mid * 100
    bw_now = bw.iloc[-1]
    bw_avg = bw.rolling(20).mean().iloc[-1]

    print(f"\n  [BB Bandwidth (20,2)]")
    print(f"  현재 밴드폭: {bw_now:.3f}%")
    if pd.notna(bw_avg):
        bw_ratio = bw_now / bw_avg
        print(f"  20봉 평균:   {bw_avg:.3f}%  (비율: {bw_ratio:.2f}x)")
        if bw_ratio > 1.5:
            print(f"  -> 밴드 급확대 (변동성 폭발)")
        elif bw_ratio > 1.0:
            print(f"  -> 밴드 확대 (변동성 증가)")
        elif bw_ratio > 0.7:
            print(f"  -> 밴드 수축 (변동성 감소)")
        else:
            print(f"  -> 밴드 급수축 - Squeeze (돌파 임박 가능)")

    # ── 종합 판별 ──
    print(f"\n  [종합 판별]")

    # 추세 강도
    if adx_now > 25:
        trend_label = "추세장"
        if adx_now > 40:
            trend_label = "강한 추세장"
    elif adx_now > 20:
        trend_label = "약한 추세/전환 구간"
    else:
        trend_label = "횡보장"

    # 추세 방향
    if di_p > di_m:
        dir_label = "상승"
        dir_mark = "▲"
    elif di_m > di_p:
        dir_label = "하락"
        dir_mark = "▼"
    else:
        dir_label = "중립"
        dir_mark = "─"

    # BB로 보조 확인
    bb_expanding = pd.notna(bw_avg) and bw_now > bw_avg

    if adx_now > 25:
        if bb_expanding:
            print(f"  {dir_mark} {trend_label} + 밴드 확대 → {dir_label} 추세 진행 중")
        else:
            print(f"  {dir_mark} {trend_label} + 밴드 수축 → {dir_label} 추세이나 모멘텀 약화")
    elif adx_now > 20:
        if bb_expanding:
            print(f"  {dir_mark} {trend_label} + 밴드 확대 → {dir_label} 방향 추세 형성 가능")
        else:
            print(f"  ─ {trend_label} + 밴드 수축 → 방향 탐색 중")
    else:
        if bb_expanding:
            print(f"  ─ {trend_label} + 밴드 확대 → 횡보 중 변동성 증가 (방향 탐색)")
        else:
            print(f"  ─ {trend_label} + 밴드 수축 → 수렴 중 (Squeeze, 돌파 대기)")

    # DI 차이로 추세 방향 확신도
    di_diff = abs(di_p - di_m)
    if adx_now > 25 and di_diff > 15:
        print(f"  DI 차이: {di_diff:.1f} (방향성 강함)")
    elif adx_now > 25 and di_diff < 5:
        print(f"  DI 차이: {di_diff:.1f} (방향성 불명확, 추세 전환 가능)")


def section_candle(df, interval):
    """최근 캔들 패턴 섹션"""
    print(f"\n[최근 캔들 패턴]")
    for i in [-3, -2, -1]:
        if abs(i) > len(df):
            continue
        row = df.iloc[i]
        body = row['close'] - row['open']
        body_size = abs(body)
        total_range = row['high'] - row['low']

        date_str = fmt_date(df.index[i], interval)
        candle_type = "양봉" if body > 0 else "음봉"

        pattern = ""
        if total_range > 0:
            lower_wick = min(row['open'], row['close']) - row['low']
            upper_wick = row['high'] - max(row['open'], row['close'])
            if body_size < total_range * 0.1:
                pattern = "도지 (Doji)"
            elif body < 0 and lower_wick > body_size * 2:
                pattern = "망치형 (Hammer)"
            elif body > 0 and upper_wick > body_size * 2:
                pattern = "역망치형"
            elif body < 0 and body_size > total_range * 0.6:
                pattern = "장대음봉"
            elif body > 0 and body_size > total_range * 0.6:
                pattern = "장대양봉"

        print(f"  {date_str}: {candle_type} O:{row['open']:.2f} H:{row['high']:.2f} "
              f"L:{row['low']:.2f} C:{row['close']:.2f} V:{row['volume']:,.0f}")
        if pattern:
            print(f"    -> {pattern}")


def analyze(df, symbol, interval):
    tf_label = INTERVAL_LABELS.get(interval, f'{interval}봉')

    if len(df) < 2:
        print("[ERROR] 데이터가 2개 미만")
        return

    if len(df) < 200:
        print(f"[WARN] 데이터 {len(df)}개 - 일부 장기 지표 계산이 부정확할 수 있음")

    df = add_moving_averages(df)
    latest = df.iloc[-1]
    prev = df.iloc[-2]

    print("=" * 70)
    print(f"  {symbol} {tf_label} 기술적 분석")
    print("=" * 70)
    print(f"  기간: {fmt_date(df.index[0], interval)} ~ {fmt_date(df.index[-1], interval)} ({len(df)}개)")

    section_moving_averages(df, latest, prev)
    section_rsi(df)
    section_macd(df)
    section_stochastic(df)
    section_bollinger(df, latest)
    section_atr(df, latest)
    section_volume(df, latest)
    section_pivot(latest)
    section_fibonacci(df, latest)
    section_ichimoku(df, latest)
    section_ma_phase(df, latest)
    section_macd_phase(df)
    section_trend_strength(df, latest)
    section_candle(df, interval)


def main():
    argc = len(sys.argv)
    prog = sys.argv[0]

    if argc == 2:
        csv_path = sys.argv[1]
        symbol, exchange, interval, df = fetch_from_file(csv_path)
    elif argc in (4, 5):
        symbol = sys.argv[1]
        exchange = sys.argv[2]
        interval = sys.argv[3]
        count = int(sys.argv[4]) if argc == 5 else 500
        symbol, exchange, interval, df = fetch_from_web(symbol, exchange, interval, count)
    else:
        print("Usage:")
        print(f"  python {prog} <csv_path>")
        print(f"  python {prog} <symbol> <exchange> <interval> [count]")
        sys.exit(1)

    analyze(df, symbol, interval)


if __name__ == "__main__":
    main()
