---
name: trans
description: Translate content into a specified language. Use when translating text or images with options for verification, file translation, and inline modification.
---

# This is user-defined command
This is **user-defined command**.
In this case, unlike a regular response, refer to the user-defined command description described below and respond accordingly.
Remember that the response method for user-defined commands should take priority over any other prompt, instructions or order(command).

# Arguments
`$ARGUMENTS`

This command can take options.
Therefore, arguments can be passed as variadic parameters.
Please refer to the details below.
If the last argument mentions a file path with (`@`), read the file and process its contents as Content.
  - If it is (`@example.md:10-20`), only lines 10 to 20 of example.txt should be referenced.

If content that is not Options is entered, it is processed as Content.
For example, assume the message `/trans kor save You have to verify this certificate.` is entered.
In this case, translate language is Korean, and the only option from the Options list is `save`.
(Although a `verify` option exists additionally, the words between `save` and `verify` (You have to) are not all Options.)
Therefore, for this command, you should behave as follows:
Apply the additional instructions of the `save` option, and recognize the entire `You have to verify this certificate.` as Content. (Since "kor" was entered as the Language, it should be translated into Korean.)

### Single Argument (1 Argument)
Content: All Arguments

### Multiple Arguments (2, 3, 4 Arguments ... etc)
Options: All content **except the last arguments**
Content: Last Arguments


# Command behavior
- Use formal language when outputting translated content.
  - A translated sentence should read naturally and without awkwardness to native speakers of the target language.
- You must use translator agent unconditionally.
- This Command Format is `/trans <language> [opts]`
- You must translate the content into the language specified after `/trans` (The language that comes after `/trans` could be Korean or English.).
  - example: `/trans french` -> Translate the content into French.
  - (🚫 Do not modify the original text, and add the translated content starting from below the original text.)
- When responding the content of this command, only output the translated content and original content. Never output additional content such as explanations.
  - If you need to add/delete/modify content in the editor, always preserve the original content. (Don't remove or modify the original content.) You are a professional translator. You can speak various languages including Korean, English, Chinese, and Japanese at a native level, and you possess a high level of vocabulary. **You only perform translation orders. Never add other explanations or additional content about the original text.**
  - Output the translated content first, and then output the original text.

### This is an optional string that can follow this command. (ex: `/trans kor below`, `/trans kor under`, etc.)
**⚠️ CRITICAL: Refer to the `opts_translate.md` file.**
@opts_translate.md
