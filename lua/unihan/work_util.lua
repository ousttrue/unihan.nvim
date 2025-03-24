---@class unihan.Opts
---@field jisyo string|table|nil path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan_dir string? path to dir. Extracted https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
---@field xszd string? path to xszd.txt from https://github.com/cjkvi/cjkvi-dict
---@field kangxi string? kx2ucs.txt from https://github.com/cjkvi/cjkvi-dict
---@field chinadat string? path to chinadat.csv from https://www.seiwatei.net/info/dnchina.htm
---@field kuankhiunn string? 有女同車《〈廣韻〉全字表》原表 path to Kuankhiunn0704-semicolon.txt from https://github.com/syimyuzya/guangyun0704
---@field sbgy string? 宋本廣韻
---@field user string? path to user_dict.json
---@field dir string? basedir

---@param encoded string
---@return string string.buffer encoded
local function parse_unihan(encoded)
  local opts = require("string.buffer").decode(encoded)
  ---@cast opts unihan.Opts
  local UnihanDict = require "unihan.UnihanDict"
  local dict = UnihanDict.new()
  local util = require "unihan.util"

  local unihan_dir = opts.unihan_dir or opts.dir
  local unihan_like_file = unihan_dir .. "/Unihan_DictionaryLikeData.txt"
  local data = util.readfile_sync(vim.uv, unihan_like_file)
  if data then
    dict:load_unihan_likedata(data, unihan_like_file)
  end

  local unihan_reading_file = unihan_dir .. "/Unihan_Readings.txt"
  data = util.readfile_sync(vim.uv, unihan_reading_file)
  if data then
    dict:load_unihan_readings(data, unihan_reading_file)
  end

  local unihan_variants_file = unihan_dir .. "/Unihan_Variants.txt"
  data = util.readfile_sync(vim.uv, unihan_variants_file)
  if data then
    dict:load_unihan_variants(data, unihan_variants_file)
  end

  data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_OtherMappings.txt")
  if data then
    dict:load_unihan_othermappings(data)
  end

  if opts.sbgy then
    data = util.readfile_sync(vim.uv, opts.sbgy)
    if data then
      dict:load_sbgy(data, opts.sbgy)
    end
  end

  if opts.kuankhiunn then
    data = util.readfile_sync(vim.uv, opts.kuankhiunn)
    if data then
      dict:load_kuankhiunn(data, opts.kuankhiunn)
    end
  end

  if opts.kangxi then
    data = util.readfile_sync(vim.uv, opts.kangxi)
    if data then
      dict:load_kangxi(data)
    end
  end

  do
    local xszd_file = opts.xszd and opts.xszd or (vim.fs.joinpath(opts.dir, "cjkvi-dict-master/xszd.txt"))
    data = util.readfile_sync(vim.uv, xszd_file)
    if data then
      dict:load_xszd(data, xszd_file)
    end
  end

  do
    local kyu_file =
        vim.fs.joinpath(opts.dir, "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt")
    data = util.readfile_sync(vim.uv, kyu_file)
    if data then
      dict:load_kyu(data, kyu_file)
    end
  end

  do
    local chinadat_file = opts.chinadat and opts.chinadat or (vim.fs.joinpath(opts.dir, "chinadat.csv"))
    data = util.readfile_sync(vim.uv, chinadat_file)
    if data then
      dict:load_chinadat(data, chinadat_file)
    end
  end

  ---@type string[]
  do
    local list = {}
    local jisyo = opts.jisyo
    if type(jisyo) == "string" then
      table.insert(list, jisyo)
    elseif type(jisyo) == "table" then
      for _, j in ipairs(jisyo) do
        table.insert(list, j)
      end
    end
    if #list == 0 then
      table.insert(list, opts.dir .. "/SKK-JISYO.L")
      table.insert(list, opts.dir .. "/SKK-JISYO.china_taiwan")
    end

    for _, path in ipairs(list) do
      data = util.readfile_sync(vim.uv, path)
      if data then
        dict:load_skk(data, path)
      end
    end
  end

  if opts.user then
    data = util.readfile_sync(vim.uv, opts.user)
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
    -- print(vim.inspect(dict))
  end)()
end

return M
