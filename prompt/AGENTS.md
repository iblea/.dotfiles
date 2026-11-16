# Direct Reply Rule (Explicit Startup Exception)

- Before any skill lookup, memory lookup, file read, tool call, or delegation, decide from the current message and already-loaded context whether additional information or action is needed.
- For greetings (e.g. "야", "안녕"), casual chat, standalone acknowledgements, and simple questions fully answerable from the current conversation, reply directly and briefly. Do not invoke skills, consult memory, read referenced prompt files (including `@global_prompt.md`), call tools, create plans, or announce preparatory work for these turns.
- This explicit user instruction takes precedence over automatic skill-startup rules, including Superpowers `using-superpowers`: "before any response", the "1% chance" trigger, and "simple questions are tasks" do not require skill lookup for the turns above. Apply this exception directly without reading a skill to confirm it.
- Explicit skill/tool requests, requests needing fresh external or workspace evidence, and short replies that approve or continue a pending task follow the relevant task workflow. Keep checks proportional to the actual request.

@global_prompt.md

# Table Formatting

If the `AIAGENTCODE` environment variable is set, assume a terminal environment.
When writing/rendering tables, size the cells so that 2 English characters/spaces = 1 Korean character, as shown below, to keep the table from breaking.
```
┌──────────────────┐
│ QUIC             │
│ (TLS 1.3 내장)   │
├──────────────────┤
│ IP               │
└──────────────────┘
```

Alternatively, you can draw tables using ASCII-compatible characters (+, -, |, etc.).

```
+------------------+
| QUIC             |
| (+TLS 1.3 내장)  |
+------------------+
| UDP              |
+------------------+
```
