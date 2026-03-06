#!/usr/bin/env python3
"""CSV 데이터 최신 여부 확인

파일명에서 인터벌(15m, 1h, 1d)을 추출하고,
마지막 행의 타임스탬프와 현재 시간을 인터벌 단위로 floor하여 비교.
같으면 최신(FRESH), 다르면 재수집 필요(STALE).

Usage:
    python market_data_recent.py <csv_file> [<csv_file> ...]
    python market_data_recent.py output/NQ1_1d_20260304.csv
    python market_data_recent.py output/NQ1_*.csv

Exit code:
    0 - 모든 파일이 최신
    1 - 재수집이 필요한 파일 있음
    2 - 에러 (파일 없음, 알 수 없는 인터벌 등)
"""

import argparse
import os
import sys
from datetime import datetime

import pandas as pd


INTERVAL_MINUTES = {
    "5m": 5,
    "15m": 15,
    "1h": 60,
    "1d": 1440,
}


def floor_time(dt, interval_minutes):
    """시간을 인터벌 단위로 내림(floor)"""
    if interval_minutes >= 1440:
        return dt.replace(hour=0, minute=0, second=0, microsecond=0)
    total_minutes = dt.hour * 60 + dt.minute
    floored = (total_minutes // interval_minutes) * interval_minutes
    return dt.replace(
        hour=floored // 60,
        minute=floored % 60,
        second=0,
        microsecond=0,
    )


def extract_interval(filepath):
    """파일명에서 인터벌 추출 ({label}_{interval}_{date}.csv)"""
    basename = os.path.basename(filepath).replace(".csv", "")
    parts = basename.split("_")
    if len(parts) >= 3:
        return parts[-2]
    return None


def check_freshness(csv_path, now=None):
    """단일 CSV 파일의 최신 여부 확인.

    Returns:
        (needs_update: bool|None, info: dict)
        needs_update: True=재수집 필요, False=최신, None=판단 불가
    """
    if not os.path.exists(csv_path):
        return True, {"reason": "file not found"}

    interval = extract_interval(csv_path)
    if interval not in INTERVAL_MINUTES:
        return None, {"reason": f"unknown interval '{interval}'"}

    try:
        df = pd.read_csv(csv_path, index_col=0, parse_dates=True)
    except Exception as e:
        return None, {"reason": f"read error: {e}"}

    if df.empty:
        return True, {"reason": "empty file"}

    last_ts = df.index[-1]
    if isinstance(last_ts, pd.Timestamp):
        last_dt = last_ts.to_pydatetime().replace(tzinfo=None)
    else:
        last_dt = pd.to_datetime(last_ts).to_pydatetime().replace(tzinfo=None)

    if now is None:
        now = datetime.now()
    minutes = INTERVAL_MINUTES[interval]
    now_floor = floor_time(now, minutes)
    last_floor = floor_time(last_dt, minutes)

    needs_update = now_floor > last_floor
    return needs_update, {
        "interval": interval,
        "last_data": last_floor.strftime("%Y-%m-%d %H:%M"),
        "now_floor": now_floor.strftime("%Y-%m-%d %H:%M"),
    }


def main():
    parser = argparse.ArgumentParser(description="CSV 데이터 최신 여부 확인")
    parser.add_argument("files", nargs="+", help="확인할 CSV 파일 경로")
    args = parser.parse_args()

    stale = []
    errors = []

    for f in args.files:
        needs_update, info = check_freshness(f)
        basename = os.path.basename(f)

        if needs_update is None:
            print(f"  [SKIP]  {basename} - {info.get('reason', 'unknown')}")
            errors.append(f)
        elif needs_update:
            print(f"  [STALE] {basename} (last: {info['last_data']}, now: {info['now_floor']})")
            stale.append(f)
        else:
            print(f"  [FRESH] {basename} (last: {info['last_data']})")

    total = len(args.files)
    fresh = total - len(stale) - len(errors)
    print(f"\n  total: {total}, fresh: {fresh}, stale: {len(stale)}, skip: {len(errors)}")

    if errors:
        sys.exit(2)
    if stale:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
