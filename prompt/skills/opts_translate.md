
##### Translation Category Options Table
| Option | Description |
|--------|-------------|
| `below` / `under` / `b` / `u` | Output original first, then translation |
| `file` / `f` | Translate file at specified path |
| `verify` / `verbose` / `v` / `vb` / `ver` | Re-translate back to original language |
| `save` / `sv` | Save to `/tmp/translate_byai.md` |
| `mod` | Add translation below selected content |
| `n` `natural` | Replace the content with more natural expressions. |

##### Translate Category commands can have optional strings (options) following the command.
Translate Category Commands Options
(example: `<translate_command> below`, `<translate command> under`, etc.)

### Option: under, below, u, b
- The characters `under` or `below` or the abbreviation `b` or `u` can be used. This is entered after a user-defined command string, output all the original text first, and then output the translated content.

### Option: file, f
- The characters `file` or the abbreviation `f` can be used. This is entered after a user-defined command string, translate the contents of the file at the path that follows this text.

### Option: verify, verbose, v, vb, ver
- The characters `verify` or `verbose` or the abbreviation `v` or `vb` or `ver` can be used. This is entered after a user-defined command string, re-translate the content you translated back into the language before translation.
  - example: `;eng ver 나는 지금 몹시 배고프다.` -> `I'm very hungry now.` -> `난 지금 매우 배고프다.`
    - Because the `;eng` command was entered, the sentence "나는 지금 몹시 배고프다." must be translated into English.
    - Because the `ver` option was entered after the `;eng` command, the translated sentence "I'm very hungry now." must be re-translated back into the language before translation, which is Korean.
    - **If this option is input, output the re-translated translation instead of outputting the original text.**
    - Output format is here.
      ```
      (translated)

      (origin - re-translated)
      ```
      so your answer is this.
      ```
      user question: ;eng ver 나는 지금 몹시 배고프다.
      your answer:
      I'm very hungry now.

      난 지금 매우 배고프다.
      (You must translate "the content you translated"(I'm very hungry now.) back into "Korean", the original language the user inputted, and output it.)
      ```

### Option: save, sv
- The characters `save` or the abbreviation `sv` can be used. This is entered after a user-defined command string, Save the translated content and original text as `/tmp/translate_byai.md` file.
  - If there is an existing `/tmp/translate_byai.md` file, delete all the existing contents of the file and write it.

### Option: mod
- The characters `mod` can be used. Add translated content from the lower line of the selected content of the file.
  - example
    - If the selected whole content is 5 to 20 lines, newline character(`\n`) enters additional and add the translated content from line 22.
    - `@test.md#L53-210 ;kor mod` or (`@test.md:53-210 ;kor mod`) -> Translate the content from line 53 to line 210 into Korean. After that, newline character(`\n`) enters additional and add the translated content from line 212.
    - `@test.md#L8-26 ;eng mod` or (`@test.md:8-26 ;eng mod`) -> Translate the content from line 8 to line 26 into English. After that, newline character(`\n`) enters additional and add the translated content from line 28.
  - If you have not selected a specific line or block in the file, add translated content in sections or paragraphs.
    - example: `@test.md ;eng mod` -> Translate everything in the file into paragraphs, or sections, and add translated content.
  - If you haven't translated the contents of the file, don't do anything about it.

### Option: natural, n
- The characters `natural` or the abbreviation `n` can be used. This is entered after a user-defined command string, Replace the sentence with an expression that sounds more natural to native speakers.
  - The n option may serve as a natural translation command, but when the input language is the same as the target language, it should rephrase the input into more natural, idiomatic expressions.
  - **Only when an explanation of why the phrasing is already natural is required may the higher-level prompt instructing to output only translated content be disregarded.**
  - If the sentence is already natural, explain why it doesn't need to be changed.
  - Additional context for the given situation can follow the option. (format: `n <situation>`)

    Example: The word "land" is typically used to mean things like "ground," "territory," or "to land (an aircraft)." However, on GitHub, "land" can also refer to "a PR being merged into the main branch."
    So if a user enters a command like the one below, it's perfectly fine to use "land" in the response.

    ```
    /eng n Github PR comment
    I think this PR looks good to merge!
    ```
    -> This PR looks good to land! or LGTM!

    In other words, if a situation is provided after n, actively use words, idioms, and expressions that are natural and appropriate for that context.

