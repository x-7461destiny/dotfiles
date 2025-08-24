local wezterm = require('wezterm')
local mux = wezterm.mux

local M = {}

-- Center a specific gui_window
M.center_gui_window = function(gui_window)
  if not gui_window then return end

  local screens = wezterm.gui.screens()
  local active_screen = screens.active or screens.main
  if not active_screen then return end

  local dims = gui_window:get_dimensions()
  local window_width = dims.pixel_width
  local window_height = dims.pixel_height

  local work = {
    x = active_screen.x or screens.origin_x or 0,
    y = active_screen.y or screens.origin_y or 0,
    width = active_screen.width or screens.virtual_width,
    height = active_screen.height or screens.virtual_height,
  }

  local target_x = work.x + math.floor((work.width - window_width) / 2)
  local target_y = work.y + math.floor((work.height - window_height) / 2)

  wezterm.log_info('center to:', { x = target_x, y = target_y })
  gui_window:set_position(target_x, target_y)
end

M.setup = function()
  wezterm.on('gui-startup', function(cmd)
    local _tab, _pane, window = mux.spawn_window(cmd or {})
    local gui_window = window:gui_window()

    -- Center immediately
    M.center_gui_window(gui_window)

    -- Conditional recenter if size changed shortly after startup
    if wezterm.time and wezterm.time.call_after then
      local initial_dims = gui_window:get_dimensions()
      wezterm.time.call_after(0.25, function()
        local new_dims = gui_window:get_dimensions()
        local dw = math.abs((new_dims.pixel_width or 0) - (initial_dims.pixel_width or 0))
        local dh = math.abs((new_dims.pixel_height or 0) - (initial_dims.pixel_height or 0))
        if dw > 2 or dh > 2 then
          M.center_gui_window(gui_window)
        end
      end)
    end
  end)
end

return M
