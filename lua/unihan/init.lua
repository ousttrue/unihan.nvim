local UnihanDict = require "unihan.UnihanDict"
local util = require "unihan.util"

local UNIHAN_URL = "https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip"
local SKK_L_URL = "https://skk-dev.github.io/dict/SKK-JISYO.L.gz"
local SKK_china_taiwan_URL = "https://skk-dev.github.io/dict/SKK-JISYO.china_taiwan.gz"
local CHINADAT_URL = "https://www.seiwatei.net/info/chinadat.csv"
local CJKVI_DICT_URL = "https://github.com/cjkvi/cjkvi-dict/archive/refs/heads/master.zip"
local HANZI_CHARS_URL = "https://github.com/zispace/hanzi-chars/archive/refs/heads/main.zip"

---@class unihan.Module
---@field opts unihan.Opts?
---@field dict unihan.UnihanDict
local M = {}

function M.setup(opts)
  M.opts = require("unihan.opts").make_opts(opts)

  local request_map = {
    [vim.lsp.protocol.Methods.textDocument_hover] = function(params)
      return require("unihan").dict:lsp_hover(params)
    end,
    [vim.lsp.protocol.Methods.textDocument_completion] = function(params)
      return require("unihan").dict:lsp_completion(params)
    end,
  }

  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = opts.group,
    callback = function()
      require("unihan.LanguageServer").launch("/", request_map)
    end,
  })

  --
  -- BufReadCmd
  --
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "sbgy:*" },
    ---@param ev vim.api.keyset.create_autocmd.callback_args
    callback = function(ev)
      local o = M.dict.sbgy:resolve_url(ev.file)

      local lines
      if o then
        lines = o:render_lines()
      else
        lines = {
          ("%s not found"):format(ev.file),
        }
      end

      vim.api.nvim_set_option_value("modifiable", true, { buf = ev.buf })

      vim.api.nvim_buf_set_lines(ev.buf, -2, -1, true, lines)
      -- vim.api.nvim_buf_set_lines(buf, -2, -1, true, vim.split(body, "\n"))
      vim.api.nvim_set_option_value("modifiable", false, { buf = ev.buf })

      vim.keymap.set("n", "j", "gj", { buffer = ev.buf, noremap = true })
      vim.keymap.set("n", "k", "gk", { buffer = ev.buf, noremap = true })

      vim.api.nvim_set_current_buf(ev.buf)
      -- vim.cmd "norm! zM"
      -- local ufo = require "ufo"
      -- ufo.applyFolds(0, { 1, -1 })
      -- ufo.closeFoldsWith(1)
      vim.api.nvim_set_option_value("filetype", "markdown", {
        buf = ev.buf,
      })
    end,
  })
  vim.api.nvim_create_user_command("UnihanGuangyun", function()
    vim.cmd "edit sbgy:"
  end, {})

  --
  -- command
  --
  vim.api.nvim_create_user_command("UnihanLsLog", function()
    vim.cmd(string.format("edit %s", require("unihan.LanguageServer").get_log_path()))
  end, {})

  vim.api.nvim_create_user_command("UnihanReload", function()
    require("unihan").reload_dict()
  end, {})

  vim.api.nvim_create_user_command("UnihanDownload", function()
    require("unihan").download_all()
  end, {})

  M.load_dict()
end

function M.load_dict()
  require("unihan.work_util").async_load(M.opts, function(dict)
    M.dict = dict
    UnihanDict.resetmetatable(M.dict)
  end)
end

---@param url string
---@param downloaded string
---@param extracted string
---@param opts unihan.Opts
---@param encoding string?
local function download_if_not_exist(url, downloaded, extracted, opts, encoding)
  local dst_extracted = vim.fs.joinpath(opts.dir, extracted)
  if vim.uv.fs_stat(dst_extracted) then
    vim.notify_once("exist " .. dst_extracted, vim.log.levels.INFO, { title = "unihan" })
    return
  end

  local dst_archive = vim.fs.joinpath(opts.dir, downloaded)
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
      local gz_job = vim
          .system({ "C:/Program Files/Git/usr/bin/gzip.exe", "-dc", dst_archive }, { cwd = opts.dir })
          :wait()
      if encoding then
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout, encoding, "utf-8")
      else
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout)
      end
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "unihan" })
    else
      vim.system({ "tar", "xf", dst_archive }, { cwd = opts.dir }):wait()
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "unihan" })
    end
  end
end

function M.download_unihan()
  download_if_not_exist(UNIHAN_URL, "Unihan.zip", "Unihan_DictionaryIndices.txt", M.opts)
end

function M.download_skkdict()
  download_if_not_exist(SKK_L_URL, "SKK-JISYO.L.gz", "SKK-JISYO.L", M.opts, "euc-jp")
  download_if_not_exist(SKK_china_taiwan_URL, "SKK-JISYO.china_taiwan.gz", "SKK-JISYO.china_taiwan", M.opts, "euc-jp")
end

function M.download_chinadat()
  download_if_not_exist(CHINADAT_URL, "chinadat.csv", "chinadat.csv", M.opts)
end

function M.download_cjkvi_dict()
  download_if_not_exist(CJKVI_DICT_URL, "cjkvi-dict-master.zip", "cjkvi-dict-master/xszd.txt", M.opts)
end

function M.download_hanzi_chars()
  download_if_not_exist(
    HANZI_CHARS_URL,
    "hanzi-chars-main.zip",
    "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt",
    M.opts
  )
end

function M.download_all()
  M.download_unihan()
  M.download_skkdict()
  M.download_chinadat()
  M.download_cjkvi_dict()
  M.download_hanzi_chars()
  M.load_dict()
end

return M
