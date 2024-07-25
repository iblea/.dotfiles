#!/bin/bash


cd $HOME/.config/aider/

# https://aider.chat/docs/llms.html#deepseek
# https://openrouter.ai/docs#models

ENV_PATH="$HOME/.config/aider/env_aider.env"
source "$ENV_PATH"

if [ -z "$AIDER_MODEL" ]; then

	echo "no custom model"
	/opt/homebrew/bin/aider \
		--env-file "$ENV_PATH" \
		--sonnet \
		--input-history-file "$HOME/.config/aider/history.input.md" \
		--chat-history-file "$HOME/.config/aider/history.chat.md" \
		--code-theme monokai \
		--no-git \
		--no-gitignore \
		--dark-mode

else

	# AIDER_MODEL_OPT=$(echo "$AIDER_MODEL_PARSE" | awk -F '=' '{print $2}' )
	# AIDER_MODEL_OPT=$(echo "${AIDER_MODEL_OPT::$(expr ${#AIDER_MODEL_OPT} - 1)}")
	# echo "aider model use: ${AIDER_MODEL_OPT:1}"
	# --model ${AIDER_MODEL_OPT:1} \
	# --env-file $HOME/.config/aider/.aider.env \
	# --model "${AIDER_MODEL}" \

	/opt/homebrew/bin/aider \
		--input-history-file "$HOME/.config/aider/history.input.md" \
		--chat-history-file "$HOME/.config/aider/history.chat.md" \
		--code-theme monokai \
		--no-git \
		--no-gitignore \
		--pretty \
		--dark-mode

fi


