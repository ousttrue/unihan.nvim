local MODULE_NAME = "unihan"

local cache = vim.fn.stdpath "cache"
assert(type(cache) == "string")

---@return string
local function ensure_make_cache_dir()
  local CACHE_DIR = vim.fs.joinpath(cache, MODULE_NAME)
  if not vim.uv.fs_stat(CACHE_DIR) then
    vim.notify_once("mkdir " .. CACHE_DIR, vim.log.levels.INFO, { title = "unihan" })
    vim.fn.mkdir(CACHE_DIR, "p")
  end
  return CACHE_DIR
end

---@class unihan.Opts
---@field skk_jisyo table path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan_dir string? path to dir. Extracted https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
---@field xszd string? path to xszd.txt from https://github.com/cjkvi/cjkvi-dict
---@field kangxi string? kx2ucs.txt from https://github.com/cjkvi/cjkvi-dict
---@field sbgy string? sbgy.xml from https://github.com/cjkvi/cjkvi-dict 宋本廣韻
---@field chinadat string? path to chinadat.csv from https://www.seiwatei.net/info/dnchina.htm
---@field kuankhiunn string? 有女同車《〈廣韻〉全字表》原表 path to Kuankhiunn0704-semicolon.txt from https://github.com/syimyuzya/guangyun0704
---@field user_dict string? path to user_dict.json
---@field kyu_file string? 旧字体.txt
---@field dir string? basedir

local M = {}

---@param opts table?
---@return unihan.Opts
function M.make_opts(opts)
  opts = opts or vim.tbl_extend("keep", opts, {})
  -- opts = vim.tb
  opts.dir = ensure_make_cache_dir()

  opts.xszd = opts.xszd or vim.fs.joinpath(opts.dir, "cjkvi-dict-master/xszd.txt")
  opts.kangxi = opts.xszd or vim.fs.joinpath(opts.dir, "cjkvi-dict-master/kx2ucs.txt")
  opts.sbgy = opts.xszd or vim.fs.joinpath(opts.dir, "cjkvi-dict-master/sbgy.xml")
  opts.kyu_file = opts.kyu_file
      or vim.fs.joinpath(opts.dir, "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt")
  opts.chinadat = opts.chinadat or vim.fs.joinpath(opts.dir, "chinadat.csv")

  ---@type string[]
  local list = {}
  local jisyo = opts.skk_jisyo
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
  opts.skk_jisyo = list

  opts.group = vim.api.nvim_create_augroup(MODULE_NAME, { clear = true })

  return opts
end

return M
