-- [[ Configure Treesitter ]]
-- nvim-treesitter `main` branch (nixpkgs >= 2026-04): the old
-- `require('nvim-treesitter.configs').setup{}` module was removed.
-- Grammars are supplied by nix (`nvim-treesitter.withAllGrammars`), so there is
-- nothing to install here -- we just turn on highlighting + indentation per buffer.

local ok, ts = pcall(require, 'nvim-treesitter')
if ok and ts.setup then
  ts.setup {}
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter_setup', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end

    -- highlighting
    pcall(vim.treesitter.start, buf, lang)

    -- indentation (experimental in the new branch, but matches the old `indent`)
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- NOTE: `incremental_selection` and `textobjects` are no longer part of
-- nvim-treesitter itself on the `main` branch. If you want them back, add the
-- `nvim-treesitter-textobjects` plugin (main branch) and configure it here.
