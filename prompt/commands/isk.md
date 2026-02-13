
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Arguments
$ARGUMENTS

Command Format : `/isk [skill name] [content]`

- A skill name argument can be provided.
  - Use the skill that matches the skill name.
  - If there is no skill matching the skill name, return the message "no skill" and end the conversation.
  - If no skill name argument is provided, display the list of available skills, return the message "input skill name argument.", and end the conversation.


# Command behavior
You must unconditionally call/use the skill corresponding to `[skill name]`.
  - Even if, after examining the context of the conversation, you determine that it seems unnecessary to use the skill, you must use the skill unconditionally. You must not skip using the skill.
    - example: `/isk eng "Hello World!"` : The `eng` skill instructs to translate the content into English. Although the subsequent content is already an English sentence and it may seem unnecessary to use the `eng` skill, since the `/isk` user defined command has been invoked, you must unconditionally call the `eng` skill.
