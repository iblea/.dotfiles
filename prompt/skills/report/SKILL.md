---
name: report
description: Write a report to a file. Use when 'write a report' or '보고서를 작성해'.
argument-hint: [format] [filename]
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).


# SKILL Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.


# SKILL behavior

- Summarize the conversation and write a report.
  - The report must include the last updated time.
    - The last updated time is based on the desktop (system) time, formatted as `YYYY-MM-DD HH:MM:SS`.
    - Do not guess the time. Use the value obtained by running the `date '+%Y-%m-%d %H:%M:%S'` command.

- Save the report in the current path (current working directory).

- Depending on each option, the report format, the output report name, etc. can be specified.
  - Specify the report format and the output file name according to the entered option values.
  - If no options are entered, use the default values.

If a report already exists, content can be added/modified/deleted in the existing report.
If the existing report needs to be erased and rewritten, before erasing all content, ask the user the confirmation question '정말로 기존 보고서의 내용을 지우고 새로 작성하시겠습니까?' and proceed only after receiving an affirmative response from the user.


# SKILL OPTS

Zero or more options can be entered.
The order of the first two options is fixed. (First: report format, Second: report filename)
Any remaining arguments beyond the first two are interpreted as additional instructions for the report content.

- `;rpt md analysis Focus on today's analysis` -> Save as analysis.md, and apply "Focus on today's analysis" as an additional instruction when writing the report.

### First Option: Report Format

Specifies the format of the report.
If the first argument is not entered, the default output format is markdown (md).

Supported formats can be various file formats such as md (markdown), html, art (artifact/artifacts), pdf, txt, excel (xlsx/xls), word (docx/doc), etc.

If the report format is HTML and a diagram is needed, use mermaid.js.
For the mermaid.min.js file, use the JavaScript file at `https://www.iasdf.com/js/mermaid_11_15_0.min.js`.
 - The mermaid version of the link is 11.15.0.

##### HTML Format

If the report format is HTML, write the report based on `report.css`, the stylesheet bundled with this skill.

**Locating `report.css`** — this skill runs with the user's project as the current working directory, NOT the skill directory, so a bare relative path will NOT resolve. Always read the file by absolute path, trying the following in order:
1. `~/.claude/skills/report/css/report.css` (standard skill location)
2. `~/.dotfiles/prompt/skills/report/css/report.css` (the real location; `~/.claude/skills` is a symlink to `~/.dotfiles/prompt/skills`)

If neither path exists, do NOT guess or reconstruct the styles from memory. Tell the user that `report.css` could not be found, then write the report with a minimal self-authored style instead.

**Applying the stylesheet**
- Read the CSS file and embed its contents inline in a `<style>` tag inside the HTML report, so that the report remains a single self-contained file.
- Follow the class names, layout, and color scheme defined in that CSS. Do not rewrite the existing styles arbitrarily; if a style that the CSS does not provide is needed, add only the minimum extra rules.

For font information, refer to the fonts available under `https://www.iasdf.com/rpt/font/`.
- Use only the fonts that exist at that location, and declare them with `@font-face` in the same way as in `report.css`.
- Always specify a fallback font stack (e.g., system fonts) together, so the report stays readable even when the font host is unavailable.


##### Artifact Format (art / artifact / artifacts)

If the first argument is `art`, `artifact`, or `artifacts`, write the report in HTML format and render it as an Artifact using the Artifact tool.
- The Artifact tool only accepts a file path (no inline content), so an HTML file must be written first. Write it to the session scratchpad directory (or a temp directory such as `/tmp` if no scratchpad is available) — NOT the current working directory.
  - This overrides the "Save the report in the current path" rule above. Do NOT leave a report file in the working directory; the artifact itself is the deliverable. (This keeps report files out of the project's git untracked list.)
  - The filename still follows the Second Option rule with the `.html` extension (the basename is used as the artifact's fallback title).
- Do NOT use the external mermaid.js link above in this case. Artifacts block external scripts (CSP) but render mermaid natively, so use `<pre class="mermaid">` blocks for diagrams instead.
- After publishing, provide the artifact URL to the user.

###### Fonts in Artifact Format

The `report.css` rule of the HTML Format section still applies (embed the CSS inline in a `<style>` tag), but the `@font-face` blocks of that CSS MUST NOT be copied as-is.
Artifacts are served under a strict CSP, so the fonts hosted on `https://www.iasdf.com/rpt/font/` cannot be loaded there. They are blocked silently with no visible error, and this is unrelated to the font host's CORS headers — CSP is enforced by the artifact viewer before the request is ever sent, so an `Access-Control-Allow-Origin: *` header does not help.

Therefore, resolve the fonts as follows when writing an Artifact report:
- Drop every `@font-face` rule that points to `https://www.iasdf.com/...`.
- Keep the `font-family` declarations and the overall typography of `report.css`, but replace the font sources with one of the following, in order of preference:
  1. Google Fonts — the only external stylesheet host allowed by the CSP. Load it with `<link rel="stylesheet" href="https://fonts.googleapis.com/css2?...">` (the font files it pulls from `https://fonts.gstatic.com` are allowed as well).
     - Korean body text: `Noto Sans KR` / Code and monospace: `JetBrains Mono`
  2. System font stacks only, making no external request at all.
- Whichever is chosen, always keep a fallback stack so the report stays readable even if the font fails to load.
  - body: `"Noto Sans KR", -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Malgun Gothic", sans-serif`
  - code: `"JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace`
- Do NOT embed the remote fonts as `data:` URIs just to work around the CSP unless the user explicitly asks for it. Korean webfonts are large and quickly eat into the artifact's 16MB limit.



### Second Option: Report Filename

Specifies the filename of the report.
Since various file formats can be entered as the first option, the filename option is always fixed as the second option.
If the second argument is not entered, the default report name is `report`.
If no extension is entered for the report filename, the extension follows the report format.

- `;rpt html test` -> Save as test.html
- `;report markdown report` -> Save as report.md
- `;rpt html` -> Save as report.html
  - Since no name was entered, the report name is report, and since the report format is html, it must be saved as `report.html`.


### Single Argument Special Case

If only one argument is entered and it does not correspond to any supported report format, interpret it as the filename.
In this case, the filename must always contain an extension, and the report format must be inferred from that extension.

In the following cases, immediately stop writing the report through this SKILL, output `Wrong Argument`, and end the response:
- Only one argument is entered and it has no extension (e.g., `testfile`)
- Only one argument is entered and the report format cannot be inferred from its extension (e.g., `testfile.dat`)
