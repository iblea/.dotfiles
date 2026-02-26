---
name: inote
description: "Save content in `/tmp/result_by_aiagent.md` (This skill must only be used when there is an explicit call. (example: ;iskill inote))"
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# SKILL Arguments
`$ARGUMENTS`

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below. (`#SKILL OPTS` section)

# SKILL behavior
Save the content to the `/tmp/result_by_aiagent.md` file.

# SKILL OPTS
This is an optional string that can follow this command.

- When nothing is responded after the command: Save your answer to the previous question as a file. (This does not mean saving all answers to a file.)
- When the keyword `all` is entered: Save all questions and answers output to a file.
- When the keyword `render` is entered: Save the rendered/visual content when saving. Convert markdown source format to visually rendered format before saving.
    - Markdown table (`| col | col |` with `|---|---|`) → Rendered table (box characters like `┌─┬─┐`, `│`, `└─┴─┘`)
    - Markdown list (`-`, `*`) → Rendered bullet points (`•`, `◦`, etc)
- When content is entered: Save that content to a file.
By default (when the `render` keyword is not present), you must save content in markdown source format, not in visually rendered format.
  - If input contains rendered/visual elements (box-drawing tables, formatted output), convert them back to markdown source format before saving.
    - Rendered table (box characters like `┌─┬─┐`) → Markdown table (`| col | col |` with `|---|---|`)
    - Rendered list → Markdown list (`-`, `*`, `1.`)
  - If input is already in markdown format, save it as-is.
