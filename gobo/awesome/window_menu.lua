
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
   local my_tags = c:tags()

   local s_tags = {}
   local in_tag = {}
   for i = 1, 4 do
      s_tags[i] = awful.tag.gettags(client.focus.screen)[i]
      for _, t in ipairs(my_tags) do
         if t == s_tags[i] then
            in_tag[i] = true
            break
         end
      end
   end
   
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
      "Send to...", {
         {
            "Virtual desktop 1", function()
               awful.client.movetotag(s_tags[1])
            end,
            in_tag[1] and beautiful.check_icon or nil,
         },{
            "Virtual desktop 2", function()
               awful.client.movetotag(s_tags[2])
            end,
            in_tag[2] and beautiful.check_icon or nil,
         },{
            "Virtual desktop 3", function()
               awful.client.movetotag(s_tags[3])
            end,
            in_tag[3] and beautiful.check_icon or nil,
         },{
            "Virtual desktop 4", function()
               awful.client.movetotag(s_tags[4])
            end,
            in_tag[4] and beautiful.check_icon or nil,
         }
      }
   })
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

   entries.theme = { height = 24, width = 170 }
   local menu = awful.menu.new(entries)
   menu:show(menu_opts)
   window_menus[c] = menu
end

return window_menu
