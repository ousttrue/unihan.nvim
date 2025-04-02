local utf8 = require "utf8"
local util = require "unihan.util"

--- 読
---@class unihan.Reading
---@field pinyin string pinyin
---@field zhuyin string? 注音符号
---@field diao integer? 四声

--
-- 字形
--
-- 複数の音(読み)を内包しうる。各読みに意味が結び付く
---@class unihan.Glyph
---@field ch string
---@field annotation string?
---@field goma string? 四角号碼
---@field xszd XueShengSection[]? 學生字典
---@field readings unihan.Reading[] 読み
---@field yin Yin[] 反切と声調
---@field kana string[] よみかな
---@field flag "joyo" | nil
---@field indices string? 康煕字典
---@field ref string[]? 異字体
local Glyph = {}
Glyph.__index = Glyph

---@param ch string
---@return unihan.Glyph
function Glyph.new(ch)
  assert(ch)
  local self = setmetatable({
    ch = ch,
    yin = {},
    kana = {},
    readings = {},
  }, Glyph)
  return self
end

---@return string[]
function Glyph:hover()
  local cp = utf8.codepoint(self.ch)
  local lines = {}

  table.insert(lines, "# 読み")
  if #self.kana > 0 then
    -- table.insert(lines, util.join(self.kana, ","))
    table.insert(lines, self.kana[1])
  end
  for _, r in ipairs(self.readings) do
    table.insert(lines, r.zhuyin .. (r.diao and ("%d"):format(r.diao) or ""))
  end
  table.insert(lines, "")

  table.insert(lines, "# " .. self.ch)
  if self.ref then
    table.insert(lines, "参照 => " .. util.join(self.ref, ","))
  end
  if self.goma then
    table.insert(lines, ("UNICODE: U+%X, 四角号碼: %s"):format(cp, self.goma))
  end
  if self.annotation and #self.annotation > 0 then
    table.insert(lines, "備考: " .. self.annotation)
  end
  table.insert(lines, "")

  if self.xszd then
    table.insert(lines, "# 學生字典")
    for _, x in ipairs(self.xszd) do
      table.insert(lines, "## " .. x.header)
      for _, l in util.split, { x.body, "\n" } do
        table.insert(lines, l)
      end
    end
  end
  return lines
end

return Glyph
