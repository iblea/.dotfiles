
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
- You must use researcher agent unconditionally.
- This Command Format is `/search [th/dis]`
- If necessary, use multiple tools such as web_search.

When receiving the command **;search**, You should research, organize, and explain the data.
You should gather up-to-date information through web searches, etc., and create a reliable report based on it.
When searching the web, you should clarify the source and ensure the accuracy and reliability of the information through cross-validation.
You should clearly explain complex concepts and provide a balanced perspective by considering various perspectives.
You should also be proficient in data analysis and statistical methodology, so that you can visualize and deliver data effectively.
You should provide creative insights and integrated perspectives based on a deep understanding of the subject.

### This is an optional string that can follow this command. (ex: `/search th`, `/search dis`, etc.)

- The `th` or `dis` option may be entered after the `/search` command. In this case, you must unconditionally search for or refer to related academic papers.
  - Use Web Search, arXiv, Google Scholar, Semantic Scholar API, etc. to search for papers.
  - Analyze the user query to extract core concepts and expand search terms. (synonyms, related terms, academic terminology)
  - Summarize the searched papers and explain them in an easy-to-understand manner.
  - Track the references (backward) and citations (forward) of key papers.
  - Critical Rules
    - Never fabricate papers. If uncertain, explicitly state "verification required".
    - Include verifiable links (DOI, arXiv ID) for all papers.
    - If direct access is not possible, verify actual existence through web search.
    - If metadata (author, year, title) is uncertain, explicitly indicate this.
        - Display the year of publication, citation count, and conference/journal ranking to filter paper quality.
  - Standardize the output format for papers.
    - Output each paper in the following format:
      ```
      ## [논문 제목]
      (내용)
      - **저자 (Authors)**:
      - **출처 (Source)**: (학회/저널, 연도) (Conference/Journal, Year)
      - **링크 (Link)**: (DOI 또는 arXiv URL)
      - **핵심 기여 (Key Contribution)**: (2-3문장)
      - **방법론 (Methodology)**:
      - **한계점 (Limitatiions)**:
      - **신뢰도 (Reliability)**: ✓ 확인됨 | ⚠ 검증 필요
      ```
