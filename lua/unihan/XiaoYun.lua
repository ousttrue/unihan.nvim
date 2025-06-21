local util = require "unihan.util"
local utf8 = require "utf8"

---小韻
---@class unihan.Xiaoyun
---@field no integer 小韻番号 1-3874 https://gijodai.jp/library/file/kiyo2006/SUMIYA.pdf
---@field fanqie string
---@field name string
---@field parent string
---@field roma string
---@field 聲調 string
---@field chars string[]
---@field 聲紐 string
---@field 開合 string
---@field 等 string
---@field ipa string
---@field onyomi string
local Xiaoyun = {}
Xiaoyun.__index = Xiaoyun

---@param ipa string
---@param onyomi string
function Xiaoyun.new(ipa, onyomi)
  local self = setmetatable({
    ipa = ipa,
    onyomi = onyomi,
    chars = {},
    parent = '',
  }, Xiaoyun)
  return self
end

-- 字段(fields)由「;」分隔，内容由左至右依次爲
-- 1、舊版(unicode3.1字符集第一版)小韻總序號。缺錄:丑戾切、no=2381，烏懈切、no=2455，他德切、no=3728，盧合、no=3784四小韻。
-- 2、刊正小韻總序號
-- 3、反切
-- 4、小韻内辭目（headwords）
-- 5、小韻所收辭目數
-- 6、校驗表記
-- 7、韻目。阿拉伯數碼「X.XX」，小數點前一位爲卷號，小數點後兩位爲韻目。如「4.11暮」意爲「第四卷去聲、十一暮韻」。
-- 8、小韻在韻中的序號。如「『德紅切』『東』爲『東』韻第一小韻，『薄紅切』『蓬』爲『東』韻第三十一小韻。」古書向無頁碼，兼且版本紛紜卷帙雜沓難於取捨，故此僅錄標目序號不記頁碼。
-- 9、聲紐
-- 10、呼（開合口）
-- 11、等
-- 12、韻部（四聲劃一）
-- 13、聲調
-- 14、Polyhedron擬羅馬字
-- 15、有女同車擬羅馬字
-- 16、舊版備註
-- 17、本次復校備註
-- 18、特殊小韻韻目歸屬說明
-- 19、見於廣韻辭條中的辭目重文、取自集韻的增補和異體字、等價異形字、備考新字等
-- 20、unicode3.1未收字的準IDS（Ideographic Desciption Characters）描述：H=⿰、Z=⿱、P=⿸、E=⿳、V=某字unicode缺載之變體
-- 1;1;德紅;東菄鶇䍶𠍀倲𩜍𢘐涷蝀凍鯟𢔅崠埬𧓕䰤;17;.;1.01東;1;端;開;一;東;平;tung;tung;;;;;
-- 3674;3676;都歷;的適嫡甋靮鏑馰滴肑弔芍蹢䶂玓樀𪄱𦉹𥕐𥐝扚𣂉啇魡㣿𨑩杓;26;.;5.23錫;5;端;開;四;青;入;tek;tek;;;;;
---@param line string
---@return unihan.Xiaoyun?
function Xiaoyun.parse(line)
  local cols = util.splited(line, ";")
  if #cols <= 5 then
    return
  end

  local no = tonumber(cols[2])

  local name = cols[7]:match "^%d+%.%d+(.*)$"
  local shengniu = cols[9]
  for _, code in utf8.codes(shengniu) do
    shengniu = code
    break
  end

  local fanqie = cols[3]:match "[^%?]+"

  local xiaoyun = setmetatable({
    no = no,
    fanqie = fanqie,
    name = name,
    ["聲紐"] = shengniu,
    ["開合"] = cols[10],
    ["等"] = cols[11],
    parent = cols[7],
    ["聲調"] = cols[13],
    roma = cols[14],
    chars = {},
  }, Xiaoyun)
  for _, ch in utf8.codes(cols[4]) do
    table.insert(xiaoyun.chars, ch)
  end
  for _, ch in utf8.codes(cols[19]) do
    table.insert(xiaoyun.chars, ch)
  end
  assert(#xiaoyun.chars, cols[5])
  return xiaoyun
end

function Xiaoyun:__tostring()
  return ("%s切%s聲 %s%s%s%s (%s) %s"):format(
    self.fanqie,
    self["聲調"],
    self['聲紐'],
    self.parent,
    self["開合"],
    self["等"],
    self.roma,
    util.join(self.chars)
  )
end

---半切上字
---@return string
function Xiaoyun:fanqie_hi()
  for _, code in utf8.codes(self.fanqie) do
    return code
  end
end

function Xiaoyun:render_lines()
  -- x["聲紐"] = xiaoyun["聲紐"]
  -- x["開合"] = xiaoyun["開合"]
  -- x["等"] = xiaoyun["等"]
  -- x["聲調"] = xiaoyun["聲調"]
  -- x["roma"] = xiaoyun["roma"]
  local lines = {}
  table.insert(lines, self.chars[1])
  table.insert(lines, ("%s%s"):format(self.fanqie, self["聲調"]))
  table.insert(lines, ("%s"):format(self["聲紐"]))
  table.insert(lines, ("%s等%s"):format(self["等"], self["開合"]))
  table.insert(lines, self.ipa)
  table.insert(lines, self.onyomi)
  return lines
end

return Xiaoyun
