return {
  "preservim/nerdtree",
  event = "VimEnter",
  init = function()
    -- NERDTree 매핑 등록 전에 실행되어야 효과가 있음 -> init 사용
    vim.g.NERDTreeShowHidden = 1
    vim.g.NERDTreeMapToggleFiles = "<F2>"
    vim.g.NERDTreeMapToggleHidden = "<F3>"
  end,
  config = function()
    -- 안전망: 변수 변경이 안 먹혀도 buffer-local 로 f/F 를 강제 덮어쓰기
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "nerdtree",
      callback = function()
        vim.keymap.set('n', 'f', '<C-w><C-w>', { buffer = true, nowait = true, silent = true })
        vim.keymap.set('n', 'F', '<C-w>W',     { buffer = true, nowait = true, silent = true })
      end,
    })
  end,
}

