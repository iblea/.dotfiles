기본 사용법 및 symbolic link 명령은 `settings.sh` 스크립트 참조.

settings.sh 스크립트 실행 시 대부분 자동으로 경로를 잡아주도록 설정해 놓았습니다.

`.aliases` 파일은 bash/zsh 쉘, wsl/mac/linux 모두 되도록 최대한 설정중입니다. \
하나의 쉘만 적용 가능한 스크립트의 경우 다른 alias 파일로 두려고 합니다.

--------

## vimrc 디렉토리

- linux vim을 사욯한다면 `.vimrc` 사용
- neovim을 사용한다면 `.vimrc`에 `.neovimrc` 내용 추가
- vscode 확장의 vim을 사용하려면 `.vsvimrc` 파일 사용
- idea 확장의 vim을 사용하려면 `.ideavimrc` 파일 사용 (현재 없음)


--------

## 환경변수

기본적인 글로벌 환경변수 세팅은 .envpath 에 존재한다.

장비 및 환경에 따라서 다른 환경변수를 사용하고 싶다면 env_custom 디렉토리에 파일을 추가하고 환경변수를 기입한다.