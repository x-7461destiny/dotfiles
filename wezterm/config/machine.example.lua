-- Copy this file to machine_local.lua and edit it for one machine.
-- machine_local.lua is ignored by Git.
local wezterm = require('wezterm')

return {
   -- Used only for the optional "PowerShell proxy" launch entry.
   proxy_url = nil,

   -- Keep the image outside this repository. Examples:
   -- Windows: wezterm.home_dir .. '/Pictures/WezTerm/background.jpg'
   -- Linux:   wezterm.home_dir .. '/.local/share/wezterm/background.jpg'
   background = {
      image = nil,
      overlay_color = '#000000',
      overlay_opacity = 0.85,
   },

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

   -- Prefer SSH aliases from ~/.ssh/config instead of embedding IP addresses.
   launch_menu = {
      { label = 'Example server', args = { 'ssh', 'example-host' } },
   },

   ssh_domains = {
      {
         multiplexing = 'None',
         name = 'example-host',
         remote_address = 'example.com:22',
         username = 'user',
         ssh_option = {
            identityfile = wezterm.home_dir .. '/.ssh/id_ed25519',
         },
      },
   },
}
