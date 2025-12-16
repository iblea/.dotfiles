return {
    {
        'milanglacier/minuet-ai.nvim',
        event = "VimEnter",
        dependencies = { 'nvim-lua/plenary.nvim', 'hrsh7th/nvim-cmp', 'Saghen/blink.cmp' }, -- if you use the mini.nvim suite
        config = function()
            require('minuet').setup {
                -- Your configuration options here

                -- cmp = {
                --     enable_auto_complete = true,
                -- },
                -- blink = {
                --     enable_auto_complete = true,
                -- },
                virtualtext = {
                    auto_trigger_ft = { '*' },
                    -- auto_trigger_ignore_ft = {},
                    keymap = {
                        -- accept whole completion
                        -- accept = '<A-A>',
                        accept = '<C-u>',
                        -- accept one line
                        accept_line = '<A-a>',
                        -- accept n lines (prompts for number)
                        -- e.g. "A-z 2 CR" will accept 2 lines
                        accept_n_lines = '<A-z>',
                        -- Cycle to prev completion item, or manually invoke completion
                        prev = '<C-z>',
                        -- Cycle to next completion item, or manually invoke completion
                        next = '<C-x>',
                        -- dismiss = '<A-e>',
                        dismiss = '<C-]>',
                    },
                    show_on_completion_menu = false,
					show 
                },
                provider = 'codestral',
                -- provider = 'claude',
                context_window = 16000,
                context_ratio = 0.75,
                throttle = 1000,
                debounce = 400,
                notify = 'warn',
                request_timeout = 3,
                add_single_line_entry = true,
                n_completions = 3,
                after_cursor_filter_length = 15,
                before_cursor_filter_length = 2,
                proxy = nil,
                provider_options = {
                    claude = {
                        max_tokens = 256,
                        model = 'claude-haiku-4.5',
                        stream = true,
                        api_key = 'ANTHROPIC_API_KEY',
                        -- end_point = 'https://api.anthropic.com/v1/messages',
                        -- system = "see [Prompt] section for the default value",
                        -- few_shots = "see [Prompt] section for the default value",
                        -- chat_input = "See [Prompt Section for default value]",
                        -- optional = { }
                    },
                    codestral = {
                        model = 'codestral-latest',
                        api_key = 'CODESTRAL_API_KEY',
                        stream = true,
                        -- end_point = 'https://codestral.mistral.ai/v1/fim/completions',
                        -- template = {
                        --     prompt = "See [Prompt Section for default value]",
                        --     suffix = "See [Prompt Section for default value]",
                        -- },
                        optional = {
                            max_tokens = 256,
                            stop = { '\n\n' },
                            -- max_tokens = nil,
                            -- stop = nil, -- the identifier to stop the completion generation
                        },
                    }
                }
            }
            vim.cmd('Minuet virtualtext enable')
        end,
    },
    -- {
    --     "hrsh7th/nvim-cmp",
    --     optional = true,
    --     opts = function(_, opts)
    --         -- if you wish to use autocomplete
    --         opts.sources = opts.sources or {}
    --         table.insert(opts.sources, 1, {
    --             name = 'minuet',
    --             group_index = 1,
    --             priority = 100,
    --         })

    --         opts.performance = {
    --             -- It is recommended to increase the timeout duration due to
    --             -- the typically slower response speed of LLMs compared to
    --             -- other completion sources. This is not needed when you only
    --             -- need manual completion.
    --             fetching_timeout = 2000,
    --         }

    --         opts.mapping = vim.tbl_deep_extend('force', opts.mapping or {}, {
    --             -- if you wish to use manual complete
    --             ['<A-y>'] = require('minuet').make_cmp_map(),
    --         })
    --     end,
    -- }
}

