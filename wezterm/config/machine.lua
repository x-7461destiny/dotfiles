local defaults = {
   proxy_url = nil,
   windows = {
      powershell = 'pwsh',
      git_bash = 'bash',
      wsl = {
         enabled = false,
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         username = nil,
         default_cwd = nil,
         default_prog = nil,
      },
   },
   launch_menu = {},
   ssh_domains = {},
}

local function is_array(value)
   return type(value) == 'table' and value[1] ~= nil
end

local function merge(base, override)
   if type(base) ~= 'table' or type(override) ~= 'table' or is_array(base) or is_array(override) then
      return override
   end

   local result = {}
   for key, value in pairs(base) do
      result[key] = value
   end
   for key, value in pairs(override) do
      result[key] = result[key] ~= nil and merge(result[key], value) or value
   end
   return result
end

local ok, local_config = pcall(require, 'config.machine_local')
if not ok and tostring(local_config):match("module 'config%.machine_local' not found") then
   return defaults
end
if not ok then
   error(local_config)
end

return merge(defaults, local_config)
