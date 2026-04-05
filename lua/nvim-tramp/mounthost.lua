local uv = vim.uv
local fzf_lua = require("fzf-lua")
local nvim_tree = require("nvim-tree")
local M = {}

M.hosts = {}
M.mount_tmpl = "/tmp/nvim-trampXXXXXX"

function M.open_host()
  local mounted_path = M.read_host()
  if mounted_path == nil then
    vim.notify("Failed to properly create and mount", vim.log.levels.ERROR)
  else
    vim.fn.chdir(mounted_path)
    require("nvim-tree").tree.open()
  end
end

function M.read_host()
  local host_info_input = vim.fn.input("Enter host information (default port 22): ")
  local mount_res = {}
  local host_info = {}

  for user, host in string.gmatch(host_info_input, "(%S+)@(%S+)") do
    host_info.user = user
    host_info.host = host
  end

  if host_info.user == nil or host_info.host == nil then
    vim.notify("Invalid host information", vim.log.levels.ERROR)
    return nil
  end

  host_info.remote_dir = "/"

  for path in string.gmatch(host_info_input, ":(%S+)") do
    host_info.remote_dir = path
  end

  host_info.port = "22"

  for port in string.gmatch(host_info_input, "#(%d+)") do
    host_info.port = port
  end

  host_info.mount_dir = uv.fs_mkdtemp(M.mount_tmpl)
  if host_info.mount_dir == nil then
    vim.notify("Failed to create mount directory", vim.log.levels.ERROR)
    return nil
  end

  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local handle, pid = uv.spawn("sshfs",
    { args = { "-p", host_info.port, host_info.user .. "@" .. host_info.host .. host_info.remote_dir, host_info.mount_dir }, stdio = {stdin, stdout, stderr} },
    function(code, signal)
      -- handle:close()
      mount_res.code = code
      mount_res.signal = signal
    end)

  local host_passwd = vim.fn.inputsecret("Enter password: ")

  uv.write(stdin, host_passwd)
  handle:close()
  -- uv.unref(handle)
  M.hosts[host_info_input] = host_info
  return host_info.mount_dir
end

function M.close_host(hostinfo)
  local umount_res = {}

  local handle, pid = uv.spawn("umount",
    { args = { host_info.mount_dir } },
    function(code, signal)
      umount_res.code = code
      umount_res.signal = signal
    end)

    uv.unref(handle)

    uv.fs_rmdir(hostinfo.mount_dir)
end

function M.close_host_prompt()
  local hosts = {}
  for host, _ in M.hosts do
    table.insert(hosts, host)
  end

  fzf_lua.fzf_exec(hosts, {
    prompt = "Close host> ",
    actions = {
      ["default"] = function(selected)
        M.close_host(M.hosts[selected])
      end,
    }
  })

end

function M.close_all()
  for _, info in M.hosts do
    M.close_host(info)
  end
end

return M
