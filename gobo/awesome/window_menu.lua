
local window_menu = {}

local beautiful = require("beautiful")
local awful = require("awful")

local window_menus = {}
setmetatable(window_menus, { __mode = "k" })

function window_menu.hide(c)
   if window_menus[c] then
      window_menus[c]:hide()
      window_menus[c] = nil
   end
end

function window_menu.show(c, menu_opts)
   window_menu.hide(c)
   local entries = {}
   
   if c.maximized then
      table.insert(entries, {
         "Restore", function()
            c.maximized_vertical = false
            c.maximized_horizontal = false
         end,
         beautiful.titlebar_maximized_button_focus_active })
   else
      table.insert(entries, {
         "Maximize", function()
            c.maximized = true
         end,
         beautiful.titlebar_maximized_button_focus_inactive })
   end
   
   table.insert(entries, {
      "Minimize", function()
         c.minimized = true
      end,
      beautiful.titlebar_minimize_button_focus_inactive })
   table.insert(entries, {
      "Always on top", function()
         c.ontop = not c.ontop
      end,
      c.ontop and beautiful.check_icon or nil})
   table.insert(entries, {
      "Full screen", function()
         c.fullscreen = not c.fullscreen
      end,
      c.fullscreen and beautiful.check_icon or nil })
   table.insert(entries, {
      "Close", function() 
         c:kill() 
      end, 
      beautiful.titlebar_close_button_focus })

   entries.theme = { height = 24, width = 150 }
   local menu = awful.menu.new(entries)
   menu:show(menu_opts)
   window_menus[c] = menu
end

return window_menu
