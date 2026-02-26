---
name: make-aitodo
description: "Analyze user requirements to create/add an aitodo file. (This skill must only be used when there is an explicit call. (example: ;iskill make-aitodo))"
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


# TODO FILE FORMAT & RULES
**⚠️ CRITICAL: Refer to the `custom_file_format.md` file.**
@custom_file_format.md


# SKILL behavior
Analyze user requirements to create/add an aitodo file.
- When creating/adding an `aitodo.md` file, you must strictly adhere to the `aitodo.md` file format and structure.
  - If the `aitodo.md` file does not exist, create the file.
  - If the `aitodo.md` file exists, add content to it.

  - Utilize the `Divide and Conquer` problem-solving approach. When there are very many or extensive requirements, you must appropriately separate them into detailed subtasks and divide them into `Tasks`/`Missions` to solve the problem.

# SKILL OPTS

This is an optional string that can follow this command.
Options list: (`t`, `task`), (`m`, `mission`)

- If the `t` / `task` / `m` / `mission` options are not entered, analyze the requirements, divide them appropriately into subtasks, and add detailed missions for each Task.

### Option: t, task
- If the `t` / `task` option is additionally entered, analyze the requirements, add a **single task**, and add detailed missions to be performed in that task.

### Option: m, mission
- If the `m` / `mission` option is additionally entered, analyze the requirements and add a **single mission**.
  - The `m` / `mission` option must be entered together with the `t` / `task` option.
    - The mission to be added should be added to the task of the entered `t` / `task`.

