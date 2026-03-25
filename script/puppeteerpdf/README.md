# puppeteerpdf

Markdown to PDF converter using Puppeteer.
VSCode Markdown Preview Enhanced (MPE) 의 CSS 스타일을 적용하여 PDF를 생성한다.

## 설치

```bash
cd ~/.dotfiles/script/puppeteerpdf
npm init -y
npm install puppeteer markdown-it
```

## 사용법

```bash
node ~/.dotfiles/script/puppeteerpdf/convert.js <input.md> [output.pdf]
```

- `<input.md>` : 변환할 마크다운 파일 경로 (필수)
- `[output.pdf]` : 출력 PDF 파일 경로 (선택, 미지정 시 input과 같은 경로에 `.pdf` 확장자로 생성)

### 예시

```bash
# 같은 경로에 teleport_cve.pdf 생성
node ~/.dotfiles/script/puppeteerpdf/convert.js teleport_cve.md

# 출력 파일 지정
node ~/.dotfiles/script/puppeteerpdf/convert.js teleport_cve.md /tmp/output.pdf

# 절대 경로
node ~/.dotfiles/script/puppeteerpdf/convert.js /home/user/docs/report.md /home/user/docs/report.pdf
```

## 디렉토리 구조

```
puppeteerpdf/
├── convert.js              # 변환 스크립트
├── css/
│   ├── style-template.css  # MPE 기본 마크다운 레이아웃
│   ├── one-light.css       # MPE 테마 (one-light)
│   └── user-custom.css     # 사용자 커스텀 스타일
├── node_modules/
├── package.json
└── README.md
```

## CSS 적용 순서

1. **style-template.css** - MPE 기본 마크다운 레이아웃 (list, code-chunk, TOC 등)
2. **one-light.css** - MPE 테마 (색상, 폰트, table, blockquote 등)
3. **user-custom.css** - 사용자 커스텀 오버라이드

## CSS 커스텀

사용자 스타일을 수정하려면 `css/user-custom.css` 를 직접 편집하거나,
LESS 소스에서 다시 컴파일한다.

```bash
npx -p less lessc ~/.dotfiles/prompt/style.less css/user-custom.css
```

테마를 변경하려면 `css/one-light.css` 를 다른 MPE 테마 파일로 교체한다.
MPE 테마 파일 위치: `~/.vscode/extensions/shd101wyy.markdown-preview-enhanced-*/crossnote/styles/preview_theme/`

## PDF 설정

`convert.js` 내 기본값:

| 항목 | 값 |
|------|------|
| 용지 | A4 |
| 여백 (상/하) | 20mm |
| 여백 (좌/우) | 15mm |
| 배경 출력 | true |

## 참고

- 마크다운 파일에 frontmatter(`---...---`)가 있으면 자동 제거된다.
- `breaks: true` 설정으로 줄바꿈이 `<br>`로 변환된다.
- 디버깅용 `.html` 파일이 PDF와 같은 경로에 함께 생성된다.
