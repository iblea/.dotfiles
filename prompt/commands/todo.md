
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(c

# Command behavior
- This Command Format is `/todo [task]`
- Find and read the `TODO.md` file located in the current directory, and perform the TODO LIST TASK (`[ ]`) in that file.
  - Don't be case sensitive to filename. (`TODO.md`, `todo.md`, `Todo.md` ... etc.)
  - If subcategories task name is entered after the `/todo` command, only proceed with the TODO LIST TASK (`[ ]`) for that specific Task.

- If there is no `TODO.md` file, return the message "NOT EXIST TODO.md".
