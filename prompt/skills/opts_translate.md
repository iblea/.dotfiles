
##### Translation Category Options Table
| Option | Description |
|--------|-------------|
| `below` / `under` / `b` / `u` | Output original first, then translation |
| `file` / `f` | Translate file at specified path |
| `verify` / `verbose` / `v` / `vb` / `ver` | Re-translate back to original language |
| `save` / `sv` | Save to `/tmp/translate_byai.md` |
| `mod` | Add translation below selected content |

##### Translate Category commands can have optional strings (options) following the command.
Translate Category Commands Options
(example: `<translate_command> below`, `<translate command> under`, etc.)

- The characters `under` or `below` or the abbreviation `b` or `u` can be used. This is entered after a user-defined command string, output all the original text first, and then output the translated content.

- The characters `file` or the abbreviation `f` can be used. This is entered after a user-defined command string, translate the contents of the file at the path that follows this text.

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

- The characters `save` or the abbreviation `sv` can be used. This is entered after a user-defined command string, Save the translated content and original text as `/tmp/translate_byai.md` file.
  - If there is an existing `/tmp/translate_byai.md` file, delete all the existing contents of the file and write it.

- The characters `mod` can be used. Add translated content from the lower line of the selected content of the file.
  - example
    - If the selected whole content is 5 to 20 lines, newline character(`\n`) enters additional and add the translated content from line 22.
    - `@test.md#L53-210 ;kor mod` or (`@test.md:53-210 ;kor mod`) -> Translate the content from line 53 to line 210 into Korean. After that, newline character(`\n`) enters additional and add the translated content from line 212.
    - `@test.md#L8-26 ;eng mod` or (`@test.md:8-26 ;eng mod`) -> Translate the content from line 8 to line 26 into English. After that, newline character(`\n`) enters additional and add the translated content from line 28.
  - If you have not selected a specific line or block in the file, add translated content in sections or paragraphs.
    - example: `@test.md ;eng mod` -> Translate everything in the file into paragraphs, or sections, and add translated content.
  - If you haven't translated the contents of the file, don't do anything about it.

