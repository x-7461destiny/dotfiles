
return {
  "pocco81/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" }, -- 触发自动保存的事件
  opts = {
    enabled = true, -- 启用插件
    execution_message = {
      message = function()
        return "💾 " .. vim.fn.strftime("%H:%M:%S")
      end,
      dim = 0.5,
      cleaning_interval = 1250,
    },
    -- 触发条件
    trigger_events = { "InsertLeave", "TextChanged" },
    condition = function(buf)
      -- 禁止在一些特殊 buffer 中自动保存，例如终端、git commit 等
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      if buftype == "nofile" or buftype == "prompt" or buftype == "terminal" then
        return false
      end
      -- 如果文件是只读的，也不保存
      if vim.api.nvim_get_option_value("readonly", { buf = buf }) then
        return false
      end
      return true
    end,
    debounce = 150, -- 延迟150毫秒执行保存，避免过于频繁
    write_all_buffers = false, -- 是否保存所有打开的 buffer
  },
}
