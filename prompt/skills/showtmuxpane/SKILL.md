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

- Identify the TMUX environment before running tmux commands.
  - Treat the environment as TMUX when either of the following is true:
    - `$TMUX` is set.
    - The session is SSH and both `$LC_TMUX` and `$LC_TMUX_SOCKET` are set.
  - If neither condition is true, output the message "This is not a TMUX environment." and terminate the conversation.
    - It can be checked as follows: `echo $TMUX` or `env | grep "TMUX"`
  - In an SSH session with `$LC_TMUX` and `$LC_TMUX_SOCKET` environment variables set, the agent is controlling the **local (remote host's) tmux** via socket. In this case, `$TMUX` may be empty, but `showtmuxpane` and `sendtmuxpane` scripts internally handle this by using `tmux -S "$LC_TMUX_SOCKET"` instead of plain `tmux`.
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

If no options are provided, the contents of window 2 will be displayed.

### First Option
The first option specifies the target tmux window (and optionally the pane) to display.

Accepted formats:
- `<window>` — target window N, pane 1 (e.g. `2` → window 2, pane 1).
- `<window>.<pane>` — target window N, pane M (e.g. `2.2` → window 2, pane 2).
- `.<pane>` — current window, pane M (e.g. `.2` → current window, pane 2; `.3` → current window, pane 3).
  - **"current window" means the window containing the pane where the AI agent itself is running** (the scripts resolve it internally from `$TMUX_PANE`). It does **NOT** mean the tmux client's currently active/visible window. Even if the user switches to another window after giving the command, the target window NEVER changes.
  - **Pass the `.pane` form to the scripts AS-IS** (`showtmuxpane .2`, `sendtmuxpane .2`). **NEVER resolve `.N` into an explicit `<window>.<pane>` yourself** (e.g. by querying the active window via `tmux display-message -p '#I'` and rewriting `.2` as `4.2`). The active-window value follows the user around; resolving it yourself silently retargets a completely different window. The scripts already resolve the window correctly — do not "help" them.
  - **Window numbers are NOT stable.** When a window is killed or moved, remaining windows may be renumbered (e.g. `renumber-windows on`: windows 1,2,3,4 → kill window 1 → old 2,3,4 become 1,2,3). A once-resolved target like `3.2` would then silently point at what used to be `4.2`. This is exactly why the user writes `.N`: it is re-resolved from the AI agent's own pane (`$TMUX_PANE`) on EVERY invocation, so it keeps tracking the correct window even after renumbering. Pass `.N` as-is every single time — NEVER resolve it once and reuse the resolved `<window>.<pane>` later in the session.
  - This applies to all two scripts: `showtmuxpane`, `sendtmuxpane`.

- example
  - `;tm 2`     → `showtmuxpane 2`     (window 2, pane 1)
  - `;tm 2.2`   → `showtmuxpane 2.2`   (window 2, pane 2)
  - `;tm .2`    → `showtmuxpane .2`    (current window, pane 2)
  - `;tm .3 t 10` → `showtmuxpane .3 | tail -n 10` (current window, pane 3, last 10 lines)

#### 🚨 CRITICAL SECURITY WARNING: DO NOT WATCH ANY OTHER WINDOW / PANE 🚨

**WARNING: DO NOT WATCH, CAPTURE, OR MANIPULATE ANY window/pane OTHER THAN THE EXACT TARGET THE USER SPECIFIED.**

- The ONLY pane you may read (`showtmuxpane` / `capture-pane`) or send keys to (`sendtmuxpane` / `send-keys`) is the exact target the user specified in the command. No exceptions.
- Other panes may be displaying highly sensitive data: API keys, credentials, customer/personal data, live production DB sessions. **The moment you capture a non-specified pane, it is a critical security violation** — sensitive data leaks into the AI context, and sending keys there can destroy or exfiltrate data.
- **NEVER** capture or enumerate other windows/panes to "figure out context", "double-check the target", or for any other reason.
- **NEVER** reinterpret `.N` against the window the user is currently viewing. `.N` is fixed to the AI agent's own window (see `.<pane>` format above). Rewriting `.2` into `<active window>.2` targets a pane the user never authorized.
- If the specified target seems wrong or does not exist, **STOP and ask the user**. NEVER guess or fall back to another window/pane.

**Real incident (why this rule exists):** The user ran `;t sk .2` from the AI agent's window (window 3), then switched to window 4 to work on a DB session. The AI noticed the user's active window was 4, reinterpreted `.2` as `4.2`, and ran `showtmuxpane 4.2` — capturing a pane full of API keys and customer data that the user never told it to touch. The correct behavior was to run `showtmuxpane .2` as-is, which targets window 3 pane 2 regardless of where the user currently is.

#### Pane environment description (optional, parentheses)
The target may be followed by a description wrapped in parentheses: `<target> (<description>)`.

- The parenthesized text is a user-provided hint describing the environment running in the target window/pane (e.g. remote ssh host, docker container, DB shell, local shell).
- It is **NOT** part of the tmux target. **NEVER** pass it as an argument to `showtmuxpane` / `sendtmuxpane`.
- Use it as context when interpreting the pane output or composing commands to send (especially with the `sk` option). For example, `(ssh win)` means the pane's shell is running on the remote host `win`, so any suggested or sent commands must be valid for that remote environment, not the local one.
- Options following the closing parenthesis (`sk`, `t`, `h`, ...) are parsed the same as usual.

- example
  - `;tm .4 (ssh win)` → `showtmuxpane .4` — pane 4 of the current window is a remote session connected via `ssh win`.
  - `;tm 3 (local zsh)` → `showtmuxpane 3` — window 3, pane 1 is a local zsh shell.
  - `;tm 2.3 (docker dreamdb)` → `showtmuxpane 2.3` — window 2, pane 3 is a shell inside the `dreamdb` docker container.
  - `;tm .4 (ssh win) sk install gcc` → analyze pane 4 of the current window, then send commands appropriate for the remote `win` host via `sendtmuxpane .4`.

### Other Option

Options for tmux capture-pane may be passed through directly.
Additionally, based on the contents of the pane, instructions such as "Analyze the logs." or "Identify the issue based on the error logs." may be given.

#### sendkeys or sk

If this option is not provided, only the `capture-pane` command should be executed by default. (Commands such as `send-keys` must never be executed.)
If this option is provided, a specific tmux window can be manipulated through the `sendtmuxpane` command.

##### `sendtmuxpane` command
  - `sendtmuxpane` is available in `$PATH` by default (`~/.dotfiles/.bin/sendtmuxpane`). If not available, use `./script/sendtmuxpane` instead.
  - Usage: `sendtmuxpane <window number>[.<pane number>] [tmux send-keys options...]`
    - The first argument specifies the target window (e.g., `2` for window 2, `2.2` for window 2 pane 2, or `.2` for current window pane 2).
    - The remaining arguments are passed directly as `tmux send-keys` options.
  - Run mode: `sendtmuxpane -w [--timeout <sec>] <target> '<command>'` (see the `-w (--write) run mode` section below)
  - `sendtmuxpane` automatically detects and cancels copy-mode on the target pane before sending keys. No manual copy-mode check is required when using `sendtmuxpane`.

##### `-w` (`--write`) run mode
  - Usage: `sendtmuxpane -w [--timeout <sec>] <target> '<command>'`
    - `-w` (or `--write`) MUST be the first argument. `--timeout <sec>` works ONLY right after `-w` (default 30 seconds, wall-clock upper bound).
    - `<command>` is a single string argument.
  - Behavior: runs `<command>` in the target pane, waits for completion, then writes **only the command's output** to stdout AND `/tmp/sendtmuxpane.txt`.
    - `/tmp/sendtmuxpane.txt` is **overwritten on every run** (previous content is discarded).
    - The pane screen keeps displaying the output as usual (output is copied via `pipe-pane`, not intercepted).
    - The ONLY keys sent to the pane are `<command>` + Enter. No markers/wrappers are injected.
    - Output is streamed to a file, so large outputs (thousands of lines) are saved without the screen-history truncation of `capture-pane`. **Use this mode to collect large command outputs** (install logs, build logs, log queries) instead of `showtmuxpane`.
  - Works on remote panes too (ssh / docker): completion is detected by observation only, in 4 stages:
    1. pane foreground process returns to a shell (local pane, fast)
    2. the prompt captured right before execution reappears (remote pane, fast)
    3. output idle for 3 seconds (remote fallback)
    4. `--timeout` safety net (partial output + exit 1)
  - stderr reports `INFO: done by '<stage>'`:
    - `shell` / `prompt`: reliable completion.
    - `idle`: completion inferred from 3s of output silence. If output looks incomplete (e.g. a command that stays silent longer than 3s), re-check the pane with `showtmuxpane`.
    - `max`: NOT complete. The command may still be running in the pane (this is normal for servers / `tail -f`; the collected partial output is still written).
  - Do NOT use `-w` for interactive programs (vim, less, password prompts) or commands that never finish on their own; for those, use plain `sendtmuxpane` + `showtmuxpane`. For servers, `-w --timeout <sec>` is a valid way to collect startup logs.
  - NOTE: avoid a trailing `;` at the very end of `<command>` (tmux parser may consume it). A `;` in the middle of the command string is safe: `sendtmuxpane -w .2 'echo a; echo b'`.
  - example
    - `sendtmuxpane -w .2 'ls -al'`
    - `sendtmuxpane -w --timeout 120 .2 'apt-get install -y gcc'`
    - `sendtmuxpane -w --timeout 15 .2 './mvnw spring-boot:run'` (collect ~15s of server startup logs; server keeps running)

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
  - Do not guard `showtmuxpane` with only `[ -n "$TMUX" ]`; SSH + `LC_TMUX_SOCKET` sessions may have an empty `$TMUX`. Use `showtmuxpane` directly because the script handles the tmux context internally.
    - Incorrect Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | tail -n 20`
    - Correct Example: `showtmuxpane 2 -S -5 --tail 10` (`-t`, `-T`, `--tail` option use. A number must be entered after the option.)

#### head or h (optional number: default 20)

If this option is provided, append `| head -n <number>` after the capture-pane command to output only the first `n` lines.

- If the content after h is not a number, it is treated as if no number option was provided, and the default value of 20 is used for output.

- example
  - `;tm 2 h 10`: `showtmuxpane 2 | head -n 10`
  - `;tm 2 h`: `showtmuxpane 2 | head -n 20`
    - Since there is no content after `h`, the default value of 20 is used for output.
  - `;tm 2 -S -50 h`: `showtmuxpane 2 -S -50 | head -n 20`
  - Do not guard `showtmuxpane` with only `[ -n "$TMUX" ]`; SSH + `LC_TMUX_SOCKET` sessions may have an empty `$TMUX`. Use `showtmuxpane` directly because the script handles the tmux context internally.
    - Incorrect Example: `[ -n "$TMUX" ] && showtmuxpane 2 -S -5 | head -n 20`
    - Correct Example: `showtmuxpane 2 -S -5 --head 10` (`-h`, `-H`, `--head` option use. A number must be entered after the option.)

