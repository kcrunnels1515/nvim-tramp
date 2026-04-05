-- plugin/nvim-tramp.lua
-- Plugin loader and command definitions

-- Define plugin commands
if vim.fn.has("nvim-0.8") == 0 then
  vim.notify("This plugin requires Neovim >= 0.8", vim.log.levels.ERROR)
  return
end

-- Create user commands for the plugin
vim.api.nvim_create_user_command("NvimTrampOpen", function()
  require("nvim-tramp").open_host()
end, {
  desc = "Open a remote host",
})

vim.api.nvim_create_user_command("NvimTrampClose", function()
  require("nvim-tramp").close_host_prompt()
end, {
  desc = "Close connection with a remote host",
})

vim.api.nvim_create_user_command("NvimTrampCloseAll", function()
  require("nvim-tramp").close_all()
end, {
  desc = "Close all remote connections",
})


vim.api.nvim_create_user_command("NvimTrampToggle", function()
  require("nvim-tramp").toggle()
end, {
  desc = "Toggle plugin on/off",
})

-- Auto-setup for lazy loading
-- Uncomment if needed
-- if vim.fn.has("vim_starting") == 1 then
--   vim.cmd([[autocmd VimEnter * ++once lua require("nvim-tramp").setup()]])
-- end
