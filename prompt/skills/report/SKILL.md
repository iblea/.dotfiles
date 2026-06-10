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

Supported formats can be various file formats such as md (markdown), html, pdf, txt, excel (xlsx/xls), word (docx/doc), etc.

If the report format is HTML and a diagram is needed, use mermaid.js.
For the mermaid.min.js file, use the JavaScript file at `https://www.iasdf.com/js/mermaid_11_15_0.min.js`.
 - The mermaid version of the link is 11.15.0.

### Second Option: Report Filename

Specifies the filename of the report.
Since various file formats can be entered as the first option, the filename option is always fixed as the second option.
If the second argument is not entered, the default report name is `report`.
If no extension is entered for the report filename, the extension follows the report format.

- `;rpt html test` -> Save as test.html
- `;report markdown report` -> Save as report.md
- `;rpt html` -> Save as report.html
  - Since no name was entered, the report name is report, and since the report format is html, it must be saved as `report.html`.
