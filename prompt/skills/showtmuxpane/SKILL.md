---
name: showtmuxpane
description: "This skill is used when it is necessary to reference the output results of a shell or command within a tmux environment, when it is necessary to manipulate tmux windows or panes (send-keys), or when the skill is directly invoked (via ';t', ;tm', ';tmux', ';i showtmuxpane', etc.)."
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
    - It can be used as follows: `echo $TMUX` or `env | grep "TMUX"`
  - However, in an SSH session with `$LC_TMUX` and `$LC_TMUX_SOCKET` environment variables set, the agent is controlling the **local (remote host's) tmux** via socket. In this case, `$TMUX` may be empty, but `showtmuxpane` and `sendtmuxpane` scripts internally handle this by using `tmux -S "$LC_TMUX_SOCKET"` instead of plain `tmux`.
    - This means: SSH environment + `LC_TMUX_SOCKET` present = operating on local tmux from a remote connection. Keep this in mind when interpreting tmux context.
- The description of the commands is as follows.
  - Verify whether the `showtmuxpane` function is defined using `command -v showtmuxpane` or similar methods. If it is defined, utilize the `showtmuxpane` function to reference the output of a specific window.
  - Use the following format: `showtmuxpane <window name> -S <tail line count>`.
  - `showtmuxpane 2 -S -30` is equivalent to the following command:
    - `tmux capture-pane -t 2 -p -S -30 -E $(($(tmux display -p -t 2 '#{pane_height}') - 2))`

  - Therefore, if the `showtmuxpane` command is not available, use the following command instead. (Replace `<window number>` and `<tail line count>` with appropriate values.)
    - `tmux capture-pane -t <window number> -p -S <tail line count> -E $(($(tmux display -p -t <window number> '#{pane_height}') - 2))`


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
If this option is provided, a specific tmux window can be manipulated through the `sendtmuxpane` command.

##### `sendtmuxpane` command
  - `sendtmuxpane` is available in `$PATH` by default (`~/.dotfiles/.bin/sendtmuxpane`). If not available, use `./script/sendtmuxpane` instead.
  - Usage: `sendtmuxpane <window number>[.<pane number>] [tmux send-keys options...]`
    - The first argument specifies the target window (e.g., `2` for window 2, or `2.2` for window 2 pane 2).
    - The remaining arguments are passed directly as `tmux send-keys` options.
  - `sendtmuxpane` automatically detects and cancels copy-mode on the target pane before sending keys. No manual copy-mode check is required when using `sendtmuxpane`.

##### copy-mode handling
  - When using `tmux send-keys` directly (without `sendtmuxpane`), the target window/pane may be in copy-mode, which prevents `send-keys` from working. You MUST manually check and cancel copy-mode first:
    - Check: `tmux display -t <window> -p '#{pane_in_mode}'` (returns `1` if in copy-mode)
    - Cancel: `tmux send-keys -t <window> -X cancel`
  - This manual check is ONLY required when using `tmux send-keys` directly. When using `sendtmuxpane`, copy-mode is automatically detected and cancelled by the script.

##### WARNING: tmux special characters (escape required)
  - When using `sendtmuxpane`, the following characters are interpreted specially by the tmux command parser and **must be escaped**:
    - `;` (semicolon): tmux command separator. Escape with `'\;'`
    - `#` (hash): tmux comment marker (text after `#` is ignored). Escape with `'\#'`
    - `\` (backslash at end of line): line continuation. Escape with `'\\'`
  - **Example (semicolon escape):**
    - `sendtmuxpane 2 "SELECT 1" '\;' C-m`
    - Incorrect: `sendtmuxpane 2 "SELECT 1;" C-m` (`;` is consumed by tmux parser)
  - The `-l` (literal) flag of `tmux send-keys` does NOT prevent this issue because tmux parses `;` before interpreting options.

##### NOTE: backslash and `-l` flag
  - To send literal backslash sequences (e.g. `\t`, `\n`), use the `-l` flag.
    - Without `-l`: `\t` may be interpreted as a Tab key by the target shell.
    - With `-l`: `\t` is sent as literal characters (backslash + t), not as a Tab key.
  - Example: `sendtmuxpane 2 -l 'echo \ttest' && sendtmuxpane 2 C-m`
  - When using `-l`, special keys like `C-m` (Enter) cannot be included in the same call. Send them separately.

##### NOTE: quoting (`'`, `"`) with sendtmuxpane
  - When the text to send contains quotes (`'` or `"`), shell escaping must be applied carefully.
  - The arguments pass through **two layers of interpretation**: the local shell (bash/zsh) first, then `tmux send-keys`.
  - Use backslash-escaped quotes (`\"`, `\'`) or mix single/double quoting as needed.
  - Examples:
    - `sendtmuxpane 2 -l "echo '\\ttest'" && sendtmuxpane 2 C-m`
    - `sendtmuxpane 2 -l 'echo "hello world"' && sendtmuxpane 2 C-m`
    - `sendtmuxpane 2 -l "SELECT * FROM users WHERE name='test'" && sendtmuxpane 2 C-m`

##### sk option behavior
  - When the input is `;tm 2 sk`, the content of window 2 should be referenced, and all subsequent command-related interactions must be conducted in window 2.
  - Since tmux operates as an interactive session, interactive CLI tools such as ssh, mysql, and psql can be used.
  - After executing `sendtmuxpane`, run the `capture-pane` related command to check the results. At this time, DO NOT USE sleep commands.
    - example
      - good: `sendtmuxpane 2 '<command>' Enter && showtmuxpane 2 -S -10`
      - bad: `sendtmuxpane 2 '<command>' Enter && sleep 2 && showtmuxpane 2 -S -10`
        - Sleep command is not necessary.

- Example
  - `;tm 2 sk apt is not working. Analyze the content and suggest an alternative installation method.`
  - When the above command is entered, the content of window 2 is analyzed using `showtmuxpane` or `capture-pane`.
  - Subsequently, the apt error message is analyzed to suggest appropriate countermeasures and commands, and the user is asked whether to execute them in window 2. (Since the instruction was only to analyze the content, asking before execution is mandatory.)
  - Then, depending on the user's response, the commands are executed in window 2 through `sendtmuxpane`.

#### tail or t (optional number: default 20)

If this option is provided, Append `| tail -n <number>` after the capture-tmux command to output only the last `n` lines.

- If the content after t is not a number, it is treated as if no number option was provided, and the default value of 20 is used for output.

- example
  - `;tm 2 t 10`: `showtmuxpane 2 | tail -n 10`
  - `;tm 2 t`: `showtmuxpane 2 | tail -n 20`
    - Since there is no content after `t`, the default value of 20 is used for output.
  - `;tm 2 -S -5 t`: `showtmuxpane 2 -S -5 | tail -n 20`
  - Do not check the TMUX environment variable and query with showtmuxpane at the same time as this command. There is a high possibility that errors will occur.
    - Incorrect Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | tail -n 20`
    - Correct Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 --tail 10` (`-t`, `-T`, `--tail` option use. A number must be entered after the option.)

#### head or h (optional number: default 20)

If this option is provided, Append `| head -n <number>` after the capture-tmux command to output only the first `n` lines.

- If the content after t is not a number, it is treated as if no number option was provided, and the default value of 20 is used for output.

- example
  - `;tm 2 h 10`: `showtmuxpane 2 | head -n 10`
  - `;tm 2 h`: `showtmuxpane 2 | head -n 20`
    - Since there is no content after `h`, the default value of 20 is used for output.
  - `;tm 2 -S -50 h`: `showtmuxpane 2 -S -50 | head -n 20`
  - Do not check the TMUX environment variable and query with showtmuxpane at the same time as this command. There is a high possibility that errors will occur.
    - Incorrect Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | head -n 20`
    - Correct Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 --head 10` (`-h`, `-H`, `--head` option use. A number must be entered after the option.)


