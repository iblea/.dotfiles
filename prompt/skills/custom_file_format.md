# CUSTOM FILE FORMAT (aitodo.md, build.md ...)

### aitodo.md (AITODO.md)
##### aitodo filename
- `./aitodo.md` (`AITODO.md` (Don't be case sensitive to filename.)) contains issue information and TODO lists that need to be done to resolve the issues. If there are issues written in the `aitodo.md` (`aitodo.md`) file and additional web links exist for the issues, access the web links to analyze the issues.

##### File Format
- The TODO LIST exists under the major category `# TODO LIST`, and each task can be further divided into subcategories (`###`).
- Each task(`###`) contains missions you must perform in the form of `- [ ]`.
- Detail missions that provide a detailed description of each mission's content(`- [ ]`) may exist.

##### Mission Completed (marking mission rule)
- The TODO LIST shows the tasks you need to work on in checkbox (`[ ]`) format.
  **Mission Processing Order (MUST FOLLOW - Do NOT batch missions):**
  1. Perform Mission 1
  2. Mark Mission 1 as completed (`[x]`) in aitodo.md - **IMMEDIATELY after completion**
  3. Perform Mission 2
  4. Mark Mission 2 as completed (`[x]`) in aitodo.md - **IMMEDIATELY after completion**
  5. Repeat until all missions are done...

  **PROHIBITED:** Processing multiple missions first and marking them completed later in batch. (do step-by-step.)
  **REASON:** If a mission fails mid-task, progress tracking becomes impossible.

- Each mission MUST be processed **step by step**, NEVER in **batch**.
  - **⚠️ CRITICAL: You must never ignore this rule, such as proceeding with batch processing based on arbitrary judgment. (This is the most important rule in this aitodo.md section.)**
    - Example of absolutely prohibited behavior: Batch processing multiple similar missions at once and then marking multiple missions all at once.
  - Even if tasks are similar, you must NEVER batch process them.
  - Examples:
    - Example 1
      - In the following example, you must NEVER create the file and write code at the same time.
      - Since Mission 1 and Mission 2 are separated, you must first create an empty file `test.py`, mark the mission as complete, and then proceed to the next mission.
      ```
      - [ ] Create File `test.py`
      - [ ] Make unit tests for the Agent class.
      ```
    - Example 2
      - In the following example, you can create the file and write code at the same time.
      - This is because there is an instruction in a single mission to create the `test.py` file and write code simultaneously.
      ```
      - [ ] Create File `test.py` and Make unit tests for the Agent class.
      ```

- Set only the completion mark (`[x]`).
  🚫 **Do not write** any additional descriptions (documenting the results) or details about the completion of the task on `aitodo.md`.
  - example
    - You are on this mission.
      ```markdown
      - [ ] 1. solve this mission. Improve the performance of this code.
        - detail description 1
        - detail description 2
        - detail description 3
      ```
    - You have completed your mission successfully.
      After completing the task, only the `- [ ]` symbol must be marked with an x. -> `- [x]` (If you fail the mission, you should **never mark it**.)
      Work as below.
      🚫 **You must not add, delete, or modify anything else.**
      ```markdown
      - [x] 1. solve this mission. Improve the performance of this code.
        - detail description 1
        - detail description 2
        - detail description 3
      ```

##### Task Commit
- When all tasks in a subcategory are completed, perform `git commit` based on `######` marker:
  | Marker | Behavior |
  |--------|----------|
  | `###### [commit message]` | Commit with this message when all tasks completed |
  | `###### NO COMMIT` | Do not commit even if all tasks completed |
  | `###### AUTO COMMIT` | Create commit message automatically and commit |
  | No `######` marker | Do not commit |

  - **IMPORTANT: When committing via aitodo tasks, use ONLY the exact commit message specified in `###### [commit message]`. Do NOT append any additional signatures, footers, or automated messages such as "Generated with Claude Code", "Co-Authored-By", emoji prefixes, or any other text. The commit message must be used exactly as written.**

##### re-perform mission
- If there are instructions to re-perform another mission, perform the mission that needs to be re-performed.
  - **Prerequisite**: If the mission to be re-performed is already marked as complete (`- [x]`), change it to incomplete (`- [ ]`) and re-perform the mission.

##### Mission Fail
- If you are **unable to complete a mission** while performing a todo task or mission, explain the problem and reason for the mission failure, **do not proceed with any further work, and terminate**.
  - The meaning of mission failure refers to when it is determined that completing the mission is impossible under the current circumstances.
    (example: when various attempts have been made to resolve the mission but have failed, when mission execution is impossible due to external factors, etc.)
  - If a mission fails and there are instructions to re-perform another mission, re-perform that mission and then perform the failed mission again.
    - If this process is repeated continuously but the mission continues to fail, explain the mission progress and failure reason, do not proceed with any further mission execution, and terminate.
  - example
    - If mission 2 fails, do not perform subsequent missions (3, 4, 5 ...) and terminate.
    - For example, if the content of mission 2 is "Access the `mlbdata.com` site and collect Brian player's 2024 batting average information.",
      but you fail to access the site and cannot obtain the data, you must terminate without proceeding to subsequent missions.
      Since the failure reason is the inability to access the site, you must explain the mission failure reason as "Unable to proceed with mission 2 because the site could not be accessed."
      (Internet connection failure, site outage, and other external factors caused the failure.)
    - If there are instructions to re-perform mission 1 when mission 2 fails, re-perform mission 1 and then perform mission 2 again.
      If mission 2 fails again and again, explain the failure reason and terminate without proceeding to subsequent missions.

##### aitodo.md Format Example
- The todo list format is as follows:

```markdown
# ISSUES
content

# TODO LIST
### Task 1
###### git commit message
- [ ] 1. task mission 1
- [ ] 2. task mission 2
  - detail mission
  - detail mission
- [ ] 3. task mission 3
  - detail mission

### Task 2
- [ ] 1. task mission 1
- [ ] 2. task mission 2
```

### build.md (BUILD.md)

- `./build.md` (`BUILD.md` (Don't be case sensitive to filename.)) contains information about compilation and build methods for the project, code formatting (code style), rules to follow, static analysis tools, dynamic analysis tools, testing methods, etc. When code is modified, refer to this file to unify code style and use build, test, and analysis tools to verify the modified logic.
