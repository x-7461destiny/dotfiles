local platform = require('utils.platform')()

local options = {
   default_prog = {},
   launch_menu = {},
}

if platform.is_win then
   options.default_prog = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' }
   options.launch_menu = {
      { label = 'PowerShell Core', args = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' } },
      { 
         label = 'PowerShell proxy', 
         args = { 'C:\\Program Files\\PowerShell\\7\\pwsh.exe' },
         set_environment_variables = {
            HTTP_PROXY = "http://127.0.0.1:7890",
            HTTPS_PROXY = "http://127.0.0.1:7890"
         }
      },
      { label = 'PowerShell Desktop', args = { 'powershell' } },
      { label = 'Command Prompt', args = { 'cmd' } },
      { label = 'Nushell', args = { 'nu' } },
      {
         label = 'Git Bash',
         args = { 'D:\\git\\Git\\bin\\bash.exe' },
      },
      {
         label = 'wsl2',
         args = { 'ubuntu2204.exe' },
      },
      {
         label = 'huawei',
         args = { 'ssh', 'root@166.108.224.3', '-p', '2200' },
      },
      {
         label = 'vm',
         args = { 'ssh', 'root@192.168.0.105', '-p', '22' },
      },
      {
         label = 'vmrack',
         args = { 'ssh', 'root@38.64.60.162', '-p', '22' },
      },
      {
         label = 'oracle',
         args = { 'ssh', 'root@129.154.200.53', '-p', '2200' },
      },
      {
         label = 'oracle_proxy',
         args = {'ssh', 'oracle_proxy'}
      },
      {
         label = 'huawei conf',
         args = {'ssh', 'huawei'}
      },
   }
elseif platform.is_mac then
   options.default_prog = { '/opt/homebrew/bin/fish' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash' } },
      { label = 'Fish', args = { '/opt/homebrew/bin/fish' } },
      { label = 'Nushell', args = { '/opt/homebrew/bin/nu' } },
      { label = 'Zsh', args = { 'zsh' } },
   }
end

return options
