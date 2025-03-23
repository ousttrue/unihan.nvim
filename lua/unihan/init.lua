local UnihanDict = require "unihan.UnihanDict"
local util = require "unihan.util"

local MODULE_NAME = "unihan"

local UNIHAN_URL = "https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip"
local SKK_L_URL = "https://skk-dev.github.io/dict/SKK-JISYO.L.gz"
local SKK_china_taiwan_URL = "https://skk-dev.github.io/dict/SKK-JISYO.china_taiwan.gz"
local CHINADAT_URL = "https://www.seiwatei.net/info/chinadat.csv"
local CJKVI_DICT_URL = "https://github.com/cjkvi/cjkvi-dict/archive/refs/heads/master.zip"
local HANZI_CHARS_URL = "https://github.com/zispace/hanzi-chars/archive/refs/heads/main.zip"

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

---@class unihan.Module
---@field opts unihan.Opts
---@field dict unihan.UnihanDict
local M = {}

function M.setup(opts)
  M.opts = opts

  local group = vim.api.nvim_create_augroup(MODULE_NAME, { clear = true })

  local request_map = {
    [vim.lsp.protocol.Methods.textDocument_hover] = function(params)
      return require("unihan").dict:lsp_hover(params)
    end,
    [vim.lsp.protocol.Methods.textDocument_completion] = function(params)
      return require("unihan").dict:lsp_completion(params)
    end,
  }
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = group,
    callback = function()
      require("unihan.LanguageServer").launch("/", request_map)
    end,
  })

  --
  -- command
  --
  vim.api.nvim_create_user_command("UnihanLsLog", function()
    vim.cmd(string.format("edit %s", require("unihan.LanguageServer").get_log_path()))
  end, {})

  vim.api.nvim_create_user_command("UnihanReload", function()
    require("unihan").reload_dict()
  end, {})

  vim.api.nvim_create_user_command("UnihanUnihanDownload", function()
    require("unihan").download_unihan()
  end, {})

  vim.api.nvim_create_user_command("UnihanSkkDictDownload", function()
    require("unihan").download_skkdict()
  end, {})

  vim.api.nvim_create_user_command("UnihanChinadatDownload", function()
    require("unihan").download_chinadat()
  end, {})

  vim.api.nvim_create_user_command("UnihanCjkviDictDownload", function()
    require("unihan").download_cjkvi_dict()
  end, {})

  vim.api.nvim_create_user_command("UnihanHanziCharsDownload", function()
    require("unihan").download_hanzi_chars()
  end, {})

  M.load_dict()
end

function M.load_dict()
  M.opts.dir = ensure_make_cache_dir()

  require("unihan.work_util").async_load(M.opts, function(dict)
    M.dict = dict
    UnihanDict.resetmetatable(M.dict)
  end)
end

---@param url string
---@param dir string
---@param downloaded string
---@param extracted string
local function download_if_not_exist(url, dir, downloaded, extracted, opts)
  local dst_extracted = vim.fs.joinpath(dir, extracted)
  if vim.uv.fs_stat(dst_extracted) then
    vim.notify_once("exist " .. dst_extracted, vim.log.levels.INFO, { title = "unihan" })
    return
  end

  local dst_archive = vim.fs.joinpath(dir, downloaded)
  if not vim.uv.fs_stat(dst_archive) then
    -- download
    vim.notify_once("download " .. url, vim.log.levels.INFO, { title = "unihan" })

    local dl_job = vim.system({ "curl", "-L", url }, { text = false }):wait()
    assert(dl_job.stdout)
    vim.notify_once(("write %dbytes"):format(#dl_job.stdout), vim.log.levels.INFO, { title = "unihan" })
    util.writefile_sync(vim.uv, dst_archive, dl_job.stdout)
  end

  -- extract
  if downloaded == extracted then
    -- skip
  else
    vim.notify_once("extact " .. dst_extracted, vim.log.levels.INFO, { title = "unihan" })
    if not downloaded:match "%.tar%.gz$" and downloaded:match "%.gz$" then
      local gz_job = vim.system({ "C:/Program Files/Git/usr/bin/gzip.exe", "-dc", dst_archive }, { cwd = dir }):wait()
      if opts.encoding then
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout, opts.encoding, "utf-8")
      else
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout)
      end
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "unihan" })
    else
      vim.system({ "tar", "xf", dst_archive }, { cwd = dir }):wait()
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "unihan" })
    end
  end
end

function M.download_unihan()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(UNIHAN_URL, dir, "Unihan.zip", "Unihan_DictionaryIndices.txt")
end

function M.download_skkdict()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(
  --
    SKK_L_URL,
    dir,
    "SKK-JISYO.L.gz",
    "SKK-JISYO.L",
    { encoding = "euc-jp" }
  )
  download_if_not_exist(
    SKK_china_taiwan_URL,
    dir,
    "SKK-JISYO.china_taiwan.gz",
    "SKK-JISYO.china_taiwan",
    { encoding = "euc-jp" }
  )
end

function M.download_chinadat()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(CHINADAT_URL, dir, "chinadat.csv", "chinadat.csv", {})
end

function M.download_cjkvi_dict()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(CJKVI_DICT_URL, dir, "cjkvi-dict-master.zip", "cjkvi-dict-master/xszd.txt", {})
end

function M.download_hanzi_chars()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(
    HANZI_CHARS_URL,
    dir,
    "hanzi-chars-main.zip",
    "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt",
    {}
  )
end

return M
