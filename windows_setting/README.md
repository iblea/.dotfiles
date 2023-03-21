#### `wt_settings.json`
windows terminal settings.json 파일

#### `wsl_connect`
wsl 서비스 및 ssh 외부 접속을 자동으로 시작시켜주는 배치 스크립트

- `wsl_connect.bat` 파일은 `Win + R` 키를 눌러 `shell:startup` 을 입력한 후 나오는 디렉토리에 넣으면 된다.
- `wsl_connect.ps1` 파일은 `Win + R` 키를 눌러 `appdata` 를 입력한 후 나오는 디렉토리에 넣으면 된다.

해당 스크립트를 실행시키기 위해서는 wsl에 기본적으로 ssh 서비스와 `ifconfig` 명령이 존재해야 한다.
```bash
apt-get install ssh
apt-get install net-tools
```
