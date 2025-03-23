local M = {}

M.check = function()
  local unihan = require "unihan"

  vim.health.start "unihan report"
  -- make sure setup function parameters are ok
  local dict = unihan.dict
  if dict then
    vim.health.ok "Setup is correct"

    local function check_dict_file(key)
      if dict[key] then
        vim.health.ok(dict[key])
      else
        vim.health.error(key)
      end
    end
    check_dict_file "unihan_like_file"
    check_dict_file "unihan_reading_file"
    check_dict_file "unihan_variants_file"
    check_dict_file "guangyun_file"
    check_dict_file "chinadat_file"
    check_dict_file "kyu_file"
    check_dict_file "xszd_file"
    check_dict_file "skk_L"

    local n = 0
    for k, v in pairs(dict.map) do
      n = n + 1
    end
    vim.health.info(("%d chars"):format(n))
  else
    vim.health.error "Setup is incorrect"
  end
  -- do some more checking
  -- ...
end

return M
