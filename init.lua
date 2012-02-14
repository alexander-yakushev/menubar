-- Advanced menu replacement similar to dmenu
-- @author Alexander Yakushev <yakushev.alex@gmail.com>
-- @license WTFPL version 2 http://sam.zoy.org/wtfpl/COPYING
-- @version 0.1.0

-- Grab environment we need
local capi = { client = client,
               screen = screen}
local setmetatable = setmetatable
local ipairs = ipairs
local table = table
local theme = require("beautiful")
local menu_gen = require("menubar.menu_gen")
local prompt = require("menubar.prompt")
local awful = require("awful")
local common = require("awful.widget.common")
local tonumber = tonumber
local string = string
local mouse = mouse
local math = math
local keygrabber = keygrabber
local print = print
local wibox = require("wibox")

module("menubar")

current_item = 1
previous_item = nil
current_category = nil
shownitems = nil
cache_entries = true
show_categories = true

instance = { prompt = nil,
             widget = nil,
             wibox = nil }

common_args = { w = wibox.layout.fixed.horizontal(),
                data = setmetatable({}, { __mode = 'kv' }) }

g = { width = nil,
      height = 20,
      x = nil,
      y = nil }

local function colortext(s, c)
   return "<span color='" .. c .. "'>" .. s .. "</span>"
end

local function label(o)
   if o.focused then
      return
      colortext(o.name, awful.util.color_strip_alpha(theme.fg_focus)) or o.name,
      theme.bg_focus, nil, o.icon
   else
      return o.name, theme.bg_normal, nil, o.icon
   end
end

local function perform_action(o)
   if not o or o.empty then
      return true
   end
   if o.cat_id then
      current_category = o.cat_id
      local new_prompt = shownitems[current_item].name .. ": "
      previous_item = current_item
      current_item = 1
      return true, "", new_prompt
   elseif shownitems[current_item].cmdline then
      awful.util.spawn(shownitems[current_item].cmdline)
      hide()
      return true
   end
end

local function initialize(scr)
   instance.wibox = wibox({screen = scr or mouse.screen})
   instance.widget = new()
   instance.wibox.ontop = true
   instance.prompt = awful.widget.prompt()
   local layout = wibox.layout.fixed.horizontal()
   layout:add(instance.prompt)
   layout:add(instance.widget)
   instance.wibox:set_widget(layout)
end

function refresh(use_cache)
   menu_entries = menu_gen.generate()
end

function show(scr)
   if not instance.wibox then
      initialize(scr)
   elseif instance.wibox.visible then -- Menu already shown, exit
      return
   elseif not cache_entries then
      refresh()
   end

   -- Set position and size
   local scrgeom = capi.screen[scr or 1].workarea
   local x = g.x or scrgeom.x
   local y = g.y or scrgeom.y
   instance.wibox.height = g.height or 20
   instance.wibox.width = g.width or scrgeom.width
   instance.wibox:geometry({x = x, y = y})

   current_item = 1
   current_category = nil
   menulist_update()
   prompt.run({ prompt = "Run app: " }, instance.prompt.widget, function(s) end, nil,
              awful.util.getdir("cache") .. "/history_menu", nil,
              hide,
              menulist_update,
              function(mod, key, comm)
                 if key == "Left" or (mod.Control and key == "j") then
                    current_item = math.max(current_item - 1, 1)
                    return true
                 elseif key == "Right" or (mod.Control and key == "k") then
                    current_item = current_item + 1
                    return true
                 elseif key == "BackSpace" then
                    if comm == "" and current_category then
                       current_category = nil
                       current_item = previous_item
                       return true, nil, "Run app: "
                    end
                 elseif key == "Escape" then
                    if current_category then
                       current_category = nil
                       current_item = previous_item
                       return true, nil, "Run app: "
                    end
                 elseif key == "Return" then
                    return perform_action(shownitems[current_item])
                 end
                 return false
              end)
   instance.wibox.visible = true
end

function hide()
   keygrabber.stop()
   instance.wibox.visible = false
end

local function nocase (s)
   s = string.gsub(s, "%a",
                   function (c)
                      return string.format("[%s%s]", string.lower(c),
                                           string.upper(c))
                   end)
   return s
end -- nocase

function menulist_update(query)
   local query = query or ""
   shownitems = {}
   local match_inside = {}

   -- We add entries that match from the beginning to the table
   -- shownitems, and those that match in the middle to the table
   -- match_inside.
   if show_categories then
      for i, v in ipairs(menu_gen.all_categories) do
         v.focused = false
         if not current_category and v.use then
            if string.match(v.name, nocase(query)) then
               if string.match(v.name, "^" .. nocase(query)) then
                  table.insert(shownitems, v)
               else
                  table.insert(match_inside, v)
               end
            end
         end
      end
   end

   for i, v in ipairs(menu_entries) do
      v.focused = false
      if not current_category or v.category == current_category then
         if string.match(v.name, nocase(query)) then
            if string.match(v.name, "^" .. nocase(query)) then
               table.insert(shownitems, v)
            else
               table.insert(match_inside, v)
            end
         end
      end
   end

   -- Now add items from match_inside to shownitems
   for i, v in ipairs(match_inside) do
      table.insert(shownitems, v)
   end

   if #shownitems > 0 then
      if current_item > #shownitems then
         current_item = #shownitems
      end
      shownitems[current_item].focused = true
   else
      table.insert(shownitems, { name = "&lt;no matches&gt;", icon = nil,
                                 empty = true })
   end

   common.list_update(common_args.w, nil, label,
                      common_args.data,
                      shownitems)
end

function new()
   if app_folders then
      menu_gen.all_menu_dirs = app_folders
   end
   refresh()
   -- Load categories icons and add IDs to them
   for i, v in ipairs(menu_gen.all_categories) do
--      v.icon = (v.icon ~= nil) and capi.image(v.icon) or nil
      v.cat_id = i
   end
   menulist_update()
   return common_args.w
end

function set_icon_theme(theme_name)
   utils.icon_theme = theme_name
   menu_gen.lookup_category_icons()
end

setmetatable(_M, { __call = function(_, ...) return new(...) end })