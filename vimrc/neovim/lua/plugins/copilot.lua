return {
    {
        'github/copilot.vim',
        -- copilot#Init()이 VimEnter autocmd에서 실행되므로 InsertEnter 지연 로드 불가
        event = "VimEnter",
        init = function()
            vim.g.copilot_filetypes = { ['.'] = true }
            vim.g.copilot_no_tab_map = true
        end,
        config = function()
            -- 제안 없으면 원래 <C-u> 동작
            -- vimrc의 insert 키맵보다 늦게 적용하기 위해 init 대신 config에서 설정
            vim.keymap.set('i', '<C-u>', 'copilot#Accept("\\<C-u>")', {
                expr = true,
                replace_keycodes = false,
            })
            vim.keymap.set('i', '<A-a>', '<Plug>(copilot-accept-line)')
            vim.keymap.set('i', '<A-z>', '<Plug>(copilot-accept-word)')
            -- 제안이 있으면 다음 후보, 없으면 수동 요청
            vim.keymap.set('i', '<C-x>', function()
                if vim.fn['copilot#GetDisplayedSuggestion']().text ~= '' then
                    vim.fn['copilot#Next']()
                else
                    vim.fn['copilot#Suggest']()
                end
            end)
            vim.keymap.set('i', '<C-z>', '<Plug>(copilot-previous)')
        end,
    },
}
