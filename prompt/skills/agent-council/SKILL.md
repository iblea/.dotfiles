---
name: agent-council
description: Collect and synthesize opinions from multiple AI Agents. Use when users say "summon the council", "ask other AIs", "council", or want multiple AI perspectives on a question.
---

# Agent Council

Gather opinions from multiple AI Agents and synthesize responses.

Inspired by Karpathy's LLM Council (https://github.com/karpathy/llm-council)

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
