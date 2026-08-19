local platform = require('utils.platform')()
local machine = require('config.machine')

local options = {
   default_prog = {},
   launch_menu = {},
}

if platform.is_win then
   local powershell = machine.windows.powershell
   options.default_prog = { powershell }
   options.launch_menu = {
      { label = 'PowerShell Core', args = { powershell } },
      { label = 'PowerShell Desktop', args = { 'powershell' } },
      { label = 'Command Prompt', args = { 'cmd' } },
      { label = 'Nushell', args = { 'nu' } },
      { label = 'Git Bash', args = { machine.windows.git_bash } },
   }

   if machine.proxy_url then
      table.insert(options.launch_menu, 2, {
         label = 'PowerShell proxy',
         args = { powershell },
         set_environment_variables = {
            HTTP_PROXY = machine.proxy_url,
            HTTPS_PROXY = machine.proxy_url,
         },
      })
   end

   local wsl = machine.windows.wsl
   if wsl.enabled then
      table.insert(options.launch_menu, {
         label = wsl.name,
         args = { 'wsl.exe', '-d', wsl.distribution },
      })
   end
elseif platform.is_mac then
   local shell = os.getenv('SHELL') or 'zsh'
   options.default_prog = { shell }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash' } },
      { label = 'Default shell', args = { shell } },
      { label = 'Zsh', args = { 'zsh' } },
   }
elseif platform.is_linux then
   local shell = os.getenv('SHELL') or 'bash'
   options.default_prog = { shell }
   options.launch_menu = {
      { label = 'Default shell', args = { shell } },
      { label = 'Bash', args = { 'bash' } },
   }
end

for _, entry in ipairs(machine.launch_menu) do
   table.insert(options.launch_menu, entry)
end

return options
