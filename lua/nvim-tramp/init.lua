-- nvim-tramp/init.lua
-- Main entry point for your plugin

-- Plugin configuration
local config = {
  -- Default configuration options
  enabled = true,
  debug = false,
  -- Add your plugin's configuration options here
}

local mounthost = require("nvim-tramp.mounthost")
local fzf_lua = require("fzf-lua")

-- Main plugin module
local M = {}

M.hosts = mounthost.hosts
M.open_host = mounthost.open_host
M.read_host = mounthost.read_host
M.close_host_prompt = mounthost.close_host_prompt
M.close_host = mounthost.close_host
M.close_all = mounthost.close_all

---Setup function - called by user to configure the plugin
---@param opts table: User configuration options
M.setup = function(opts)
  -- Merge user configuration with defaults
  config = vim.tbl_deep_extend("force", config, opts or {})

  -- Validate configuration
  if type(config.enabled) ~= "boolean" then
    vim.notify("nvim-tramp: 'enabled' option must be boolean", vim.log.levels.ERROR)
    return
  end

  -- Add additional validations as needed

  -- Early return if disabled
  if not config.enabled then
    vim.notify("nvim-tramp is disabled", vim.log.levels.INFO)
    return
  end

  -- Set up autocommands if necessary
  vim.api.nvim_create_augroup("NvimTramp", { clear = true })
  vim.api.nvim_create_autocmd("VimLeave", {
    group = "NvimTramp",
    pattern = { "*" }, -- Adjust file types as needed
    callback = M.close_all,
  })

  -- Load keymappings if necessary
  M.setup_keymaps()

  -- Log debug information
  if config.debug then
    vim.notify("nvim-tramp: plugin initialized with config: " .. vim.inspect(config), vim.log.levels.DEBUG)
  end
end

---Set up keymaps for the plugin
M.setup_keymaps = function()
  -- Example keymap setup
  local opts = { noremap = true, silent = true } -- Used for keymap functions

  -- Example of setting a keymap
  -- vim.keymap.set("n", "<leader>p", function() require("nvim-tramp").some_function() end, opts)

  -- Register with which-key if available
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.register({
      ["<leader>f"] = {
        name = "+nvim-tramp",
        to = { function() M.open_host() end, "Open new remote host" },
        tc = { function() M.close_host_prompt() end, "Close a remote host" },
        -- t = { function() M.toggle() end, "Toggle Plugin" },
      }
    })
  end
end

-- ---Example function that your plugin provides
-- M.some_function = function()
--   -- Your plugin logic here
--   vim.notify("nvim-tramp: some_function called", vim.log.levels.INFO)
-- end

---Toggle plugin enabled state
M.toggle = function()
  config.enabled = not config.enabled
  vim.notify("nvim-tramp: " .. (config.enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end

---Get current configuration
---@return table: Current configuration
M.get_config = function()
  return config
end

return M
