-- local version = _VERSION:match("%d+%.%d+")

local function dirname(src)
  local found = src:find "tests[/\\]_helper.lua$"
  if found then
    if found == 1 then
      return "."
    end
    return src:sub(1, found)
  end

  return src
end

local file = debug.getinfo(1, "S").source:sub(2)
local dir = dirname(file)
-- print("file=>", dir)

local utf8_path = ("%s/nvim-data/lazy/utf8.nvim/lua/?.lua"):format(os.getenv "LOCALAPPDATA")

package.path = ([[%s/lua/?.lua;%s/lua/?/init.lua;%s;]]):format(dir, dir, utf8_path) .. package.path

-- print(package.path)
