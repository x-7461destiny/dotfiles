return {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {
      {
         multiplexing = 'None',
         name = 'oracle_proxy',
         remote_address = '129.154.200.53:2200',

         username = 'root',
         ssh_option = {
            identifyfile = 'C:\\Users/Arutorialo\\.ssh\\id_rsa',
            ProxyCommand = 'nc -x 127.0.0.1:7890 %h %p',
         },
      },
      -- multiplexing = 'None',
      -- name = 'aliyun',
      -- remote_address = '112.74.105.26',
      -- username = 'root',
      -- ssh_option = {
      --    identifyfile = 'C:\\Users/Arutorialo/.ssh/id_rsa',
      -- },
      --      port = 22,
   },

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {
      {
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         username = 'kevin',
         default_cwd = '/home/kevin',
         default_prog = { 'fish' },
      },
   },
}
