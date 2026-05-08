local palette = require "onedark.palette"

local M = {}

M.make_theme = function(style)
  local c = palette[style]

  if not c then
    error("Unknown onedark style: " .. tostring(style))
  end

  local theme = {
    base_30 = {
      white = c.fg,
      darker_black = c.black,
      black = c.bg_d,
      black2 = c.bg1,
      one_bg = c.bg0,
      one_bg2 = c.bg2,
      one_bg3 = c.bg3,
      grey = c.grey,
      grey_fg = c.grey,
      grey_fg2 = c.light_grey,
      light_grey = c.light_grey,
      red = c.red,
      baby_pink = c.red,
      pink = c.purple,
      line = c.bg3,
      green = c.green,
      vibrant_green = c.green,
      nord_blue = c.bg_blue,
      blue = c.blue,
      yellow = c.yellow,
      sun = c.bg_yellow,
      purple = c.purple,
      dark_purple = c.dark_purple,
      teal = c.cyan,
      orange = c.orange,
      cyan = c.cyan,
      statusline_bg = c.bg_d,
      lightbg = c.bg1,
      pmenu_bg = c.blue,
      folder_bg = c.blue,
    },
    base_16 = {
      base00 = c.bg0,
      base01 = c.bg1,
      base02 = c.bg2,
      base03 = c.grey,
      base04 = c.light_grey,
      base05 = c.fg,
      base06 = c.fg,
      base07 = c.fg,
      base08 = c.red,
      base09 = c.orange,
      base0A = c.yellow,
      base0B = c.green,
      base0C = c.cyan,
      base0D = c.blue,
      base0E = c.purple,
      base0F = c.dark_red,
    },
    type = style == "light" and "light" or "dark",
  }

  return require("base46").override_theme(theme, "onedark-" .. style)
end

return M
