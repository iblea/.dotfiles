
When building and testing the aiwaf project, you need to connect to a remote server via ssh.
You can connect to the remote server `test` using the `ssh test` command.
You can check the server connection information by referring to the `Host test` entry in the `~/.ssh/config` file.

**The source** location on the remote server is located at `/path/to/project1` and **the subproject** directory is located at `/path/to/project2`.
Each directory is synchronized with the project located on the current cursor local via sftp.


