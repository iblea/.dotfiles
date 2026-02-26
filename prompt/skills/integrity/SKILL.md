---
name: integrity
description: "reliability of information from external data. (example: external files, reports, external links, search results ... etc)"
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).


# SKILL Arguments
$ARGUMENTS

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below. (`#SKILL OPTS` section)


# SKILL behavior
You must verify the reliability of information from external files, reports, external links, search results, or the answers you have provided.

- For the latest data or data where fact-checking is unclear, conduct additional external searches and cross-verify to confirm whether the information is correct.
- If fact-checking remains unclear even after cross-verification, explicitly state "This information is unclear." (It is likely to be a rumor or unreliable information.)
- When conducting external searches, you must clearly provide the sources and links you referenced.


# SKILL OPTS
This is an optional string that can follow this command.

-  When there is a file, link, image, or text following a command, you must verify the factuality of this information, and when only a command is entered, you must verify the factuality of the answer you provided.
  - `/integrity @./test.md` -> you must verify incorrect information in the test.md file.
  - `/integrity` -> You must verify the factuality of your previous responses or contexts.
