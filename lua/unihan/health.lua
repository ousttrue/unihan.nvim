local M = {}

M.check = function()
  local unihan = require "unihan"

  vim.health.start "unihan report"
  -- make sure setup function parameters are ok
  local dict = unihan.dict
  if dict then
    vim.health.ok "Setup is correct"

    ---@param key string
    ---@param label string?
    local function check_dict_file(key, label)
      label = label and ("[" .. label .. "] ") or ""
      if dict[key] then
        vim.health.ok(("%s%s"):format(label, dict[key] or key))
      else
        vim.health.error(("%s%s"):format(label, key))
      end
    end
    check_dict_file "unihan_like_file"
    check_dict_file "unihan_readings_file"
    check_dict_file "unihan_variants_file"
    check_dict_file("sbgy_file", "宋本廣韻")
    check_dict_file("xszd_file", "學生字典")
    check_dict_file("kuankhiunn_file", "有女同車《〈廣韻〉全字表》原表")
    check_dict_file("chinadat_file", "支那漢")
    check_dict_file "kyu_file"
    check_dict_file("skk_L", "SKK辞書")

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
