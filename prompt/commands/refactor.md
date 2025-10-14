
# This is user-defined command
This is **user-defined command**.
You must refactor the code.

The input can be in the form `/refactor @[file] [msg]`.
The `[msg]` option is for user-defined requests.
Both the msg and file fields may or may not be provided.

If the `msg` field is provided, proceed with refactoring to satisfy those requirements.
If the `msg` field is not provided, please refactor comprehensively.

If a `file` mentioned with the @ symbol is provided, please refactor only that file.
If files related to that file need to be refactored, proceed with the refactoring and additionally report the files that were refactored.

If no `file` is mentioned with the @ symbol, refactor all files in the current directory and its subdirectories based on where the agent is located.
If files in parent directories or other directories need to be refactored, proceed with the refactoring and additionally report the files that were refactored.

- Please separate the code for functions that perform two roles so that each function adheres to the Single Responsibility Principle.
- Use appropriate design patterns to increase maintainability.
- Restructure the code to minimize duplication.

# Command behavior
- You must use refactorer and code-reviewer agent unconditionally.

Before modifying code, use the refactorer to establish a plan and execute it.
After code modifications are complete, verify the code through the code-reviewer agent.
If the code-reviewer agent's approval conditions are not satisfied, explain the reasons for the disapproval. (No additional work such as
refactoring will be performed thereafter.)
