---
name: showtmuxpane
description: "This skill is used when it is necessary to reference the output results of a shell or command within a tmux environment, when it is necessary to manipulate tmux windows or panes (send-keys), or when the skill is directly invoked (via ';tm', ';tmux', ';i showtmuxpane', etc.)."
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).


# SKILL Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below. (`#SKILL OPTS` section)


# SKILL behavior

- Identify the TMUX environment, and if the agent is operating within a TMUX environment, perform the following tasks.
  - If the environment is not TMUX, output the message "This is not a TMUX environment." and terminate the conversation.
- The description of the commands is as follows.
  - Verify whether the `showtmuxpane` function is defined using `command -v showtmuxpane` or similar methods. If it is defined, utilize the `showtmuxpane` function to reference the output of a specific window.
  - Use the following format: `showtmuxpane <window name> -S <tail line count>`.
  - `showtmuxpane 2 -S -30` is equivalent to the following command:
    - `tmux capture-pane -t 2 -p -S -30 -E $(($(tmux display -p -t 2 '#{pane_height}') - 2))`

  - Therefore, if the `showtmuxpane` command is not available, use the following command instead. (Replace `<window number>` and `<tail line count>` with appropriate values.)
    - `tmux capture-pane -t <window number> -p -S <tail line count> -E $(($(tmux display -p -t <window number> '#{pane_height}') - 2))`
  - It can be used as follows: `[ -n "$TMUX" ] && showtmuxpane 2 -S -30`.


# SKILL OPTS
This is an optional string that can follow this command.

If no options are provided, the contents of pane 2 will be displayed.

### First Option
The first option specifies the number of the tmux window to display.
Therefore, the first option consists of a numeric value.

### Other Option

Options for tmux capture-pane may be passed through directly.
Additionally, based on the contents of the pane, instructions such as "Analyze the logs." or "Identify the issue based on the error logs." may be given.

#### sendkeys or sk

If this option is not provided, only the `capture-pane` command should be executed by default. (Commands such as `send-keys` must never be executed.)
If this option is provided, a specific tmux window can be manipulated through commands such as `send-keys`.
  - When the input is `;tm 2 sk`, the content of window 2 should be referenced, and all subsequent command-related interactions must be conducted in window 2.
  - Since tmux operates as an interactive session, interactive CLI tools such as ssh, mysql, and psql can be used.
  - After executing `send-keys`, run the `capture-pane` related command to check the results. At this time, DO NOT USE in sleep commands.
    - example
      - good: `tmux send-keys -t 2 '<command>' Enter && showtmuxpane 2 -S -10`
      - bad: `tmux send-keys -t 2 '<command>' Enter && sleep 2 && showtmuxpane 2 -S -10`
        - Sleep command is not necessary.

- Example
  - `;tm 2 sk apt is not working. Analyze the content and suggest an alternative installation method.`
  - When the above command is entered, the content of window 2 is analyzed using `showtmuxpane` or `capture-pane`.
  - Subsequently, the apt error message is analyzed to suggest appropriate countermeasures and commands, and the user is asked whether to execute them in window 2. (Since the instruction was only to analyze the content, asking before execution is mandatory.)
  - Then, depending on the user's response, the commands are executed in window 2 through `send-keys` or similar methods.

#### tail or t (optional number: default 20)

If this option is provided, Append `| tail -n <number>` after the capture-tmux command to output only the last `n` lines.

- If the content after t is not a number, it is treated as if no number option was provided, and the default value of 20 is used for output.

- example
  - `;tm 2 t 10`: `showtmuxpane 2 | tail -n 10`
  - `;tm 2 t`: `showtmuxpane 2 | tail -n 20`
    - Since there is no content after `t`, the default value of 20 is used for output.
  - `;tm 2 -S -5 t`: `showtmuxpane 2 -S -5 | tail -n 20`
  - If check "TMUX" environment variable, use `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | tail -n 20` this command.

#### head or h (optional number: default 20)

If this option is provided, Append `| head -n <number>` after the capture-tmux command to output only the first `n` lines.

- If the content after t is not a number, it is treated as if no number option was provided, and the default value of 20 is used for output.

- example
  - `;tm 2 h 10`: `showtmuxpane 2 | head -n 10`
  - `;tm 2 h`: `showtmuxpane 2 | head -n 20`
    - Since there is no content after `h`, the default value of 20 is used for output.
  - `;tm 2 -S -50 h`: `showtmuxpane 2 -S -50 | head -n 20`
  - If check "TMUX" environment variable, use `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | head -n 20` this command.

