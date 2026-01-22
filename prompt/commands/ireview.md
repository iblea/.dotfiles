
# This is user-defined command
This is **user-defined command**.
You must review the code.

# Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.

The input can be in the form `/ireview @[file] [msg]`.
The `[msg]` option is for user-defined requests.
Both the msg and file fields may or may not be provided.

If the `msg` field is provided, proceed with reviewing to satisfy those requirements.
If the `msg` field is not provided, please review comprehensively.

If a `file` mentioned with the @ symbol is provided, please review only that file.
If files related to that file need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.

If the keyword `cached`, `staged`, `staging`, or `stage` is provided instead of `@[file]` (e.g., `/ireview cached`, `/ireview staged`), execute `git diff --cached` (or `git diff --staged`) to review the staged changes.
In this case, review the code changes that have been staged for commit.

If no `file` is mentioned with the @ symbol and no `cached`/`staged` keyword is provided, review all files in the current directory and its subdirectories based on where the agent is located.
If files in parent directories or other directories need to be reviewed, proceed with the reviewing and additionally report the files that were reviewed.


# Command behavior
- You must use CodeReviewer, ArchitectReviewer agent unconditionally.
When there is a request to use static analysis tools, please analyze and review the code using static analysis tools.

