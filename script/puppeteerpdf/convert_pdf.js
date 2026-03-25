const puppeteer = require('puppeteer');
const markdownIt = require('markdown-it');
const fs = require('fs');
const path = require('path');

const [,, mdFile, outFile] = process.argv;
if (!mdFile) {
  console.error('Usage: node convert.js <input.md> [output.pdf]');
  process.exit(1);
}

const mdPath = path.resolve(mdFile);
const pdfPath = outFile ? path.resolve(outFile) : mdPath.replace(/\.md$/, '.pdf');
const cssDir = path.join(__dirname, 'css');

// const md = markdownIt({ html: true, typographer: true, breaks: true });
const md = markdownIt({ html: true, typographer: true, breaks: true, linkify: true });
const raw = fs.readFileSync(mdPath, 'utf8');
const content = raw.replace(/^---[\s\S]*?---\n*/, '');
const body = md.render(content);

// 1) MPE 기본 레이아웃
const styleTemplate = fs.readFileSync(path.join(cssDir, 'style-template.css'), 'utf8');
// 2) MPE 테마 (one-light)
const themeCss = fs.readFileSync(path.join(cssDir, 'one-light.css'), 'utf8');
// 3) 사용자 커스텀
const userCss = fs.readFileSync(path.join(cssDir, 'user-custom.css'), 'utf8');

const html = `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
/* 1. MPE style-template */
${styleTemplate}
</style>
<style>
/* 2. MPE one-light theme */
${themeCss}
</style>
<style>
/* 3. User custom style */
${userCss}
</style>
</head>
<!-- <body class="markdown-preview markdown-preview"> -->
<body for="html-export">
<div class="crossnote markdown-preview">
${body}
</div>
</body>
</html>`;

// 디버깅용 HTML 저장
fs.writeFileSync(pdfPath.replace(/\.pdf$/, '.html'), html);

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle0' });
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    // printBackground: true,
    // margin: { top: '20mm', bottom: '20mm', left: '15mm', right: '15mm' },
    printBackground: false,
    margin: { top: '1cm', bottom: '1cm', left: '1cm', right: '1cm' },
  });
  await browser.close();
  console.log('PDF generated:', pdfPath);
})();
