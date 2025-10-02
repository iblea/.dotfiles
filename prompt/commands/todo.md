
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(c

# TODO FILE FORMAT & RULES
- `./TODO.md` (`TODO.md` (Don't be case sensitive to filename.)) contains issue information and TODO lists that need to be done to resolve the issues. If there are issues written in the `TODO.md` (`todo.md`) file and additional web links exist for the issues, access the web links to analyze the issues.
  - The TODO LIST shows the tasks you need to work on in checkbox (`[ ]`) format. Work on them one by one, and when you complete a task, mark it as completed (`[x]`).
    - Set only the completion mark (`[x]`). **Do not write** any additional descriptions (documenting the results) or details about the completion of the task on `TODO.md`.
  - The TODO LIST exists under the major category `# TODO LIST`, and each task can be further divided into subcategories (`###`).
  - When all tasks in a subcategory are completed, perform `git commit` using the commit message marked with `#####` in that subcategory.
    - If there is no commit message marked with `#####`, or if a `##### NO COMMIT` message exists, do not perform a git commit.
    - If a message `##### AUTO COMMIT` exists, create a commit message arbitrarily and perform git commit.
  - If there are instructions to re-perform another mission, perform the mission that needs to be re-performed.
    - **Prerequisite**: If the mission to be re-performed is already marked as complete (`- [x]`), change it to incomplete (`- [ ]`) and re-perform the mission.
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
  - The todo list format is as follows:
    ```markdown
    # ISSUES
    content

    # TODO LIST
    ### Task 1
    ##### git commit message
    - [ ] 1. task mission 1
    - [ ] 2. task mission 2
      - detail mission
      - detail mission
    - [ ] 3. task mission 3

    ### Task 2
    (If there is no commit message marked with `#####`, don't perform `git commit`.)
    - [ ] 1. task mission 1
      - detail mission
    - [ ] 2. task mission 2

    ### Task 3
    (Don't commit if there is a message `##### NO COMMIT`.)
    ##### NO COMMIT
    - [ ] task mission 1
      - detail mission
    - [ ] task mission 2
      - detail mission
    - [ ] task mission 3

    ### Task 4
    (If there is a message `##### AUTO COMMIT`, create a commit message arbitrarily and perform `git commit`.)
    ##### AUTO COMMIT
    - [ ] ...mission...
      - detail mission
      - detail mission
    - [ ] ...mission...
      - detail mission
    - [ ] ...mission...
      - detail mission
    ```

# Command behavior
- This Command Format is `/todo [task] [mission]`
- Find and read the `TODO.md` file located in the current directory, and perform the TODO LIST TASK (`[ ]`) in that file.
  - Don't be case sensitive to filename. (`TODO.md`, `todo.md`, `Todo.md` ... etc.)
- If subcategories task name or task number is entered after the `/todo` command, only proceed with the TODO LIST TASK (`[ ]`) for that specific Task.
- mission is optional. ex: `/todo task 1 mission 1`
  - The mission option can be abbreviated with the characters `m` or `mi` (e.g. `/todo task 1 m 2`).
  - The mission option refers to a single `- [ ]` item within a Task in the TODO.md file.
  - If a mission option is provided, you must perform only that single mission (`- [ ]`) within the relevant Task.
  - When a mission is completed, mark it as complete with `- [x]`.
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
      - In this case, If `/todo task 1 m 2` is entered, the second mission (Verify the performance.) will be performed.
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

- If there is no `TODO.md` file, return the message "NOT EXIST TODO.md".
