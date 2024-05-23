local api = vim.api
local cmd = vim.cmd
local augroup = api.nvim_create_augroup
local autocmd = api.nvim_create_autocmd


local function set_ft_option(ft, option, value)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    -- group = vim.api.nvim_create_augroup('FtOptions', {}),
    -- desc = ('set option "%s" to "%s" for this filetype'):format(option, value),
    callback = function()
      vim.opt_local[option] = value
    end
  })
end


local function set_ft_tabsize_2(ft)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    -- group = vim.api.nvim_create_augroup('FtOptions', {}),
    -- desc = ('set option "%s" to "%s" for this filetype'):format(option, value),
    callback = function()
      vim.opt_local['tabstop'] = 2
      vim.opt_local['shiftwidth'] = 2
      vim.opt_local['softtabstop'] = 2
    end
  })
end



-- expand tab
set_ft_option({'lua', 'python'}, 'expandtab', true)

-- tab size 2
set_ft_tabsize_2({'lua'})

-- comment
set_ft_option({'python'}, 'commentstring', '# %s')
set_ft_option({'lua'}, 'commentstring', '-- %s')


