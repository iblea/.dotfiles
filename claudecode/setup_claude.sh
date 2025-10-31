#!/bin/bash

if [ -z "$(command -v claude)" ]; then
    echo "claude code is not installed"
    echo "install claude code"
    echo "npm install -g @anthropic-ai/claude-code"
    exit 1
fi

CLAUDE_DIR="$HOME/.claude"


if [ ! -d "$CLAUDE_DIR" ]; then
    mkdir -p "$CLAUDE_DIR"
fi

echo "setup status-line"
ln -s "$HOME/.dotfiles/claudecode/statusline-command.sh" "$CLAUDE_DIR/"

echo "setup agents directory"
ln -s "$HOME/.dotfiles/prompt/agents" "$CLAUDE_DIR/"

echo "setup commands directory"
if [ ! -d "$CLAUDE_DIR/commands" ]; then
	mkdir -p "$CLAUDE_DIR/commands"
fi
ln -s "$HOME/.dotfiles/prompt/commands" "$CLAUDE_DIR/commands/di"

echo "setup settings.json"
cp -r "$HOME/.dotfiles/claudecode/settings.json" "$HOME/.claude/settings.json"

echo "install mcp servers"
npm install -g @modelcontextprotocol/server-sequential-thinking
npm install -g @upstash/context7-mcp
npm install -g @playwright/mcp@latest
cp -r "$HOME/.dotfiles/claudecode/sequential-thinking-improved.js" "$(npm root -g)/@modelcontextprotocol/server-sequential-thinking/dist/sequential-thinking-improved.js"
echo "sequential thinking mcp script modify. (check this path)"
echo "\$(npm root -g)/@modelcontextprotocol/server-sequential-thinking/dist/sequential-thinking-improved.js"
echo "CHANGE ~/.claude.json , ~/.claude/settings.json YOUR_API_KEY"

echo "setup prompt"
if [ ! -e "$CLAUDE_DIR/global_prompt.md" ]; then
    ln -s "$HOME/.dotfiles/prompt/global_prompt.md" "$CLAUDE_DIR/"
fi
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    touch "$CLAUDE_DIR/CLAUDE.md"
fi
CLAUDE_PROMPT_CHECK=$(grep '^@global_prompt.md$' "$CLAUDE_DIR/CLAUDE.md")
if [ -n "$CLAUDE_PROMPT_CHECK" ]; then
    echo -e "@global_prompt.md\n\n$(cat $CLAUDE_DIR/CLAUDE.md)" > "$CLAUDE_DIR/CLAUDE.md"
fi

echo "add this in '\$HOME/.claude/CLAUDE.md'"
echo "@global_prompt.md"

echo "modify $HOME/.claude.json"


echo "Plugin update"
echo "/plugin marketplace add anthropics/skills"
claude plugin marketplace add anthropics/skills
echo "/plugin install document-skills@anthropic-agent-skills"
claude plugin install document-skills@anthropic-agent-skills
echo "/plugin install webapp-testing@anthropic-agent-skills"
claude plugin install webapp-testing@anthropic-agent-skills


