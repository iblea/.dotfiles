---
name: convert-aitodo
description: "Convert (plan) file to `aitodo.md` format. (This skill must only be used when there is an explicit call. (example: ;iskill convert-aitodo))"
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
Modify the written file to match the file format of `aitodo.md`, and save it as the `aitodo.md` file in the directory where you are currently located.

- If the `aitodo.md` file already exists, delete all the contents of the existing file and overwrite it with the newly written content.
- The following phrase must be included at the very top of the file: (The path of the original file to be converted must be specified.)
  ```
  - [Converted by file](file:///path/to/original_file.md)
    - For more details, refer to the file.

  ```

- Write the commit message in Korean whenever possible.
- Utilize the `Divide and Conquer` problem-solving approach. When there are very many or extensive requirements, you must appropriately separate them into detailed subtasks and divide them into `Tasks`/`Missions` to solve the problem.


# SKILL OPTS
This is an optional string that can follow this command.
Options list: (`a`, `add`), (`nci`)

### Option: a, add
- When the `a` or `add` option is added after the **;cai** command (example: `;cai a`), do not delete the content and overwrite it; instead, add content to the existing aitodo.md file.
  - If the aitodo.md file does not exist, create a new one.

### Option: nci
- When the `nci` (no commit) option is added after the **;cai** command (example: `;cai nci`), do not add a commit message when converting to the `aitodo.md` file.
