---
name: showtmuxpane
description: "When it is necessary to reference the output results of a shell or command within a tmux environment, or when the skill is directly invoked via (';tm', ';tmux', ';i showtmuxpane', etc.,) use this skill."
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
  - It can be used as follows: `test -n "$TMUX" && showtmuxpane 2 -S -30`.


# SKILL OPTS
This is an optional string that can follow this command.

If no options are provided, the contents of pane 2 will be displayed.

### First Option
The first option specifies the number of the tmux window to display.
Therefore, the first option consists of a numeric value.

### Other Option

Options for tmux capture-pane may be passed through directly.
Additionally, based on the contents of the pane, instructions such as "Analyze the logs." or "Identify the issue based on the error logs." may be given.

