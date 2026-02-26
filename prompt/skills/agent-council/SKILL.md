---
name: agent-council
description: Collect and synthesize opinions from multiple AI Agents. Use when users say "summon the council", "ask other AIs", "council", or want multiple AI perspectives on a question.
---

# Agent Council

Gather opinions from multiple AI Agents and synthesize responses.

Inspired by Karpathy's LLM Council (https://github.com/karpathy/llm-council)

# SKILL Arguments
`$ARGUMENTS`

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below. (`#SKILL OPTS` section)

# SKILL behavior
Execute the commands corresponding to each `Agent Name` by referring to the table (`#SKILL OPTS` section table).


## Execution Instructions

When this skill is invoked, follow these steps:

### Step 1: Determine Query Type

Parse the user request:
- Pattern "council AGENT_NAME: MESSAGE" means single agent query
- Otherwise means full council query

### Step 2: Execute Query

For SINGLE AGENT query (council gemini: ..., council claude: ...):
- Use Bash tool to pipe the message to the specified agent CLI
- Gemini (gemini) agent: pipe message to "`gemini --model pro 2>/dev/null`" command.
- Claude (gemini) agent: pipe message to "`claude -p`" command.

For FULL COUNCIL query (summon the council, ask other AIs):
- Use Bash tool to run the `council.sh` script located at `$HOME/.claude/skills/agent-council/scripts/council.sh`
- Pass the question as an argument

### Step 3: Present Results

- Prefix Gemini responses with diamond emoji
- Prefix Claude responses with brain emoji
- If multiple responses, synthesize as Chairman

## Agent Commands Reference

See council.config.yaml for configured agents and their CLI commands.

## Requirements

Each agent CLI must be installed and authenticated.

# SKILL OPTS
This is an optional string that can follow this command.

| Agent Name | Command | Parallel Agents |
|------------|---------|-----------------|
| `all` | Request in parallel using both `codex_council_agent` and `gemini_council_agent` subagents. | `codex_council_agent` / `gemini_council_agent` |
| `gem` / `gemini` | `echo "[input]" \| gemini --model pro 2>/dev/null` | `gemini_council_agent` |
| `codex` | `codex exec [input]` | `codex_council_agent` |

- `[input]` should contain the content entered by the user.
  - example
    - `;ag gem` -> execute `gem` / `gemini` agnet command.
      - `;ag gem Hello, tell me today's weather.` -> `echo 'Hello, tell me today's weather' | gemini --model pro 2>/dev/null`
- If special characters such as `"`, `'` are included in `[input]`, proceed by escaping them, or save the `[input]` phrase as a file and make the request using the cat command.
  - example: `cat you_created_file.txt | gemini --model pro 2>/dev/null`
- `p` or `parallel` option input, Refer to the table and execute the subagents corresponding to each option in parallel.
  - example: `;ag p gem` -> use `gemini_council_agent` subagent.
  - example: `;ag p all` -> use `codex_council_agent` / `gemini_council_agent` subagent.

