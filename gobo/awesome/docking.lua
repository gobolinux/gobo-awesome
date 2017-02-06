
local docking = {}

local awful = require("awful")
local beautiful = require("beautiful")
local mouse = mouse
local screen = screen
local mousegrabber = mousegrabber
local timer = require("gears.timer") or timer

local auto_tile = {}
setmetatable(auto_tile, { __mode = "k" })

local function undock_auto_tile(c)
   c.border_width = beautiful.border_width
   auto_tile[c] = nil
end

function docking.move_key(orient, delta, mods, key)
   local size, pos, upleft, downright
   if orient == "vertical" then
      size, pos, upleft, downright = "height", "y", "up", "down"
   else
      size, pos, upleft, downright = "width", "x", "left", "right"
   end
   local fn = function(c)
      local curr = c:geometry()
      if auto_tile[c] then
         local mode = auto_tile[c].mode
         if mode == upleft then
            c:geometry({ [size] = curr[size] + delta })
         elseif mode == downright then
            c:geometry({ [size] = curr[size] - delta, [pos] = curr[pos] + delta })
         end
      else
         c:geometry({ [pos] = curr[pos] + delta })
      end
   end
   return awful.key(mods, key, fn, { description = "Move floating window", group = "awesome gobolinux" })
end

function docking.resize_key(orient, delta, mods, key)
   local size
   if orient == "vertical" then
      size = "height"
   else
      size = "width"
   end
   local fn = function(c)
      local curr = c:geometry()
      if not auto_tile[c] then
         c:geometry({ [size] = curr[size] + delta })
      end
   end
   return awful.key(mods, key, fn, { description = "Resize floating window", group = "awesome gobolinux" })
end

local function save_relative_geometry(c, geo, reference)
   if not auto_tile[c] then
      local old = {
         x = geo.x - reference.x,
         y = geo.y - reference.y,
         width = geo.width,
         height = geo.height,
      }
      auto_tile[c] = { old = old }
   end
end

local corner_fns = {
}

local function get_corner_fn(bottom, right)
   local key = bottom.."-"..right
   if not corner_fns[key] then
      corner_fns[key] = function(c)
         local area = screen[c.screen].workarea
         undock_auto_tile(c)
         c.maximized = false
         c:geometry({
            x = area.x + (right == "right" and (area.width / 2) or 0),
            y = area.y + (bottom == "bottom" and (area.height / 2) or 0),
            width = (area.width / 2) - (c.border_width * 2),
            height = (area.height / 2) - (c.border_width * 2),
         })
      end
   end
   return corner_fns[key]
end

function docking.corner_key(bottom, right, mods, key)
   local corner_fn = get_corner_fn(bottom, right)
   return awful.key(mods, key, corner_fn, { description = "Arrange at "..bottom.."-"..right.." corner", group = "awesome gobolinux" })
end

local cornering = {
   bottom = nil,
   right = nil,
   timer = nil
}

local function check_corner(c, bottom, right, non_corner_fn)
   if cornering.timer then
      if (cornering.bottom and not bottom) or (cornering.right and not right) then
         cornering.timer:stop()
         local corner_fn = get_corner_fn(cornering.bottom or bottom, cornering.right or right)
         cornering.timer = nil
         cornering.right = nil
         cornering.bottom = nil
         corner_fn(c)
         return true
      end
   else
      cornering.x = c.x
      cornering.y = c.y
      local my_timer = timer({timeout = 0.05})
      cornering.timer = my_timer
      cornering.right = right
      cornering.bottom = bottom
      my_timer:connect_signal("timeout", function()
         my_timer:stop()
         cornering.timer = nil
         cornering.right = nil
         cornering.bottom = nil
         non_corner_fn()
      end)
      cornering.timer:start()
   end
end

function docking.dock_left(c)
   check_corner(c, nil, "left", function()
      local curr = c:geometry()
      local area = screen[c.screen].workarea
      local s_area = area
      local half = math.floor(area.width / 2)
      local offset = 0
      local mode = "left"
      local maxd = c.maximized
      if (maxd or (curr.x == area.x and curr.y == area.y)) and area.x > 0 then
         local nextscreen = awful.screen.getbycoord(area.x - 1, area.y)
         if maxd then
            area = screen[nextscreen].workarea
            half = area.width
            offset = 0
            mode = "up"
            c.screen = nextscreen
         elseif auto_tile[c] and auto_tile[c].mode == "left" then
            area = screen[nextscreen].workarea
            half = math.floor(area.width / 2)
            offset = half
            mode = "right"
         end
      else
         c.maximized = false
      end
      c:geometry({ x = area.x + offset,
         y = area.y,
         width = half,
         height = area.height
      })
      save_relative_geometry(c, curr, s_area)
      auto_tile[c].mode = mode
      c.border_width = 0
   end)
end

function docking.dock_right(c)
   check_corner(c, nil, "right", function()
      local area = screen[c.screen].workarea
      local s_area = area
      local half = math.floor(area.width / 2)
      local curr = c:geometry()
      local offset = 0
      local mode = "right"
      local nextscreen = awful.screen.getbycoord(area.x + area.width, area.y, -1)
      local maxd = c.maximized
      if (maxd or (curr.x == area.x + half and curr.y == area.y)) and nextscreen ~= c.screen.index then
         area = screen[nextscreen].workarea
         if maxd then
            half = area.width
            offset = area.width
            mode = "up"
            c.screen = nextscreen
         else
            half = math.floor(area.width / 2)
            offset = half
            mode = "left"
         end
      else
         c.maximized = false
      end
      c:geometry({ x = area.x + half - offset,
         y = area.y,
         width = half,
         height = area.height
      })
      save_relative_geometry(c, curr, s_area)
      auto_tile[c].mode = mode
      c.border_width = 0
   end)
end

function docking.dock_up(c)
   check_corner(c, "top", nil, function()
      local area = screen[c.screen].workarea
      local half = math.floor(area.height / 2)
      local curr = c:geometry()
      local tophalf = (curr.x == area.x and curr.y == area.y and math.abs(curr.height - half) < 20)
      if c.maximized or (not tophalf) then
         c.maximized = false
         c:geometry({ x = area.x,
            y = area.y,
            width = area.width,
            height = half,
         })
      elseif tophalf then
         c.maximized = true
         c:geometry({ x = area.x,
            y = area.y,
            width = area.width,
            height = area.height,
         })
      end
      save_relative_geometry(c, curr, area)
      auto_tile[c].mode = "up"
      c.border_width = 0
   end)
end

function docking.dock_down(c)
   check_corner(c, "bottom", nil, function()
      c.maximized = false
      local area = screen[c.screen].workarea
      local half = math.floor(area.height / 2)
      local curr = c:geometry()
      if curr.y ~= area.y + half then
         c:geometry({ x = area.x,
            y = area.y + half,
            width = area.width,
            height = half,
         })
         save_relative_geometry(c, curr, area)
         auto_tile[c].mode = "down"
         c.border_width = 0
      elseif auto_tile[c] then
         local old = auto_tile[c].old
         if old.x == 0 and old.y == 0 then
            old = {
               x = area.x + (area.width / 4),
               y = area.y + (area.height / 4),
               width = area.width / 2,
               height = area.height / 2,
            }
         else
            old.x = old.x + area.x
            old.y = old.y + area.y
         end
         c:geometry(old)
         awful.placement.no_offscreen(c)
         undock_auto_tile(c)
      end
   end)
end

function docking.smart_mouse_move(c)
   if c.maximized then
      c.border_width = 0
      mousegrabber.run(
         function(_mouse)
            if _mouse.buttons[1] then
               local ms = mouse.screen
               if mouse.screen ~= c.screen then
                  c.screen = ms
                  c:geometry(screen[ms].workarea)
               end
               return true
            end
            return false
         end,
         "fleur"
      )
   else
      undock_auto_tile(c)
      awful.mouse.client.move(c)
   end
end

return docking

