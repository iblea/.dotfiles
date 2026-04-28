#!/usr/bin/env python3
# US100 close-time collector daemon
# 1분마다 API 호출 -> 가장 작은 타임프레임의 close 와 (start_time + 타임프레임 분) 을 파일에 덮어쓰기
# macOS / Linux 호환 (POSIX double-fork)

import atexit
import json
import logging
import os
import signal
import ssl
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta
from logging.handlers import RotatingFileHandler


# === 설정 ===

SYMBOL="US100"
API_URL = "https://stock.iasdf.com/tradingview/recent_data?symbol={}".format(SYMBOL)
INTERVAL_SEC = 60
REQUEST_TIMEOUT = 10
FETCH_AT_SECOND = 8  # 매분 이 초에 fetch (예: 09:00:08, 09:01:08, ...)

# Insecure SSL 컨텍스트 (사용자 요구: --insecure 모드)
# - hostname 검증 OFF
# - 인증서 검증 OFF
SSL_CONTEXT = ssl.create_default_context()
SSL_CONTEXT.check_hostname = False
SSL_CONTEXT.verify_mode = ssl.CERT_NONE

TF_MINUTES = {
    "1": 1,
    "3": 3,
    "5": 5,
    "15": 15,
    "1h": 60,
    "4h": 240,
    "1d": 1440,
}

# --- 이전 설정 (CWD 기반 + ~/.us100_daemon 분리) — fallback 용 보존 ---
# START_CWD = os.getcwd()
# DATA_FILE = os.path.join(START_CWD, "us100.txt")
# META_DIR = os.path.expanduser("~/.us100_daemon")

# 데이터 + 메타파일을 ~/.cache/.stock_realtime_daemon/ 로 통합
META_DIR = os.path.expanduser("~/.cache/.stock_realtime_daemon")
DATA_FILE = os.path.join(META_DIR, "result.txt")
PID_FILE = os.path.join(META_DIR, "daemon.pid")
LOG_FILE = os.path.join(META_DIR, "daemon.log")
HEARTBEAT_FILE = os.path.join(META_DIR, "heartbeat")

os.makedirs(META_DIR, exist_ok=True)


# === 로깅 ===
def setup_logger():
    lg = logging.getLogger("indexrealtimed")
    lg.setLevel(logging.INFO)
    if not lg.handlers:
        handler = RotatingFileHandler(LOG_FILE, maxBytes=1_000_000, backupCount=3)
        handler.setFormatter(
            logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
        )
        lg.addHandler(handler)
    return lg


logger = setup_logger()


# === 핵심 로직 ===
def fetch_and_write():
    try:
        req = urllib.request.Request(
            API_URL, headers={"User-Agent": "indexrealtimed/1.0"}
        )
        with urllib.request.urlopen(
            req, timeout=REQUEST_TIMEOUT, context=SSL_CONTEXT
        ) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        logger.error(f"request failed: {e}")
        return
    except json.JSONDecodeError as e:
        logger.error(f"json parse failed: {e}")
        return

    data = payload.get("data") or {}
    if not data:
        logger.warning("response has no 'data' field")
        return

    symbol_key = next(iter(data))
    symbol_data = data[symbol_key]
    if not isinstance(symbol_data, dict):
        logger.warning(f"unexpected shape for {symbol_key}")
        return

    available = [k for k in symbol_data.keys() if k in TF_MINUTES]
    if not available:
        logger.warning(f"no timeframe keys found for {symbol_key}")
        return

    smallest = min(available, key=lambda k: TF_MINUTES[k])
    minutes = TF_MINUTES[smallest]
    bar = symbol_data[smallest]

    try:
        close = bar["close"]
        start_str = bar["start_time"]
    except (KeyError, TypeError) as e:
        logger.error(f"missing field in bar {smallest}: {e}")
        return

    try:
        start_dt = datetime.fromisoformat(start_str)
    except (ValueError, TypeError) as e:
        logger.error(f"invalid start_time {start_str!r}: {e}")
        return

    update_str = (start_dt + timedelta(minutes=minutes)).isoformat()

    try:
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            f.write(f"{symbol_key}\n")
            f.write(f"{close}\n")
            f.write(f"{update_str}\n")
    except OSError as e:
        logger.error(f"write failed: {e}")
        return

    logger.info(
        f"OK {symbol_key} tf={smallest}({minutes}m) close={close} update={update_str}"
    )


# === 루프 ===
running = True


def _stop(signum, _frame):
    del _frame  # signal handler signature; frame unused
    global running
    running = False
    logger.info(f"signal {signum} received, stopping")


def _seconds_until_next_target():
    # 다음 매분 FETCH_AT_SECOND 초까지 남은 초 (실수)
    now = time.time()
    sec_in_min = now % 60
    if sec_in_min < FETCH_AT_SECOND:
        return FETCH_AT_SECOND - sec_in_min
    return 60 - sec_in_min + FETCH_AT_SECOND


def _write_heartbeat():
    try:
        with open(HEARTBEAT_FILE, "w") as f:
            f.write(str(int(time.time())))
    except OSError:
        pass


def run_loop():
    signal.signal(signal.SIGTERM, _stop)
    signal.signal(signal.SIGINT, _stop)
    logger.info(
        f"daemon started (data file: {DATA_FILE}, "
        f"fetch at :{FETCH_AT_SECOND:02d} every minute)"
    )

    # --- 이전 구현 (직전 fetch 기준 60초 drift 보정) — fallback 보존 ---
    # while running:
    #     loop_start = time.time()
    #     fetch_and_write()
    #     _write_heartbeat()
    #     elapsed = time.time() - loop_start
    #     end = time.time() + max(0, INTERVAL_SEC - elapsed)
    #     while running and time.time() < end:
    #         time.sleep(min(1.0, max(0.0, end - time.time())))

    # 매분 :FETCH_AT_SECOND 시각에 정렬해서 fetch
    while running:
        sleep_for = _seconds_until_next_target()
        end = time.time() + sleep_for
        while running and time.time() < end:
            time.sleep(min(1.0, max(0.0, end - time.time())))
        if not running:
            break

        fetch_and_write()
        _write_heartbeat()

    logger.info("daemon stopped")


# === 데몬화 (POSIX double-fork) ===
def daemonize():
    if os.fork() > 0:
        sys.exit(0)
    os.chdir("/")
    os.setsid()
    os.umask(0)
    if os.fork() > 0:
        sys.exit(0)

    sys.stdout.flush()
    sys.stderr.flush()
    with open("/dev/null", "rb") as f:
        os.dup2(f.fileno(), sys.stdin.fileno())
    with open("/dev/null", "ab") as f:
        os.dup2(f.fileno(), sys.stdout.fileno())
        os.dup2(f.fileno(), sys.stderr.fileno())

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    atexit.register(_remove_pidfile)


def _remove_pidfile():
    try:
        os.remove(PID_FILE)
    except OSError:
        pass


# === 명령 ===
def read_pid():
    try:
        with open(PID_FILE) as f:
            return int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return None


def is_running():
    pid = read_pid()
    if not pid:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def cmd_start():
    if is_running():
        print(f"already running (pid {read_pid()})")
        return
    print(f"starting daemon, data file: {DATA_FILE}")
    daemonize()
    run_loop()


def cmd_stop():
    pid = read_pid()
    if not pid or not is_running():
        print("not running")
        if pid:
            _remove_pidfile()
        return
    try:
        os.kill(pid, signal.SIGTERM)
    except OSError as e:
        print(f"kill failed: {e}")
        return
    for _ in range(50):
        if not is_running():
            break
        time.sleep(0.1)
    print("stopped" if not is_running() else f"still alive (pid {pid})")


def cmd_status():
    if not is_running():
        print("not running")
        return
    pid = read_pid()
    try:
        with open(HEARTBEAT_FILE) as f:
            beat = int(f.read().strip())
        age = int(time.time()) - beat
        health = (
            f"healthy (last beat {age}s ago)"
            if age < INTERVAL_SEC * 2
            else f"STALE ({age}s ago)"
        )
    except (FileNotFoundError, ValueError):
        health = "no heartbeat yet"
    print(f"running (pid {pid}, {health})")


def cmd_run():
    print(f"foreground mode, data file: {DATA_FILE}")
    print("Ctrl+C to stop")
    run_loop()


def cmd_once():
    # 1회 fetch -> result.txt 갱신 -> stdout 출력 -> 종료
    print(f"one-shot fetch -> {DATA_FILE}")
    fetch_and_write()
    if os.path.exists(DATA_FILE):
        print("--- result ---")
        with open(DATA_FILE, encoding="utf-8") as f:
            sys.stdout.write(f.read())
    else:
        print("no result (check log: " + LOG_FILE + ")")
        sys.exit(1)


def usage():
    print(f"usage: {sys.argv[0]} [start|stop|status|run|once]")
    sys.exit(1)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    handlers = {
        "start": cmd_start,
        "stop": cmd_stop,
        "status": cmd_status,
        "run": cmd_run,
        "once": cmd_once,
    }
    if cmd not in handlers:
        usage()
    handlers[cmd]()
