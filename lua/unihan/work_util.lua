---@param encoded string
---@return string string.buffer encoded
local function parse_unihan(encoded)
  local opts = require("string.buffer").decode(encoded)
  ---@cast opts unihan.Opts
  local UnihanDict = require "unihan.UnihanDict"
  local dict = UnihanDict.new()
  local util = require "unihan.util"

  ---@param key string
  local function load_opts(key)
    local value = opts[key]
    if value then
      local data = util.readfile_sync(vim.uv, value)
      if data then
        dict["load_" .. key](dict, data, value)
      end
    end
  end

  load_opts "unihan_likedata"
  load_opts "unihan_readings"
  load_opts "unihan_variants"
  load_opts "unihan_othermappings"
  load_opts "sbgy"
  load_opts "kangxi"
  load_opts "xszd"
  load_opts "kuankhiunn"
  load_opts "kyu"
  load_opts "chinadat"
  load_opts "user_dict"

  -- skk
  for _, path in ipairs(opts.skk_jisyo) do
    local data = util.readfile_sync(vim.uv, path)
    if data then
      dict:load_skk(data, path)
    end
  end

  return require("string.buffer").encode(dict)
end

local M = {}

---@param opts unihan.Opts
function M.async_load(opts, on_completed)
  local async = require "plenary.async"
  async.void(function()
    local function async_parse(src, callback)
      local work = vim.uv.new_work(parse_unihan, callback)
      return work:queue(src)
    end
    local encoded = async.wrap(async_parse, 2)(require("string.buffer").encode(opts))
    assert(encoded, vim.inspect(opts))
    ---@diagnostic disable
    local dict = require("string.buffer").decode(encoded)
    ---@cast dict unihan.UnihanDict
    require("unihan.UnihanDict").resetmetatable(dict)
    local Sbgy = require "unihan.Sbgy"
    Sbgy.setmetatable(dict.sbgy)
    on_completed(dict)
  end)()
end

return M
