
# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.

# Command Name
**initu** (init file update)

# Command Description
Update project initialization files (AGENTS.md, CLAUDE.md, GEMINI.md) based on the current conversation history.
This command analyzes the conversation to identify any project-related changes that should be documented.

# Command Behavior

## Pre-Step: Parse arguments and validate options
- Parse all arguments and options from input
- **Option conflict check**: If both `--force` (`-f`) and `--dry-run` (`-d`) are specified:
  - Report: "Error: --force and --dry-run cannot be used together."
  - **END**

## Step 1: Analyze file structure (symlink/hardlink detection)
- **IMPORTANT: `~/.claude/CLAUDE.md` (global file) is EXCLUDED from modification targets. Never modify this file.**
- Search for target files in:
  1. Current working directory
  2. Project root directory
- For each target file found, check:
  1. Is it a symlink? → Use `readlink -f` to get actual target
  2. Is it a hardlink? → Compare inodes using `stat`
- Group files that point to the same actual file
- Create a deduplicated list of unique actual files to modify

### If specific path is provided (e.g., `./docs/CLAUDE.md`):
- Check if the specified file exists
- If NOT exists:
  - Report: "Error: Specified file '[path]' does not exist."
  - **END**

### If no file arguments (default behavior):
- Search for: CLAUDE.md, AGENTS.md, GEMINI.md
- If **NO files exist at all**:
  - Report: "No init files found. (CLAUDE.md, AGENTS.md, GEMINI.md do not exist)"
  - **END**
- If **some files exist**: Proceed with only the existing files
  - Report which files were found (e.g., "Found: CLAUDE.md, AGENTS.md")

### Symlink/Hardlink handling:
- If symlink detected: Update only the TARGET file, skip the symlink
- If hardlink detected (same inode): Update only ONE of the files
- Report: "CLAUDE.md is a symlink to AGENTS.md. Updating AGENTS.md only."

## Step 2: Analyze conversation and identify updates
- Review the current conversation history (including compact summary if compacted)
- Identify any of the following that should be documented:
  - New project conventions or coding standards discovered
  - Important architectural decisions made
  - New dependencies or tools introduced
  - Workflow changes or new commands learned
  - Bug fixes or workarounds that should be remembered
  - Configuration changes
  - Any other project-specific knowledge worth preserving

## Step 3: Determine if updates are needed
- If **NO updates needed**:
  - Report: "No updates needed for init files."
  - **END**

- If **updates ARE needed**:
  - Proceed to Step 4

## Step 4: Report and confirm with user
- Present a clear summary of proposed changes:
  ```
  ## Proposed Updates

  ### CLAUDE.md
  - [List of changes]

  ### AGENTS.md
  - [List of changes]

  ### GEMINI.md
  - [List of changes]
  ```
- Ask the user: "Apply these updates? (yes/no)"

## Step 5: Apply based on user response
- **If user responds positively** (yes, ok, y, ㅇㅇ, 응, 네, etc.):
  1. Create backup copies to `/tmp/` (overwrite if backup already exists):
     - `AGENTS.md` → `/tmp/AGENTS.md.bak`
     - `CLAUDE.md` → `/tmp/CLAUDE.md.bak`
     - `GEMINI.md` → `/tmp/GEMINI.md.bak`
  2. Apply all proposed changes to the respective files
     - **If apply fails**: Restore from backup, report "Error: Failed to apply changes. Reverted to original." and **END**
  3. Delete backup files from `/tmp/`
  4. Report: "Updates applied successfully."

- **If user responds negatively** (no, n, ㄴㄴ, 아니, cancel, etc.):
  - Report: "Updates cancelled."
  - **END** (no backup needed, no rollback needed)

## --force Option Flow
When `--force` or `-f` option is used:
1. Create backup copies to `/tmp/` first (overwrite if exists)
2. Analyze conversation
3. **If NO updates needed**:
   - Delete backup files
   - Report: "No updates needed for init files."
   - **END**
4. Apply changes directly without confirmation
   - **If apply fails**: Restore from backup, report error and **END**
5. Delete backup files
6. Report: "Updates applied successfully (force mode)."

# Options
- `--force` or `-f`: Skip confirmation and apply updates directly (use with caution)
- `--dry-run` or `-d`: Only show proposed changes without applying or backing up
- **Note**: `--force` and `--dry-run` are mutually exclusive. Using both will result in an error.

# File Arguments (without -F option)
You can specify target files directly as arguments without any option flag:

## Supported formats:
| Input | Interpretation |
|-------|----------------|
| `CLAUDE.md` | Target CLAUDE.md file |
| `claude` | Target CLAUDE.md file (auto-append .md) |
| `AGENTS.md` | Target AGENTS.md file |
| `agents` | Target AGENTS.md file (auto-append .md) |
| `GEMINI.md` | Target GEMINI.md file |
| `gemini` | Target GEMINI.md file (auto-append .md) |
| `./docs/CLAUDE.md` | Target specific path (must exist) |
| `claude agents` | Target multiple files |

## Examples:
- `/initu claude` → Update only CLAUDE.md
- `/initu agents gemini` → Update AGENTS.md and GEMINI.md
- `/initu ./docs/CLAUDE.md` → Update specific file at path
- `/initu -d claude` → Dry-run for CLAUDE.md only
- `/initu` → Update ALL existing init files (CLAUDE.md, AGENTS.md, GEMINI.md)

# Symlink/Hardlink Detection Commands
```bash
# Check symlink
readlink -f <file>

# Check inode (for hardlink detection)
ls -i <file>

# Compare two files' inodes
stat -f "%i" <file1>  # macOS
stat -c "%i" <file1>  # Linux
```

# Default Behavior (no file arguments)
When NO file arguments are provided (`/initu` alone):
1. Search for ALL supported init files in project directory:
   - CLAUDE.md
   - AGENTS.md
   - GEMINI.md
2. Proceed with only the files that exist (skip non-existent ones)
3. Check for symlinks/hardlinks between them
4. Deduplicate to get unique actual files
5. Analyze and update each unique file

# Error Handling
- **Option conflict**: Report "Error: --force and --dry-run cannot be used together." and **END**.
- **Specified file not found**: Report "Error: Specified file '[path]' does not exist." and **END**.
- **No files found**: Report "No init files found." and **END**.
- **File read error**: Report "Error: Cannot read [filename]. Check file permissions." and skip the file.
- **File write error**: Restore from backup (if exists), report "Error: Cannot write to [filename]. Changes reverted." and **END**.
- **Backup creation error**: Report "Error: Cannot create backup. Aborting." and **END** without modifying any files.

# Excluded Files (NEVER modify)
- `~/.claude/CLAUDE.md` - Global configuration file, always excluded
- Any file outside project directory unless explicitly specified by path

# Notes
- This command relies on the current conversation context
- If the conversation has been compacted (`/compact`), analyze BOTH the compact summary AND post-compact conversation
- Files are searched in order: current directory → project root (excluding ~/.claude/)
- Always preserve existing content and only ADD or MODIFY relevant sections
- Case-insensitive file matching: `claude`, `Claude`, `CLAUDE` all match CLAUDE.md
- Backup files may be overwritten if another project runs `/initu` simultaneously

