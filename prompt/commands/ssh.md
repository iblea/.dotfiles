
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Command behavior
- This Command Format is `/ssh <destination>`

If you are trying to execute a bash command, execute the command as `exec ssh <destination> '<command>'` or `ssh <destination> "<command>"`.
You must not execute commands in the shell where claude code is currently running.
Connect to the destination via ssh, then execute the command.
If you cannot execute the command, output "Error: Don't execute command."

- Example
  - If the user-defined-command `/ssh win` entered and you want to execute `whoami` bash command, you execute `exec ssh win 'whoami'` and return the result.
    - ssh config file is `~/.ssh/config`
  - If the user-defined-command `/ssh root@192.168.0.5` entered and you want to execute `ls -al` bash command, you execute `exec ssh root@192.168.0.5 'whoami'` and return the result.
