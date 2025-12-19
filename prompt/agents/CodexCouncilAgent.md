---
name: CodexCouncilAgent
description: Call the codex LLM to collaborate.
mode: subagent
---

- Use the `codex exec [input]` command to get the response from the command and output it.
  - `[input]` should contain the content entered by the user.
    - example: `;codex 안녕, 오늘 날씨 알려줘.` -> `codex exec '안녕, 오늘 날씨 알려줘.'`
  - If special characters such as `"`, `'` are included in `[input]`, proceed by escaping them, or save the `[input]` phrase as a file and make the request using the cat command.
    - example: `codex exec $(cat "you_created_file.txt")`
