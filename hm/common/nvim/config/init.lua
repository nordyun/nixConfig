vim.g.mapleader = " "
vim.g.maplocalleader = " "
require('keymaps')
require('plugins.lualine')
require('options')
require('misc')
require('plugins.dap')
require('plugins.cmp')
require('plugins.gitsigns')
require('plugins.tele')
require('plugins.treesitter')
require('plugins.lsp')
require('plugins.trouble')
-- require('plugins.obsidian')
-- require('plugins.harpoon')
require('plugins.mini')
-- require('plugins.copilot')
require('plugins.rainbow-delimiters')
-- Create an autocommand group for Markdown settings
vim.api.nvim_create_augroup('MarkdownSettings', { clear = true })

-- Enable syntax highlighting for Markdown files
vim.api.nvim_create_autocmd('FileType', {
  group = 'MarkdownSettings',
  pattern = 'markdown',
  callback = function()
    vim.opt_local.conceallevel = 1
  end,
})

