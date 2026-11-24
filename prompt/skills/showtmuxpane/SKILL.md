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


# Helper scripts

The helper scripts live in `~/.dotfiles/bin/` and are in `$PATH`. This skill's `script/` directory holds symlinks to the same files (`script/<name> -> ../../../../bin/<name>`), so both paths run the identical script.

| Script         | Purpose                                                                                    |
|----------------|--------------------------------------------------------------------------------------------|
| `showtmuxpane` | Capture a pane's screen (read-only)                                                        |
| `sendtmuxpane` | Send keys / run a command in a pane (`sk`, `sksf`, `skf`)                                  |
| `tmcp`         | Copy files/directories between panes (`skf` only)                                          |
| `tmuxaddir`    | User-facing helper: types `/add-dir <target pane's cwd>` into the pane where it runs       |

- Call the scripts by name (`showtmuxpane`, `sendtmuxpane`, `tmcp`). If a name is not found in `$PATH`, use the symlink in this skill's directory by its absolute path: `~/.dotfiles/prompt/skills/showtmuxpane/script/<name>`. Do not use a relative `./script/...` path; the agent's working directory is not the skill directory.
- If the symlink's target is missing (broken link), stop and tell the user. Do not look for a copy elsewhere.
- **Never run `tmuxaddir`.** It types into the pane it is run from, which for the agent is its own input. It is not part of this skill's agent workflow.

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
  - Verify whether the `showtmuxpane` function is defined using `command -v showtmuxpane` or similar methods. If it is defined, utilize the `showtmuxpane` function to reference the output of a specific window. If it is not in `$PATH`, use `~/.dotfiles/prompt/skills/showtmuxpane/script/showtmuxpane` (symlink to the same script; see `# Helper scripts`).
  - Use the following format: `showtmuxpane <window name> -S <tail line count>`.
  - `showtmuxpane 2 -S -30` is equivalent to the following command:
    - `tmux capture-pane -t 2 -p -J -S -30 -E $(($(tmux display -p -t 2 '#{pane_height}') - 1))`
    - `-J` joins wrapped lines, so a narrow pane still returns each output line as one line. `-S` counts physical screen rows, not output lines, so a narrow pane needs a larger value (e.g. `showtmuxpane 2 -S -200 --tail 50` for the last 50 output lines).

  - Therefore, if neither the `showtmuxpane` command nor its symlink is available, use the following command instead. (Replace `<window number>` and `<tail line count>` with appropriate values.)
    - `tmux capture-pane -t <window number> -p -J -S <tail line count> -E $(($(tmux display -p -t <window number> '#{pane_height}') - 1))`


# SKILL OPTS
This is an optional string that can follow this command.

If no options are provided, the contents of window 2 will be displayed.

### First Option
The first option specifies the target tmux window (and optionally the pane) to display.
Options (`sk`, `sksf`, ...) may also come before the target (e.g. `;t sk .2`). Only a token matching one of the formats below is a target.

Accepted formats:
- `<window>` — target window N, pane 1 (e.g. `2` → window 2, pane 1).
- `<window>.<pane>` — target window N, pane M (e.g. `2.2` → window 2, pane 2).
- `.<pane>` — current window, pane M (e.g. `.2` → current window, pane 2; `.3` → current window, pane 3).
  - **"current window" means the window containing the pane where the AI agent itself is running** (the scripts resolve it internally from `$TMUX_PANE`). It does **NOT** mean the tmux client's currently active/visible window. Even if the user switches to another window after giving the command, the target window NEVER changes.
  - **Pass the `.pane` form to the scripts AS-IS** (`showtmuxpane .2`, `sendtmuxpane .2`). **NEVER resolve `.N` into an explicit `<window>.<pane>` yourself** (e.g. by querying the active window via `tmux display-message -p '#I'` and rewriting `.2` as `4.2`). The active-window value follows the user around; resolving it yourself silently retargets a completely different window. The scripts already resolve the window correctly — do not "help" them.
  - **Window numbers are NOT stable.** When a window is killed or moved, remaining windows may be renumbered (e.g. `renumber-windows on`: windows 1,2,3,4 → kill window 1 → old 2,3,4 become 1,2,3). A once-resolved target like `3.2` would then silently point at what used to be `4.2`. This is exactly why the user writes `.N`: it is re-resolved from the AI agent's own pane (`$TMUX_PANE`) on EVERY invocation, so it keeps tracking the correct window even after renumbering. Pass `.N` as-is every single time — NEVER resolve it once and reuse the resolved `<window>.<pane>` later in the session.
  - This applies to every script that takes a target: `showtmuxpane`, `sendtmuxpane`, `tmcp`.
- **The pane number is the fixed pane slot (`@pane_slot`), NOT tmux's `pane_index`.** It is the number shown in the status bar (`<window>.<slot>`). Existing panes keep their number when a new pane is split; a new pane takes the smallest free number in its window. The scripts resolve the slot internally — pass the number exactly as the user wrote it, and never translate it to/from `pane_index` yourself. If the slot does not exist, the scripts fail with `pane number is wrong`; then STOP and ask the user.

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
- Use it as context when interpreting the pane output or composing commands to send (especially with the `sk` or `sksf` option). For example, `(ssh win)` means the pane's shell is running on the remote host `win`, so any suggested or sent commands must be valid for that remote environment, not the local one.
- Options following the closing parenthesis (`sk`, `sksf`, `t`, `h`, ...) are parsed the same as usual.

##### Chained state: `(ssh <alias> - <command>)`
A description may express a **chained state** by joining steps with ` - `.

- `(ssh <alias> - <command>)` means: the pane connected to the `<alias>` host via ssh, **then** ran `<command>`, and is currently sitting in the resulting state.
  - example: `(ssh test - sudo su)` — connected to the `test` server, then obtained **root** privileges through `sudo su`. Any command sent to that pane therefore runs as root on `test`.
- Always compose commands against the **final** state, not just the first step.
  - Do NOT prefix `sudo` again when the pane is already root.
  - Do NOT assume a local path/binary exists just because it exists on the local machine.
- The same form applies to any environment chain, not only `sudo su`.
  - `(ssh db01 - mysql)` — connected to `db01`, then entered the `mysql` client. Send **SQL**, not shell commands.
  - `(ssh prod - docker exec -it api bash)` — a shell inside the `api` container on the `prod` host.

##### 🚨 Resolving an ssh alias: `ssh -G` ONLY 🚨

**NEVER read `~/.ssh/config`, `~/.ssh/known_hosts`, or ANY file under `~/.ssh/` to find out what an alias points to.**

- That directory holds highly sensitive data — private/public keys and connection info for unrelated servers — and reading it is blocked by design. Reading it (or trying to work around the block) is a security violation, exactly like capturing a non-specified pane.
- When you genuinely need the real host/port/user behind an alias (e.g. to judge whether a command is valid on that remote), use `ssh -G <alias>`:
  - `ssh -G <alias>` evaluates `Host` / `Match` blocks (including `Include`d files and wildcards) and **prints the final resolved config, then exits**. It opens **no network connection**, so it is safe and instant.
  - Filter to only what you need — never dump the whole output:
    - `/usr/bin/ssh -G win </dev/null | grep -Ei '^(hostname|port|user) '`
- NOTE: `ssh` may be defined as a **shell function** in the user's environment. Call the binary directly (`/usr/bin/ssh`), otherwise a non-TTY context fails with `tcgetattr: Operation not supported by device` (exit 255).
- Look up **only the alias the user actually named**. NEVER enumerate other hosts or list the aliases defined in the config.

- example
  - `;tm .4 (ssh win)` → `showtmuxpane .4` — pane 4 of the current window is a remote session connected via `ssh win`.
  - `;tm 3 (local zsh)` → `showtmuxpane 3` — window 3, pane 1 is a local zsh shell.
  - `;tm 2.3 (docker dreamdb)` → `showtmuxpane 2.3` — window 2, pane 3 is a shell inside the `dreamdb` docker container.
  - `;tm .5 (ssh test - sudo su)` → `showtmuxpane .5` — pane 5 of the current window is connected to the remote `test` host **and has already escalated to root via `sudo su`**.
  - `;tm .4 (ssh win) sk install gcc` → analyze pane 4 of the current window, then send commands appropriate for the remote `win` host via `sendtmuxpane .4`.

#### Command line syntax: `#` request, `|` multiple targets, multiple lines

##### `#` request text
- The first `#` **outside parentheses** starts the request text. Everything after it, including `|` and `#`, is request text, never a target, separator, or option.
- `|` and `#` inside parentheses belong to the pane description and are ignored for parsing.
- `#` is optional (legacy form: request text right after the targets/options). If that text contains `|` and the command string is clearly identifiable, proceed. Otherwise ask the user to re-enter it with `#` and end the response without running any tmux command. Even when it is identifiable, asking for `#` and stopping is allowed.

##### `|` multiple targets
- Targets that share the same options are joined with `|` on one line. `|` separates targets only outside parentheses and before the first `#`.
- Options on a line apply to every target on that line. Numeric option arguments (`t 10`, `h 5`, `-S -30`) are not targets.
- Targets that need different options must be written as separate `;t` lines. If one line mixes per-target options, ask.
- Call `showtmuxpane` / `sendtmuxpane` once per target, passing each `.N` as-is.

##### Multiple `;t` lines
- One message may contain several `;t` lines. Each line is an independent command, even though only the first one starts the message.
- A `#` request applies only to the target(s) on its own line, unless the request itself clearly refers to other panes (e.g. "compare the logs of both panes").
- A request for all targets is written as free text on a separate line (not a `;t` line).

##### Ambiguity → ask and stop
- tmux access is security-critical. If the targets, options, request scope, or destination pane of a command is ambiguous, do NOT run any tmux command. Ask the user to re-enter it precisely and end the response.

- example
  - `;t sk .2 #ps aux | grep java 돌려 줘` → target `.2`, request `ps aux | grep java 돌려 줘`
  - `;t sk .2 (ssh serv # haproxy lb server) #cat /etc/haproxy.conf 해봐.` → target `.2`, description `ssh serv # haproxy lb server`, request `cat /etc/haproxy.conf 해봐.`
  - `;t sksf .2 (ssh test server | checking) | .3 (ssh server1)` → `sksf` on both `.2` and `.3`
  - `;t sk .2 | .3 이 두 pane 에서 ps -aef | grep java 한 결과를 리턴해서 비교해 봐.` → the shell pipe is clearly part of the command, so running it is allowed; asking for `#` and stopping is also allowed.
  - Line-scoped `#` (`.3` only):
    ```
    ;t sk .2 (ssh a)
    ;t sk .3 (ssh b) #ps -aef 만 해라.
    ```
  - Request for all targets on a separate line (`.2` and `.3`):
    ```
    아래 pane에서는 ps -aef 만 해라.
    ;t sk .2 (ssh a)
    ;t sk .3 (ssh b)
    ```

### Other Option

Options for tmux capture-pane may be passed through directly.
Additionally, based on the contents of the pane, instructions such as "Analyze the logs." or "Identify the issue based on the error logs." may be given.

#### sendkeys or sk

If none of `sendkeys`, `sk`, `sksf`, or `skf` is provided, only the `capture-pane` command should be executed by default. (Commands such as `send-keys` must never be executed.)
If `sendkeys` or `sk` is provided, a specific tmux window/pane can be manipulated through the `sendtmuxpane` command. `sksf` enables the same interaction with the additional restrictions in the `sksf (sendkeys safe)` section below. `skf` enables the same interaction as `sk` plus file transfer between the specified panes with `tmcp` (see the `skf (sendkeys + file transfer)` section below).

##### `sendtmuxpane` command
  - `sendtmuxpane` is available in `$PATH` by default (`~/.dotfiles/bin/sendtmuxpane`). If not available, use `~/.dotfiles/prompt/skills/showtmuxpane/script/sendtmuxpane` instead (symlink to the same script; see `# Helper scripts`).
  - Usage: `sendtmuxpane <window number>[.<pane number>] [tmux send-keys options...]`
    - The first argument specifies the target window (e.g., `2` for window 2, `2.2` for window 2 pane 2, or `.2` for current window pane 2).
    - The remaining arguments are passed directly as `tmux send-keys` options.
  - Run mode: `sendtmuxpane -w [--timeout <sec>] <target> '<command>'` (see the `-w (--write) run mode` section below)
  - `sendtmuxpane` automatically detects and cancels copy-mode on the target pane before sending keys. No manual copy-mode check is required when using `sendtmuxpane`.

##### `-w` (`--write`) run mode
  - **Allowed under `sksf` as an explicit exception:** the helper's own capture files are exempt, but `<command>` must still satisfy every `sksf` restriction (see the `sendtmuxpane -w` capture-file exception in the `sksf` section).
  - Usage: `sendtmuxpane -w [--timeout <sec>] <target> '<command>'`
    - `-w` (or `--write`) MUST be the first argument. `--timeout <sec>` works ONLY right after `-w` (default 30 seconds, wall-clock upper bound).
    - `<command>` is a single string argument.
  - Behavior: runs `<command>` in the target pane, waits for completion, then writes **only the command's output** to stdout AND `/tmp/sendtmuxpane-<uid>/output.txt` (`<uid>` = `id -u` of the user running the helper).
    - `/tmp/sendtmuxpane-<uid>/output.txt` is **overwritten on every run** (previous content is discarded).
    - The capture directory is owner-only (`700`) and its files are `600`, because they hold raw command output (possibly secrets).
    - If the helper fails with `ERROR: unsafe capture directory` (the path is a symlink or owned by another user), stop and report it to the user. Do not delete, move, or chmod that path yourself.
    - The pane screen keeps displaying the output as usual (output is copied via `pipe-pane`, not intercepted).
    - The ONLY keys sent to the pane are `<command>` + Enter. No markers/wrappers are injected.
    - Sequence: type `<command>` → wait until its echo is rendered in the pane (max 3s, then proceed anyway) → start collection → press Enter. The input echo is excluded from collection, so commands longer than the pane width (which shells wrap with ` \r` / redraws) are still extracted correctly.
    - Output is streamed to a file, so large outputs (thousands of lines) are saved without the screen-history truncation of `capture-pane`, independent of the pane size. **Use this mode to collect large command outputs** (install logs, build logs, log queries) instead of `showtmuxpane`.
    - Width-aware programs (`ps` without a pipe, `systemctl status`, etc.) still truncate their own output to the pane width; append `| cat`, `--no-pager`, or `-ww` when full lines matter.
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

##### sksf (sendkeys safe)

- `sksf` is a restricted form of `sk`. It enables send-keys by itself; adding `sk` is unnecessary. It inherits `sk`'s exact-target, subsequent-interaction, and result-checking rules, subject to the restrictions below. If both options are present, **`sksf` takes precedence**.
- **Except for the explicit `make` build and `sendtmuxpane -w` capture-file exceptions below, NEVER execute commands or send interactive input that creates, modifies, overwrites, appends to, moves, renames, or deletes files/directories, or changes their metadata/permissions.** This applies to local and remote files, including temporary files. Judge the complete command and its effects, not just the command name.
- Forbidden operations include:
  - File transfer/copy/move/delete commands: `scp`, `cp`, `mv`, `rm`, `unlink`, `tmcp`, and file-writing `rsync` operations.
  - File creation or metadata changes: `touch`, `mkdir`, `chmod`, `chown`, and `truncate`.
  - In-place edits or explicit file writes: `sed -i`, `sed`'s `w` command, `perl -i`, editor save commands, and scripts that write/delete files (including Python or shell scripts).
  - File-writing redirection such as `echo "test" > output.txt`, `>>`, `2>`, `&>`, or `<>`; writing through `tee`, `dd`, or similar tools is also forbidden.
  - Commands whose effects include file writes, such as package installation (including `apt`, `yum`, and `dnf` installation commands), builds that generate artifacts (except the `make` build exception below), archive extraction, and downloads saved to disk. Installing compiled software, including `make install` and `sudo make install`, is forbidden.
  - SQL that changes database data, schema, permissions, or settings: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `CREATE`, `ALTER`, `DROP`, `GRANT`, `REVOKE`, and settings-changing `SET` statements, including session-only settings. The same prohibition applies through database clients, APIs, Python or other scripts, and stored procedures/functions; do not assume a statement is read-only merely because it starts with `SELECT`.
  - Terminating, stopping, pausing, starting, or restarting services, whether through service managers (`systemctl`, `service`, etc.), containers, scripts, APIs, or process signals. This includes `kill` / `pkill` and interactive input such as Ctrl-C when it would stop a running service.
  - Downloading external scripts and executing them, including `curl -sk "url" | sh -`, `wget` piped to an interpreter, command/process substitution, and saving a script before executing it. This applies to shell, Python, and other interpreters even when no script file is saved locally. Downloading source code, compiling it, and then installing it is also forbidden.
- **`make` build exception:** `make` used solely for compilation/building is allowed, including creation or updates of normal build artifacts. Confirm the selected target and its recipes only perform the permitted build; a command named `make` is not automatically safe. This exception does not permit installation (`make install`), external-script download/execution, database or service changes, or unrelated file manipulation. If the recipes' effects are unclear, do not execute them.
- Do not bypass these restrictions through aliases, functions, scripts, command substitutions, pipelines, `sh -c`, `sudo`, SSH/container commands, another tool, or another pane. Check every component of a compound command. If its effects on files, databases, services, or external-code execution are unclear, do not execute it; explain the uncertainty and use a known read-only alternative when available.
- Read-only commands and transformations that only print to the terminal are allowed, such as `pwd`, `ls`, `cat`, `grep`, `head`, `tail`, and `sed 's/old/new/g' input.txt`. Read-only SQL queries and service-status inspection are also allowed when they do not cause prohibited effects. Read-only input redirection (`cat < input.txt`) and pipelines are allowed only when every component complies with these restrictions, including the explicit `make` build exception.
- **`sendtmuxpane -w` capture-file exception:** `sendtmuxpane -w` / `--write` is allowed under `sksf`. Its only file writes are the helper's own capture files on the machine where the helper runs, inside the owner-only directory `/tmp/sendtmuxpane-<uid>/` (created if missing): `output.txt` (overwritten every run) and the temporary raw file `.raw_<pid>` (deleted on exit). Only these helper-managed files are exempt.
  - The `<command>` sent with `-w` must still satisfy every `sksf` restriction above. The exception never covers files, databases, or services affected by the command itself.
  - Do not add redirection or `tee` to `<command>`, and do not copy, move, or edit `/tmp/sendtmuxpane-<uid>/output.txt` afterward (reading it is allowed). Other file-backed capture (manual `pipe-pane`, `capture-pane` redirected to a file, `save-buffer`) remains forbidden.
  - Plain `sendtmuxpane` followed by `showtmuxpane` / `capture-pane -p` remains available, and is required for interactive programs or commands that do not finish on their own.
- Keep `sksf` active for subsequent command-related interactions until the user explicitly switches out of safe mode. A request for a prohibited operation or a generic confirmation does not silently disable it; explain that the operation is prohibited under `sksf` and do not execute it.
- These are agent execution rules in this skill, not a shell sandbox or a command-filtering flag implemented by `sendtmuxpane`. Do not pass `sksf` to the helper scripts.
- Examples:
  - `;tm .2 sksf` → inspect the specified pane and conduct subsequent commands there under the restrictions above.
  - `;tm .4 (ssh win) sksf inspect the logs` → send read-only log inspection commands to `.4` in the existing remote session.
  - Allowed: `sendtmuxpane .2 -l 'cat app.log'` followed by `sendtmuxpane .2 Enter` and `showtmuxpane .2 -S -20`.
  - Allowed: `sendtmuxpane -w .2 'cat app.log'` (output collected through the helper's capture file).
  - Forbidden: `scp app.conf host:/tmp/`, `rm app.log`, `sed -i 's/old/new/g' app.conf`, `echo "test" > output.txt`, `cat app.log | tee copy.log`, and `sendtmuxpane -w .2 'cat app.log > copy.log'`.
  - Allowed: read-only `SELECT` / `SHOW` queries, `systemctl status nginx`, and `make` after confirming its recipes only build.
  - Forbidden: `UPDATE users SET active = 0`, `SET GLOBAL max_connections = 200`, `systemctl restart nginx`, `curl -sk "url" | sh -`, `make install`, and `apt install gcc` / `yum install gcc` / `dnf install gcc`.

##### skf (sendkeys + file transfer)

- `skf` enables everything `sk` allows (send-keys to the specified targets, with the same exact-target, subsequent-interaction, and result-checking rules) **plus** file/directory transfer between the specified target panes with the `tmcp` helper.
- **`tmcp` may be used ONLY when `skf` is given.** Do not run `tmcp` under `sk` alone. Under `sksf`, `tmcp` is forbidden because it writes files.
- If `skf` and `sksf` are both present, the options conflict: ask the user to re-enter the command and stop without running any tmux command or `tmcp`.

**`tmcp` command**
- Location: `~/.dotfiles/bin/tmcp` (in `$PATH`). If not available, use `~/.dotfiles/prompt/skills/showtmuxpane/script/tmcp` (symlink to the same script; see `# Helper scripts`). Run it in the agent's own local shell, on the machine where the tmux server runs; it inspects the panes' local ssh processes.
- Usage: `tmcp <src target>:<path> <dst target>[:<path>]`
  - Targets use the same notation as `showtmuxpane` / `sendtmuxpane` (`2`, `2.2`, `.2`; the pane number is `@pane_slot`). **Pass `.N` as-is**: `tmcp` resolves it from `$TMUX_PANE` exactly like the other scripts. NEVER rewrite `.N` into `<window>.<pane>`.
  - Both the source pane and the destination pane MUST be targets the user specified on the command line. NEVER transfer from or to any other pane.
  - The agent's own pane cannot be a source or destination (`tmcp` refuses it).
  - Example: `tmcp .3:/opt/app/conf.tgz .2:/opt/app/`, `tmcp .3:~/logs .2`
- Path rules are identical to GNU `cp -r` / `scp -r`:

  | Destination                      | Source is a file                     | Source is a directory            |
  |----------------------------------|--------------------------------------|----------------------------------|
  | Existing directory               | Copied inside with the original name | Copied inside (merged if exists) |
  | Existing file                    | Overwritten (keeps its permissions)  | Error                            |
  | Non-existent path                | Copied with that name (rename)       | Copied with that name (rename)   |
  | Non-existent path ending in `/`  | Error                                | Created with that name           |
  | Parent directory missing         | Error                                | Error                            |

  - Relative paths are resolved by each pane's shell against its current directory; `~` is that pane user's home. Omitting the destination path copies into the destination pane's current directory.
  - The source is never deleted (copy only). Parent directories are never created.
  - Top-level source symlinks are followed; symlinks inside a directory are copied as symlinks (`cp -rH`).
- How it works (what to expect):
  - Data flows over each pane's existing ssh connection (ControlMaster reuse), not through the tmux screen. The plan line shows `기존 연결 재사용` (no re-authentication) or `새 연결: 인증 필요할 수 있음`. The agent cannot answer a password prompt; if authentication fails, tell the user to reconnect the pane with the ControlMaster setting or to run `tmcp` themselves.
  - Files are read and written by each pane's current shell, so a pane that switched user (e.g. `(ssh test - sudo su)`) transfers with that user's privileges.
  - `tmcp` types exactly one line, ` sh </tmp/tmcp.XXXXXX/<token>.s`, into BOTH panes and presses Enter. Copy-mode is cancelled automatically.
  - Supported: remote ssh panes (including wrappers such as `zssh`), local panes, and any pane shell (bash, zsh, dash, csh, fish).
- Preconditions: check them before running. If any is not met, do NOT run `tmcp`; explain why and ask the user.
  - Both panes are at an idle shell prompt (no running command, empty input line). Do not use `tmcp` if a pane shows a running command or full-screen app, or if its description chain ends in a non-shell program (e.g. `(ssh db01 - mysql)`).
  - Each pane's shell runs on the host its ssh connection reached. Chains that enter another filesystem are NOT supported: nested ssh `(ssh a - ssh b)`, containers `(ssh prod - docker exec -it api bash)`, chroot. `sudo su` / `su -` chains ARE supported.
  - The source path and the destination are clear. If the request is vague (e.g. "필요한 파일"), identify the files from the conversation or from read-only inspection of the specified panes (`showtmuxpane`, read-only commands via `sendtmuxpane`). If it is still unclear, list the candidates and ask.
  - If the transfer would overwrite an existing file (or replace files while merging a directory), confirm with the user first unless the request explicitly asks to overwrite.
  - "옮겨" / "move" means copy with `tmcp`. Deleting the source afterwards is a separate operation: do it only when the user explicitly asks, and confirm first.
  - Not supported in the SSH + `LC_TMUX_SOCKET` mode (the agent on a remote host controlling local tmux), or for `mosh` / `tssh` panes. Tell the user instead of trying.
- Result handling:
  - Exit 0 with `완료 (...)` means success. Report what was copied to where.
  - Non-zero: the `tmcp: ...` lines give the cause (cp-like messages). Further details (e.g. tar errors) may only appear on the pane screen; check them with `showtmuxpane <target> -S -20` on the specified pane.
  - Do not add `sleep`; `tmcp` waits for completion itself. Use a longer tool timeout for large transfers.
- Examples
  - `;t skf .2 (ssh testvbox) | .3 (ssh serv) # .3 에서 필요한 파일을 .2 로 옮겨.`
    → targets `.2` and `.3` with `skf`. Determine the needed files from the conversation or read-only inspection of `.3` (ask if unclear), check the preconditions, then run `tmcp .3:<path> .2[:<path>]`.
  - `;t skf .2 (ssh test - sudo su) | .3 (ssh serv - sudo su) # .3 의 /opt/a.tgz 를 .2 의 /opt 로 옮겨.`
    → `tmcp .3:/opt/a.tgz .2:/opt/` (both panes are root, so `/opt` is readable and writable).
  - `;t skf .2 (ssh a) | .3 (ssh b) # .3 의 /home/src/test 디렉토리를 .2 의 /backup/test_old 로 복사.`
    → `tmcp .3:/home/src/test .2:/backup/test_old` (copied as `test_old` if it does not exist; copied into it as `test_old/test` if it is an existing directory).
  - Forbidden: `tmcp` under `sk` or `sksf`; `tmcp` from or to a pane the user did not specify; `tmcp` into a pane whose description ends in `mysql`, `docker exec`, or a nested `ssh`.

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

