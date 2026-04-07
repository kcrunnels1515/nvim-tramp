local uv = vim.uv
local fzf_lua = require("fzf-lua")

local M = {}

M.hosts = {}
M.hostnames = {}
M.mount_tmpl = "/tmp/nvim-trampXXXXXX"

function M.read_host()
  local host_info_input = vim.fn.input("Enter host information: ")
  local mount_res = {}
  local host_info = {}

  host_info.nth = 1

  for user, host in string.gmatch(host_info_input, "(%S+)@(%S+):") do
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

  local port = vim.fn.input("Enter port (default port 22): ")
  if #port > 0 then
    host_info.port = port
  end

  host_info.mount_dir = uv.fs_mkdtemp(M.mount_tmpl)
  if host_info.mount_dir == nil then
    vim.notify("Failed to create mount directory", vim.log.levels.ERROR)
    return nil
  end

  -- local channel_id = vim.fn.jobstart( { "sshfs", "-p", host_info.port, host_info.user .. "@" .. host_info.host .. host_info.remote_dir, host_info.mount_dir })

  local stdin = uv.new_pipe()
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local handle, pid = uv.spawn("sshfs",
    { args = { "-p", host_info.port, host_info.user .. "@" .. host_info.host .. ":" .. host_info.remote_dir, host_info.mount_dir }, stdio = {stdin, stdout, stderr} },
    function(code, signal)
      uv.write(stdout, tostring(code) .. "," .. tostring(signal))
      handle:close()
      -- mount_res.code = code
      -- mount_res.signal = signal
    end)

  -- local host_passwd = vim.fn.inputsecret("Enter password: ")
  --
  -- uv.write(stdin, host_passwd)

  uv.read_start(stdout, function(err, chunk)
    if err then
      -- vim.notify("Got error reading from stdout pipe: " .. err, vim.log.levels.ERROR)
      mount_res.code = -1
    elseif chunk then
      for code, sig in string.gmatch(chunk, "(%d+),(%d+)") do
        mount_res.code = code
        mount_res.signal = signal
      end
      uv.read_stop(stdout)
    else
      -- vim.notify("Disconnect from pipe", vim.log.levels.ERROR)
      mount_res.code = -2
    end
  end)

  uv.shutdown(stdin, function()
    uv.close(handle)
  end)

  if mount_res.code == -1 then
    vim.notify("Got error reading from stdout pipe: " .. err, vim.log.levels.ERROR)
    return nil
  elseif mount_res.code == -2 then
    vim.notify("Disconnect from pipe", vim.log.levels.ERROR)
    return nil
  end

  if M.hostnames[host_info_input] then
    host_info.nth = M.hostnames[host_info_input] + 1
  else
    M.hostnames[host_info_input] = 1
  end

  M.hosts[host_info_input .. "#" .. tostring(host_info.nth)] = host_info
  return host_info.mount_dir
end

function M.open_host()
  local mounted_path = M.read_host()
  print(mounted_path)
  if mounted_path == nil then
    vim.notify("Failed to properly create and mount", vim.log.levels.ERROR)
  else
    vim.fn.chdir(mounted_path)
    require("nvim-tree.api").tree.open()
  end
end

function M.close_host(hostinfo)
  local res = os.execute("umount " .. hostinfo.mount_dir)

  if res ~= 0 then
    vim.notify("Failed to unmount directory", vim.log.levels.ERROR)
    return
  end

  -- local handle, pid = uv.spawn("umount",
  --   { args = { host_info.mount_dir } },
  --   function(code, signal)
  --     umount_res.code = code
  --     umount_res.signal = signal
  --   end)
  --
  --   uv.unref(handle)

    uv.fs_rmdir(hostinfo.mount_dir)
end

function M.close_host_prompt()
  local hosts = {}
  for host, _ in pairs(M.hosts) do
    table.insert(hosts, host)
  end

  fzf_lua.fzf_exec(hosts, {
    prompt = "Close host> ",
    actions = {
      ["default"] = function(selected)
        M.close_host(M.hosts[selected[1]])
      end,
    }
  })

end

function M.close_all()
  for _, info in pairs(M.hosts) do
    M.close_host(info)
  end
end

return M
