-- Originally written by Antonio Terceiro
-- https://github.com/terceiro/awesome-freedesktop
-- Hacked by Alex Y. <yakushev.alex@gmail.com>

-- Grab environment
local utils = require("menubar.utils")
local ipairs = ipairs
local string = string
local table = table

module("menubar.menu_gen")

all_menu_dirs = { '/usr/share/applications/' }

all_categories = {
   { app_type = "AudioVideo", name = "Multimedia",
     icon_name = "applications-multimedia.png", use = true },
   { app_type = "Development", name = "Development",
     icon_name = "applications-development.png", use = true },
   { app_type = "Education", name = "Education",
     icon_name = "applications-science.png", use = false },
   { app_type = "Game", name = "Games",
     icon_name = "applications-games.png", use = true },
   { app_type = "Graphics", name = "Graphics",
     icon_name = "applications-graphics.png", use = true },
   { app_type = "Office", name = "Office",
     icon_name = "applications-office.png", use = true },
   { app_type = "Network", name = "Internet",
     icon_name = "applications-internet.png", use = true },
   { app_type = "Settings", name = "Settings",
     icon_name = "applications-utilities.png", use = false },
   { app_type = "System", name = "System Tools",
     icon_name = "applications-system.png", use = true },
   { app_type = "Utility", name = "Accessories",
     icon_name = "applications-accessories.png", use = true }
}

function lookup_category_icons()
   for i, v in ipairs(all_categories) do
      v.icon = utils.lookup_icon(v.icon_name)
   end
end

lookup_category_icons()

local function get_category_and_number_by_type(app_type)
   for i, v in ipairs(all_categories) do
      if app_type == v.app_type then
         return i, v
      end
   end
   return nil
end

local function esc_q(s)
   if s then
      -- Remove all non-printable characters
      return string.gsub(string.gsub(s, "'" ,"\\'"),
                         "(.)", function(c)
                                   if string.byte(c, 1) > 31 then
                                      return c
                                   else
                                      return ""
                                   end
                                end)
   else
      return ""
   end
end

function generate()
   local result = {}

   for i, dir in ipairs(all_menu_dirs) do
      local entries = utils.parse_dir(dir) do
         for i, program in ipairs(entries) do
            -- check whether to include in the menu
            if program.show and program.Name and program.cmdline then
               local target_category = nil
               if program.categories then
                  for _, category in ipairs(program.categories) do
                     local category_id, cat =
                        get_category_and_number_by_type(category)
                     if category_id and cat.use then
                        target_category = category_id
                        break
                     end
                  end
               end
               if target_category then
                  table.insert(result, { name = esc_q(program.Name) or "",
                                         cmdline = esc_q(program.cmdline) or "",
                                         icon = utils.lookup_icon(esc_q(program.icon_path)) or nil,
                                         category = target_category })
               end
            end
         end
      end
   end

   return result
end
