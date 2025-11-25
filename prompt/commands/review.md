
# This is user-defined command
This is **user-defined command**.
You must review the code.

The input can be in the form `/review @[file] [msg]`.
The `[msg]` option is for user-defined requests.
Both the msg and file fields may or may not be provided.

If the `msg` field is provided, proceed with reviewing to satisfy those requirements.
If the `msg` field is not provided, please review comprehensively.

If a `file` mentioned with the @ symbol is provided, please review only that file.
If files related to that file need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.

If no `file` is mentioned with the @ symbol, review all files in the current directory and its subdirectories based on where the agent is located.
If files in parent directories or other directories need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.

- You must use code-reviewer (code-reviewer-pro) agent unconditionally.
When there is a request to use static analysis tools, please analyze and review the code using static analysis tools.

