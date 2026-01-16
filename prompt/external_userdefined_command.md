
### User-Defined Category: Other (Coding)
- When receiving the command **;irefactor**, you must separate the selected logic into a function or refactor it.
  - Use `refactor` sub-agents.
- When receiving the command **;ireview**, This needs to be reviewed. (The subject of the review can vary, such as code, software architecture, etc.)
  - The input can be in the form `/review @[file] [msg]`.
    The `[msg]` option is for user-defined requests.
    Both the msg and file fields may or may not be provided.
  - If the `msg` field is provided, proceed with reviewing to satisfy those requirements.
    If the `msg` field is not provided, Review comprehensively.
  - If a `file` mentioned with the @ symbol is provided, Review only that file.
    If files related to that file need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.
  - If no `file` is mentioned with the @ symbol, review all files in the current directory and its subdirectories based on where the agent is located.
    If files in parent directories or other directories need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.
  - If necessary, Use `CodeReviewer` and `ArchitectReviewer`.
    When there is a request to use static analysis tools, analyze and review the code using static analysis tools.
- When receiving the command **;itest** or **;itests**, you must create unit test code for the selected code, function, or file. (Mainly create boundary value tests.) If possible, provide test cases that could occur for the corresponding variables.
  - In Claude Code, you must use **tester** agent unconditionally. (서브 에이전트 또는 커스텀 에이전트를 사용할 수 있다면 반드시 tester 에이전트를 사용해야 합니다.)

- When receiving the command **;ssh**, If you are trying to execute a bash command, execute the command as `exec ssh <host/destination> '<command>'` or `ssh <host/destination> "<command>"`..
  - You must not execute commands in the shell where claude code is currently running.
  - Connect to the destination via ssh, then execute the command.
  - If you cannot execute the command, output "Error: Don't execute command."
  - If only the Host is entered, connect to the host via SSH and execute the subsequent commands.
  - Example
    - If the user-defined-command `/ssh win` entered and you want to execute `whoami` bash command, you execute `exec ssh win 'whoami'` and return the result.
      - ssh config file is `~/.ssh/config`
    - If the user-defined-command `/ssh root@192.168.0.5` entered and you want to execute `ls -al` bash command, you execute `exec ssh root@192.168.0.5 'whoami'` and return the result.
    - If the user-defined-command `/ssh test install gcc (config file is current directory, sshconfig.conf name.)` entered, You must proceed as below.
      - Assuming that the server is an Ubuntu server with apt installed, the command to install gcc is `apt-get install -y gcc`.
        Also, since the user indicated that the ssh config file is located at sshconfig.conf in the current directory, you need to add the -F option like `exec ssh -F "$(pwd)/sshconfig.conf"`.
        Therefore, you should execute the following command: `exec ssh -F "$(pwd)/sshconfig.conf" test "apt-get install -y gcc"`

### User-Defined Category: Council
| Agent Name | Command | Parallel Agents |
|------------|---------|-----------------|
| `all` | Request in parallel using both `CodexCouncilAgent` and `GeminiCouncilAgent` subagents. | `CodexCouncilAgent` / `GeminiCouncilAgent` |
| `gem` / `gemini` | `echo "[input]" \| gemini --model pro 2>/dev/null` | `GeminiCouncilAgent` |
| `codex` | `codex exec [input]` | `CodexCouncilAgent` |

- When receiving the command **;ag `Agent Name`** or **;agents `Agent Name`**, execute the commands corresponding to each `Agent Name` by referring to the table.
  - `[input]` should contain the content entered by the user.
    - example
      - `;ag gem` -> execute `gem` / `gemini` agnet command.
        - `;ag gem Hello, tell me today's weather.` -> `echo 'Hello, tell me today's weather' | gemini --model pro 2>/dev/null`
  - If special characters such as `"`, `'` are included in `[input]`, proceed by escaping them, or save the `[input]` phrase as a file and make the request using the cat command.
    - example: `cat you_created_file.txt | gemini --model pro 2>/dev/null`
  - `p` or `parallel` option input, Refer to the table and execute the subagents corresponding to each option in parallel.
    - example: `;ag p gem` -> use `GeminiCouncilAgent` subagent.
    - example: `;ag p all` -> use `CodexCouncilAgent` / `GeminiCouncilAgent` subagent.

### AITODO user-defined commands
Refer to the `AITODO` section in `ETC` for the `aitodo.md` file structure and detailed information about it.

- When receiving the command **;aitodo**, find and read the `aitodo.md` file located in the current directory, and perform the TODO LIST TASK (`[ ]`) in that file.
  - The `-n` or `-next` option can be added after the `;aitodo` command and can be combined with other options (e.g., `;aitodo -next`, `;aitodo -n task 1`, `;aitodo -next task 1 m 2`).
    - When this option is provided, after completing each mission, you MUST ask the user "Continue to the next mission?" before proceeding.
    - Wait for the user's response:
      - If the user responds positively (e.g., "yes", "ok", "continue", "ㅇㅇ", ";dd"), proceed to the next mission.
      - If the user responds negatively (e.g., "no", "stop", "ㄴㄴ", ";ss"), stop execution and do not proceed to the next mission.
    - This option overrides the default behavior of automatically proceeding to the next mission.
    - **End-of-task behavior:**
      - If a specific task was specified (e.g., `;aitodo task 1 -next`) and all missions in that task are completed, do NOT ask for confirmation. Simply report that all missions in the task have been completed.
      - If no specific task was specified (e.g., `;aitodo -n`) and all missions in the current task are completed, check if there are remaining tasks with unresolved missions. If so, ask: "All missions in the current task are completed. Continue to the next task?"
    - In case of mission failure (refer to the `##### Mission Fail` content in the `### aitodo.md` section.)
  - The `-nt` option can be added after the `;aitodo` command and can be combined with other options (e.g., `;aitodo -nt`, `;aitodo -nt task 1`).
    - This option cannot be used together with the `mission` option. (The option contents are contradictory.)
      - ⚠️ CRITICAL: Therefore, if the `-nt` option is entered together with the `m` / `mission` option, output `wrong options` and do not proceed with the `;aitodo` command.
    - This option is similar to the `-n` / `-next` option, but the scope is different. (The {`-n`/`-next`} option asks per mission unit, while the {`-nt`} option asks per task unit)
    - When this option is provided, after completing each task, you MUST ask the user "Continue to the next task?" before proceeding.
    - Wait for the user's response:
      - If the user responds positively (e.g., "yes", "ok", "continue", "ㅇㅇ", ";dd"), proceed to the next task.
      - If the user responds negatively (e.g., "no", "stop", "ㄴㄴ", ";ss"), stop execution and do not proceed to the next task.
    - **End-of-task behavior:**
      - If a specific task was specified (e.g., `;aitodo task 1 -nt`) and all missions in that task are completed, do NOT ask for confirmation. Simply report that all missions in the task have been completed.
      - If no specific task was specified (e.g., `;aitodo -nt`) and all missions in the current task are completed, check if there are remaining tasks with unresolved missions. If so, ask: "All missions in the current task are completed. Continue to the next task?"
    - In case of mission failure (refer to the `##### Mission Fail` content in the `### aitodo.md` section.)
  - Don't be case sensitive to filename. (`aitodo.md`, `AITODO.md`, `AItodo.md` ... etc.)
  - **⚠️ CRITICAL**: When processing missions, you MUST follow "Perform → Immediately mark [x] → Next mission" order. Batch processing is PROHIBITED. (Details: See `### aitodo.md` section)
  - If subcategories task name or task number is entered after the `;aitodo` command, only proceed with the TODO LIST TASK (`[ ]`) for that specific Task.
    - Instead of `task name or number`, it may be entered in a format that includes the todo file path and line. (example: ";aitodo `@path/to/aitodo.md#L23`" or ";aitodo `@./aitodo.md:23`" or ";aitodo `@./aitodo.md#L23-30`" etc.)
      - In this case, instead of searching for the TODO file, it directly accesses the mentioned TODO file path and line.
        - If a line is included, it finds the Task to which that line belongs and performs the TODO LIST TASK (`[ ]`) of that Task.
        - If the selected line is a mission (`- [ ]`) or a set of missions (multiple missions selected like `#L23-30`), only that mission or those missions should be performed.
      - After the mentioned TODO file and line are entered, the mission option may be additionally entered. (example: ";aitodo `@./aitodo.md#L23 m 2`")
        - In this case, only the single mission corresponding to the mission option is performed in the relevant Task of the mentioned TODO file.
      - `t` is an abbreviation for `task`. Therefore, `;aitodo t 1` is the same as `;aitodo task 1`.
  - mission is optional. ex: `;aitodo task 1 mission 1`
    - The mission option can be abbreviated with the characters `m` or `mi` (e.g. `;aitodo task 1 m 2`).
    - The mission option refers to a single `- [ ]` item within a Task in the aitodo.md file.
    - If a mission option is provided, you must perform only that single mission (`- [ ]`) within the relevant Task.
    - When a mission is completed, **immediately** mark it as complete with `- [x]` **before starting the next mission**.
    - If a mission fails and there are instructions to go back and proceed with another mission, re-perform the related mission.
      - example
        ```markdown
          ### Task 1: task name
          - [ ] 1. make a logic to do something.
          - [ ] 2. Verify the performance. The logic you created must produce results within 1 second.
            - If mission 2 fails, go back to mission 1 and re-perform it.
        ```
    - If there is no numbering indication for missions (- [ ] 1. ...something..., - [ ] 2. ...something... ...), they are in the order the missions were created.
      - example
        ```markdown
          ### Task 1: task name
          - [ ] make a logic to do something.
          - [ ] Verify the performance. The logic you created must produce results within 1 second.
        ```
        - In this case, If `;aitodo task 1 m 2` is entered, the second mission (Verify the performance.) will be performed.
    - After the m option, a number may not be entered.
      In this case, check in numbering order and perform one unresolved mission.
      If there are related missions, perform those missions as well.
      - example
        ```markdown
          ### Task 1: task name
          - [x] make a logic to do something.
          - [ ] Verify the performance. The logic you created must produce results within 1 second.
            - If this mission fails, go back to mission 1 and re-perform it.
          - [ ] Write a report on the performance verification results.
        ```
      - Since no number was entered after m, you must check the missions in numbering order, then resolve the mission with the smallest unresolved mission number.
        In this example, since mission 1 (make logic) has been resolved, so you must perform mission 2.
        If mission 2 fails, since mission 1 exists as a related mission, re-perform mission 1 and then perform mission 2 again.
        If mission 2 succeeds, mark mission 2 as complete and end the response.
        Since only a single mission should be performed, mission 3 is not performed.
  - If there is no `aitodo.md` file, return the message "NOT EXIST aitodo.md".

- When receiving the command **;cai**, modify the written file to match the file format of `aitodo.md`, and save it as the `aitodo.md` file in the directory where you are currently located.
  - If the `aitodo.md` file already exists, delete all the contents of the existing file and overwrite it with the newly written content.
    - When the `a` or `add` option is added after the **;cai** command (ex: `;cai a`), do not delete the content and overwrite it; instead, add content to the existing aitodo.md file.
      - If the aitodo.md file does not exist, create a new one.
  - The following phrase must be included at the very top of the file: (The path of the original file to be converted must be specified.)
    ```
    - [Converted by file](file:///path/to/original_file.md)
      - For more details, refer to the file.

    ```
  - Write the commit message in Korean whenever possible.
  - When the `nci` (no commit) option is added after the **;cai** command (ex: `;cai nci`), do not add a commit message when converting to the `aitodo.md` file.
  - Utilize the `Divide and Conquer` problem-solving approach. When there are very many or extensive requirements, you must appropriately separate them into detailed subtasks and divide them into `Tasks`/`Missions` to solve the problem.

- When receiving the command **;maketodo**, Analyze user requirements to create/add an aitodo file.
  - When creating/adding an `aitodo.md` file, you must strictly adhere to the `aitodo.md` file format and structure.
    - If the `aitodo.md` file does not exist, create the file.
    - If the `aitodo.md` file exists, add content to it.

  - If the `t` / `task` / `m` / `mission` options are not entered, analyze the requirements, divide them appropriately into subtasks, and add detailed missions for each Task.
    - Utilize the `Divide and Conquer` problem-solving approach. When there are very many or extensive requirements, you must appropriately separate them into detailed subtasks and divide them into `Tasks`/`Missions` to solve the problem.
  - If the `t` / `task` option is additionally entered, analyze the requirements, add a **single task**, and add detailed missions to be performed in that task.
  - If the `m` / `mission` option is additionally entered, analyze the requirements and add a **single mission**.
    - The `m` / `mission` option must be entered together with the `t` / `task` option.
      - The mission to be added should be added to the task of the entered `t` / `task`.

