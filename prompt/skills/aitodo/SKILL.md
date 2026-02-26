---
name: aitodo
description: Execute TODO tasks from aitodo.md file step by step. Use when processing task lists with mission tracking, completion marking, and optional task/mission targeting.
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(c

# SKILL Arguments
$ARGUMENTS

This command can take options (`-n` / `-next` / `-nt` / `t` / `task` / `m` / `mission`).
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below. (`#SKILL OPTS` section)


# TODO FILE FORMAT & RULES
**⚠️ CRITICAL: Refer to the `custom_file_format.md` file.**
@custom_file_format.md


# SKILL behavior
Find and read the `aitodo.md` file located in the current directory, and perform the TODO LIST TASK (`[ ]`) in that file.
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
- mission is optional. example: `;aitodo task 1 mission 1`
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


# SKILL OPTS
This is an optional string that can follow this command.
Options list: (`-n`, `-next`), (`-nt`)

### Option: -n, -next
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

### Option: -nt
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
