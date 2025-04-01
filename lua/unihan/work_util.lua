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

  --
  -- other
  --

  if opts.kuankhiunn then
    data = util.readfile_sync(vim.uv, opts.kuankhiunn)
    if data then
      dict:load_kuankhiunn(data, opts.kuankhiunn)
    end
  end

  local kyu_file = opts.kyu_file
  if kyu_file then
    data = util.readfile_sync(vim.uv, kyu_file)
    if data then
      dict:load_kyu(data, kyu_file)
    end
  end

  local chinadat_file = opts.chinadat
  if chinadat_file then
    data = util.readfile_sync(vim.uv, chinadat_file)
    if data then
      dict:load_chinadat(data, chinadat_file)
    end
  end

  for _, path in ipairs(opts.skk_jisyo) do
    data = util.readfile_sync(vim.uv, path)
    if data then
      dict:load_skk(data, path)
    end
  end

  local user_dict = opts.user_dict
  if user_dict then
    data = util.readfile_sync(vim.uv, user_dict)
    if data then
      local json = vim.json.decode(data)
      dict:load_user(json)
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
    local Sbgy = require "unihan.Sbgy"
    Sbgy.setmetatable(dict.sbgy)
    ---@cast dict unihan.UnihanDict
    on_completed(dict)
  end)()
end

return M
