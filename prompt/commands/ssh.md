
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.


# Command behavior
- This Command Format is `/ssh <destination>`

If you are trying to execute a bash command, execute the command as `exec ssh <destination> '<command>'` or `ssh <destination> "<command>"`.
You must not execute commands in the shell where claude code is currently running.
Connect to the destination via ssh, then execute the command.
If you cannot execute the command, output "Error: Don't execute command."
If only the Host is entered, connect to the host via SSH and execute the subsequent commands.

- Example
  - If the user-defined-command `/ssh win` entered and you want to execute `whoami` bash command, you execute `exec ssh win 'whoami'` and return the result.
    - ssh config file is `~/.ssh/config`
  - If the user-defined-command `/ssh root@192.168.0.5` entered and you want to execute `ls -al` bash command, you execute `exec ssh root@192.168.0.5 'whoami'` and return the result.
  - If the user-defined-command `/ssh test install gcc (config file is current directory, sshconfig.conf name.)` entered, You must proceed as below.
    - Assuming that the server is an Ubuntu server with apt installed, the command to install gcc is `apt-get install -y gcc`.
      Also, since the user indicated that the ssh config file is located at sshconfig.conf in the current directory, you need to add the -F option like `ssh -F "$(pwd)/sshconfig.conf"`.
      Therefore, you should execute the following command: `ssh -F "$(pwd)/sshconfig.conf" test "apt-get install -y gcc"`

