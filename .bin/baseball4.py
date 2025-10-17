#!/usr/bin/env python3
import random
import sys

def generate_number():
    """중복 없는 4자리 랜덤 숫자 생성"""
    digits = random.sample(range(10), 4)
    return ''.join(map(str, digits))

def save_number(number):
    """숫자를 파일에 저장"""
    with open('/tmp/baseball4.txt', 'w') as f:
        f.write(number)

def load_number():
    """파일에서 숫자 로드"""
    with open('/tmp/baseball4.txt', 'r') as f:
        return f.read().strip()

def validate_input(user_input):
    """입력값 유효성 검사"""
    if len(user_input) != 4:
        return False
    if not user_input.isdigit():
        return False
    if len(set(user_input)) != 4:  # 중복 체크
        return False
    return True

def calculate_result(answer, guess):
    """스트라이크와 볼 계산"""
    strikes = sum(1 for i in range(4) if answer[i] == guess[i])
    balls = sum(1 for digit in guess if digit in answer) - strikes
    return strikes, balls

def show_help():
    """도움말 출력"""
    print("=" * 40)
    print("4자리 숫자야구 게임 규칙")
    print("=" * 40)
    print("- 중복되지 않는 4자리 숫자를 맞춰보세요")
    print("- 기회는 9회까지입니다")
    print("- 'gg'를 입력하면 게임을 포기합니다")
    print("- Ctrl+C로 강제 종료할 수 있습니다")
    print("- '--help'를 입력하면 규칙을 다시 볼 수 있습니다")
    print("=" * 40)

def clear_previous_lines(num_lines):
    """이전 줄들을 지우고 커서를 위로 이동"""
    for _ in range(num_lines):
        # 커서를 한 줄 위로 이동
        sys.stdout.write('\033[F')
        # 현재 줄 지우기
        sys.stdout.write('\033[K')
    sys.stdout.flush()

def main():
    # 랜덤 숫자 생성 및 저장
    answer = generate_number()
    save_number(answer)

    turn = 1
    max_turns = 9
    history = []  # 입력 이력 저장
    prev_lines = 0  # 이전에 출력한 줄 수
    tried_numbers = set()  # 시도한 숫자들을 저장

    try:
        while turn <= max_turns:
            # 이전 출력 지우기
            if prev_lines > 0:
                clear_previous_lines(prev_lines)

            # 턴 번호 출력
            print(f"[{turn}]")

            # 이력 출력
            for item in history:
                print(item)

            # 입력 받기 (빈 줄에서)
            user_input = input().strip()

            # 도움말
            if user_input == '--help':
                clear_previous_lines(len(history) + 2)  # 턴 번호 + 이력 + 입력
                show_help()
                input("\n계속하려면 Enter를 누르세요...")
                prev_lines = 0
                continue

            # 게임 포기
            if user_input.lower() == 'gg':
                clear_previous_lines(len(history) + 2)  # 턴 번호 + 이력 + 입력
                print(f"[{turn}]")
                for item in history:
                    print(item)
                print(f"\n포기하셨습니다.")
                print(f"정답은 '{answer}' 였습니다.")
                break

            # 중복 입력 체크 (입력 라인만 지우고 다시 입력받기)
            if user_input in tried_numbers:
                clear_previous_lines(1)  # 방금 입력한 라인만 지우기
                continue

            # 입력값 검증
            if not validate_input(user_input):
                clear_previous_lines(1)  # 방금 입력한 라인만 지우기
                continue

            # 현재까지 출력한 줄 수 계산 (턴 번호 + 이력 + 입력)
            prev_lines = len(history) + 2

            # 시도한 숫자 저장
            tried_numbers.add(user_input)

            # 결과 계산
            strikes, balls = calculate_result(answer, user_input)

            # 정답 확인
            if strikes == 4:
                clear_previous_lines(prev_lines)
                print(f"[{turn}]")
                for item in history:
                    print(item)
                print(f"{user_input}=4s")
                print(f"\n🎉 정답입니다! {turn}회 만에 맞추셨습니다!")
                break

            # 결과 문자열 생성
            if strikes == 0 and balls == 0:
                result = "out"
            else:
                result_parts = []
                if strikes > 0:
                    result_parts.append(f"{strikes}s")
                if balls > 0:
                    result_parts.append(f"{balls}b")
                result = "".join(result_parts)

            # 이력에 추가
            history.append(f"{user_input}={result}")

            # 마지막 턴 확인
            if turn == max_turns:
                clear_previous_lines(prev_lines)
                print(f"[{turn}]")
                for item in history:
                    print(item)
                print(f"\nYou lose! {max_turns}회 안에 맞추지 못했습니다.")
                print(f"정답은 '{answer}' 였습니다.")
                break

            turn += 1

    except KeyboardInterrupt:
        print(f"\n\n강제 종료되었습니다.")
        print(f"정답은 '{answer}' 였습니다.")
        sys.exit(0)


if __name__ == "__main__":
    main()
