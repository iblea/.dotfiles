---
name: itest
description: Generate unit test code for selected code, functions, or files. Use when creating boundary value tests and comprehensive test cases for variables.
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
- You must use tester agent unconditionally.
you must create unit test code for the selected code, function, or file. (Mainly create boundary value tests.) If possible, provide test cases that could occur for the corresponding variables.

# SKILL OPTS
This is an optional string that can follow this command.

- The input can be in the form `/itest @[file] or @[file:line]`.
  - Write unit tests for and validate the logic and functions present in the specified file, line, or range.
