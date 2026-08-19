local platform = require('utils.platform')()
local machine = require('config.machine')

local options = {
   ssh_domains = machine.ssh_domains,

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {
      {
         name = 'unix',
      },
   },
   default_gui_startup_args = { 'connect', 'unix' },

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
}

if platform.is_win then
   local wsl = machine.windows.wsl
   if not wsl.enabled then
      return options
   end

   options.wsl_domains = {
      {
         name = wsl.name,
         distribution = wsl.distribution,
         username = wsl.username,
         default_cwd = wsl.default_cwd,
         default_prog = wsl.default_prog,
      },
   }
end

return options
