
- <https://coolenjoy.net/bbs/37/247261>
- <https://www.tenforums.com/tutorials/57690-create-elevated-shortcut-without-uac-prompt-windows-10-a.html>

`Win+R`: control schedtasks

"작업 스케줄러 라이브러리" > 우클릭 > 새 폴더 -> 이름: new_tasks
new_tasks 클릭
"작업 만들기..." 또는 우클릭 후 "새 작업 만들기"

```
이름: admin_starter
- 사용자가 로그온할 때만 실행
- 가장 높은 수준의 권한으로 실행
구성 대상: Windows 10
```

트리거 > 새로 만들기
```
작업 시작: 로그온할 때
설정: 모든 사용자
고급 설정
  - 사용 체크
```

동작 > 새로 만들기
```
동작: 프로그램 시작
프로그램/스크립트: C:\Users\testuser\testscript.bat
```

조건
- 컴퓨터의 AC 전원이 켜져 있는 경우에만 작업 시작 (체크 해제)

바탕화면에서 > 우클릭 > 바로가기 추가

항목 위치 입력: C:\Windows\System32\schtasks.exe /run /tn "\new_tasks\admin_starter"
여기의 `/run/tn` 뒤에는 생성한 작업 폴더명/작업명 을 입력해주면 된다.


전체 UAC 비활성화

`Win+R`: UserAccountControlSettings.exe

-> 다음의 경우 항상 알리지 않음(사용자 계정 컨트롤 끄기) (제일 아래에 있는 항목 선택)
-> 확인


