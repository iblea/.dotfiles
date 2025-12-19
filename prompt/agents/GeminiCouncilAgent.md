---
name: GeminiCouncilAgent
description: Call the gemini LLM to collaborate.
mode: subagent
---

Use the command `echo "[input]" | gemini --model pro 2>/dev/null` to receive and output the command's response.
  - `[input]` should contain the content entered by the user.
    - example: user input: `Hello, tell me today's weather.` -> command: `echo 'Hello, tell me today's weather' | gemini --model pro 2>/dev/null`
  - If special characters such as `"`, `'` are included in `[input]`, proceed by escaping them, or save the `[input]` phrase as a file and make the request using the cat command.
    - example: `cat you_created_file.txt | gemini --model pro 2>/dev/null`
