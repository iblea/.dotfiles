---
name: findcode 
description: Analyze the code and provide a concise summary of the file paths, lines, and line ranges that correspond to the description. (use with ;findcode)
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order.

# SKILL Arguments
$ARGUMENTS

Please refer to the details below. (`#SKILL OPTS` section)


# SKILL behavior

- When receiving the command **;findcode**, Analyze the code and provide a concise summary of the file paths, lines, and line ranges that correspond to the description. 
  - Analyze the code related to the description, organize the associated logic, and explain the file paths/lines along with the behavior of each file/line.
  - Based on the current path, output the path and line/line range, and provide an explanation.
    - The line notation is fixed to the `#L<line>` / `#L<start>-<end>` format.
    - ex: `./path/to/.../file.py#L100` or `./path/to/.../file.py#L50-130`
      - (Based on the current path, output the path and line/line range, and explain the analyzed content.)
  - Analysis method: For symbol tracing (analyzing definition/reference/call relationships), use LSP tools (`goToDefinition`, `findReferences`, `incomingCalls`/`outgoingCalls`) first.
    - Use Grep/Search as a fallback only when LSP is unavailable or its results are insufficient.
  - Trace scope: Trace only the project's internal code.
    - For external library/open-source code, do not step inside; only note the function call site.
  - When summarizing the code flow, output it in a tree-like form (similar to the output of the `tree` command) as shown below.
    - For each call in the flow, include the called file path / line (line range) / function name / description.
      - Include the call site of the function whenever possible.

##### Summary Example
```
/path/to/a.py#L10-20 (a 함수)
  - call (#L15): /path/to/module_a.py#L23-39 (a1 함수 호출)
    - call (#L25, #L33): /path/to/module_b.py#L44 (thread_1 함수 호출)
      - (#L44): thread_1 기동 실행
    - call (#L36): /path/to/log.py#L102-109 (로그 큐 삽입)

- thread_1 (module_a.py#L26 - atr 변수 참조)
  - call (#L26): /path/to/atr/usage.py#L9-34 (atr_msg 함수 호출)
    - call (#L23): /path/to/telegram_msg.py#L62-120 (telegram_msg 함수 호출)
      - call (#L89): /path/to/tlg_queue.py#L35-62 (tlg_que 삽입)
    - call (#L29): /path/to/discord_msg.py#L12-45 (discord_msg 함수 호출)
```

##### Async / Queue Branch Handling
- For points where the call flow does not continue immediately in place — such as thread startup, callback registration, or queue insertion — do not cut the tree at the insertion/startup point; instead, **split the consuming/executing side into a separate top-level tree** and continue tracing it.
  - Example: If a function just pushes to a queue and returns, the processing flow of the consuming (pop) side of that queue must also be organized as a separate tree.
    ```
    - call function a
      - ...(omitted)...
        - msgque.push()

    - on msgque.pop() (every 200ms, check whether msgque is empty; if not, pop its contents)
      - description of how the popped contents are processed ...(omitted)...
    ```
  - The `thread_1` tree in the `Summary Example` above is an example where this rule is applied.

##### Output Structure
The response MUST consist of the following two parts. Do not stop after outputting only the tree summary.
1. **Call flow summary**: A tree-form call flow summary like the `Summary Example` above. (Async/queue branches are split into separate trees.)
2. **Detail**: A detailed description of each node (file#line, function) that appears in the tree.
   - Explain what each function/section does in 2-4 lines per node, along with its key branches/conditions.


# SKILL OPTS
This is an optional string that can follow this command.

### Option: Request (String)

Analyze the content corresponding to the given request.

