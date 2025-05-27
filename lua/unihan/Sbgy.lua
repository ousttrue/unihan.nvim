local utf8 = require "utf8"
local util = require "unihan.util"

---@alias unihan.SbgyVolume '廣韻上平聲卷第一'|'廣韻下平聲卷第二'|'廣韻上聲卷第三'|'廣韻去聲卷第四'|'廣韻入聲卷第五'

---@param volume unihan.SbgyVolume
---@return '平'|'上'|'去'|'入'|nil
---@return '上'|'下'|nil
local function volume_to_name(volume)
  if volume == "廣韻上平聲卷第一" then
    return "平", "上"
  elseif volume == "廣韻下平聲卷第二" then
    return "平", "下"
  elseif volume == "廣韻上聲卷第三" then
    return "上"
  elseif volume == "廣韻去聲卷第四" then
    return "去"
  elseif volume == "廣韻入聲卷第五" then
    return "入"
  else
    assert(false)
  end
end

local Xiaoyun = require "unihan.XiaoYun"

--
-- 韻目
--
---@class unihan.Yun
---@field name string
---@field parent string
---@field xiaoyun unihan.Xiaoyun[]
local Yun = {}
Yun.__index = Yun

function Yun.setmetatable(self)
  setmetatable(self, Yun)
  for _, x in ipairs(self.xiaoyun) do
    setmetatable(x, Xiaoyun)
  end
end

---@param name string
---@param parent string
---@return unihan.Yun
function Yun.new(name, parent)
  for _, code in utf8.codes(name) do
    -- 一文字目
    local self = setmetatable({
      name = code,
      parent = parent,
      xiaoyun = {},
    }, Yun)
    return self
  end
end

-- <fanqie>德紅</fanqie>東第一<note>獨用</note>
---@return unihan.Yun
function Yun.parse_entry(data, parent)
  local fanqie, remain = data:match "<fanqie>(.-)</fanqie>(.*)"
  assert(fanqie, data)
  local name, note = remain:match "(.-)<note>(.-)</note>"
  if name and note then
    return Yun.new(name, parent)
  else
    return Yun.new(remain, parent)
  end
end

function Yun:md_link()
  return ("[%s](sbgy:/%s/%s)"):format(self.name, self.parent, self.name)
end

---@return string[]
function Yun:render_lines()
  local lines = {}

  for _, xiao in ipairs(self.xiaoyun) do
    table.insert(lines, ("[%s](sbgy:/x/%s): %s"):format(xiao.chars[1], xiao.chars[1], xiao.fanqie))
  end

  return lines
end

-- ipa="tuŋ˥˩" onyomi="トウ"
---@param src string
---@return string
---@return string
local function parse_attr(src)
  local map = {}
  for k, v in src:gmatch '(%w-)="([^"]*)"' do
    map[k] = v
  end
  return map["ipa"], map["onyomi"]
end

function Yun:parse_body(data)
  local i = 1
  for attrs, body in data:gmatch "<voice_part ([^>]-)>(.-)</voice_part>" do
    local ipa, onyomi = parse_attr(attrs)
    local x = Xiaoyun.new(ipa, onyomi)
    table.insert(self.xiaoyun, x)
    local j = 1
    for w in body:gmatch "<word_head [^>]->(.-)</word_head>" do
      local pre, note = w:match "(.-)<note>(.*)</note>"
      if j == 1 then
        local fanqie = note:match "<fanqie>(.-)</fanqie>"
        assert(#fanqie > 0, w)
        x.fanqie = fanqie
      end
      table.insert(x.chars, pre and pre or w)
      j = j + 1
    end
    i = i + 1
  end
end

---
--- 宋本廣韻
---
---@class unihan.Sbgy
---@field sbgy_file string? sgby.xml
---@field kuankhiunn_file string?
---@field 平 unihan.Yun[]
---@field 上 unihan.Yun[]
---@field 去 unihan.Yun[]
---@field 入 unihan.Yun[]
---@field xiaoyun_map table<string, unihan.Xiaoyun[]>
local Sbgy = {}
Sbgy.__index = Sbgy

---@return unihan.Sbgy
function Sbgy.new()
  local self = setmetatable({
    ["平"] = {},
    ["上"] = {},
    ["去"] = {},
    ["入"] = {},
    xiaoyun_map = {},
  }, Sbgy)

  return self
end

function Sbgy.setmetatable(self)
  setmetatable(self, Sbgy)
  for _, y in ipairs(self["平"]) do
    Yun.setmetatable(y)
  end
  for _, y in ipairs(self["上"]) do
    Yun.setmetatable(y)
  end
  for _, y in ipairs(self["去"]) do
    Yun.setmetatable(y)
  end
  for _, y in ipairs(self["入"]) do
    Yun.setmetatable(y)
  end
end

-- <book title="校正宋本廣韻">
--   <preface></preface>
--   <preface></preface>
--   <old_preface></old_preface>
--   <volume></volume> 上平
--   <volume></volume> 下平
--   <volume></volume> 上
--   <volume></volume> 去
--   <volume></volume> 入
--   <appendix></appendix>
--   <postscript></postscript>
-- </book>
--
---@param data string
---@param sbgy_file string?
function Sbgy:load_sbgy(data, sbgy_file)
  self.sbgy_file = sbgy_file
  -- remove newline
  data = data:gsub("%s+", " ")

  for title, v in data:gmatch "<volume[^>]+>%s*<volume_title>(.-)</volume_title>(.-)</volume>" do
    local volume = title
    ---@cast volume unihan.SbgyVolume
    self:load_sbgy_v(volume, v)
  end

  -- patch
  -- local function check(key)
  --   for i, y in ipairs(self[key]) do
  --     if #y.xiaoyun > 0 and y.name ~= y.xiaoyun[1].chars[1] then
  --       print(key, i, y.name, "!=", y.xiaoyun[1].chars[1])
  --     end
  --   end
  -- end
  -- check "平"
  -- check "上"
  -- check "去"
  -- check "入"
  -- 平 21 欽 != 欣
  -- 平 23 魂 != 䰟
  -- 平 27 删 != 𠜂
  -- 平 46  != 尤
  self["平"][46].name = "尤"
  -- 上 26 產 != 産
  -- 上 47 寢 != 寑
  -- 去 5 ？ != 寘
  -- 去 50 候 != 𠋫
  -- 入 11 𣳚 != 沒
  -- 入 12 ？ != 曷
  -- 入 29 ？ != 葉
  -- 入 30 帖 != 怗
end

-- <volume id="v1">
--   <volume_title>廣韻上平聲卷第一</volume_title>
--   <catalog>
--     <rhythmic_entry><fanqie>德紅</fanqie>東第一<note>獨用</note></rhythmic_entry>
--   </catalog>
--   <rhyme id="sp01">
--     <rhyme_num>一</rhyme_num>
--     <voice_part ipa="tuŋ˥˩" onyomi="トウ">
--       <word_head id="w107b0601">東</word_head>
--     </voice_part>
--     <voice_part ipa="dʰuŋ˩" onyomi="トウ">
--     </voice_part>
--     ...
--   </rhyme>
--   <rhyme id="sp02"></rhyme>
--   <rhyme id="sp03"></rhyme>
--   ...
--   <end_volume>廣韻上平聲卷第一</end_volume>
--   <accession></accession>
-- </volume>
---@param volume unihan.SbgyVolume
---@param data string
function Sbgy:load_sbgy_v(volume, data)
  -- print(volume)

  local i = 1
  for entry in data:gmatch "<rhythmic_entry>%s*(%S+)%s*</rhythmic_entry>" do
    self:load_sbgy_entry(volume, i, entry)
    i = i + 1
  end
  i = 1
  for rhyme in data:gmatch "<rhyme[^>]+>(.-)</rhyme>" do
    self:load_sbgy_rhyme(volume, i, rhyme)
    i = i + 1
  end
end

---@param volume unihan.SbgyVolume
---@param i integer
---@param data string
function Sbgy:load_sbgy_entry(volume, i, data)
  local name, _ = volume_to_name(volume)
  table.insert(self[name], Yun.parse_entry(data, name))
end

---@param volume unihan.SbgyVolume
---@param i integer
---@param data string
function Sbgy:load_sbgy_rhyme(volume, i, data)
  local name, sub = volume_to_name(volume)
  if sub == "下" then
    i = i + 28
  end
  ---@type unihan.Yun
  local yun = self[name][i]
  yun:parse_body(data)

  for _, xiao in ipairs(yun.xiaoyun) do
    local ch = xiao.chars[1]
    local list = self.xiaoyun_map[ch]
    if not list then
      list = {}
      self.xiaoyun_map[ch] = list
    end
    local found = 0
    for _, x in ipairs(list) do
      if x == xiao then
        found = found + 1
      end
    end
    if found == 0 then
      table.insert(list, xiao)
    end
  end
end

---@param line string
---@return unihan.Xiaoyun?
local function parse(line)
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
    parent = cols[12],
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

---@param vol integer
---@param yun integer
---@param xiao integer
---@return unihan.Xiaoyun?
function Sbgy:get_xiaoyun(vol, yun, xiao)
  local keys = { "平", "平", "上", "去", "入" }
  ---@type unihan.Yun[]
  local list = self[keys[vol]]
  if vol == 2 then
    -- 下平
    yun = yun + 28
  end
  if list then
    local y = list[yun]
    if y then
      return y.xiaoyun[xiao]
    else
      -- print(vol, yun, xiao, #list)
    end
  else
    print(vol, yun, xiao)
  end
end

---@param data string
---@param kuankhiunn_file string?
function Sbgy:load_kuankhiunn(data, kuankhiunn_file)
  self.kuankhiunn_file = kuankhiunn_file

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
  for line in string.gmatch(data, "(.-)\n") do
    local cols = util.splited(line, ";")
    if #cols > 5 then
      local vol, yun = cols[7]:match "^(%d+)%.(%d+)"
      -- print(line, cols[8])
      local x = self:get_xiaoyun(tonumber(vol), tonumber(yun), tonumber(cols[8]))
      if x then
        x["聲紐"] = cols[9]
        x["開合"] = cols[10]
        x["等"] = cols[11]
        x["聲調"] = cols[13]
        x["roma"] = cols[15]
        x.parent = cols[12]
        x.fanqie = cols[3]

        for _, codepoint in utf8.codes(cols[4]) do
          local map_list = self.xiaoyun_map[codepoint]
          if not map_list then
            map_list = {}
            self.xiaoyun_map[codepoint] = map_list
          end
          local found = 0
          for _, z in ipairs(map_list) do
            if z == x then
              found = found + 1
            end
          end
          if found == 0 then
            table.insert(map_list, x)
          end
        end
      end
      -- break
    end
  end
end

---@param path string
---@return '平'|'上'|'去'|'入'|'x'|nil
---@return string? 韻目
---@return string? 小韻
local function parse_path(path)
  local root
  local yun_name
  local xiao_name

  local pattern = "^/([^/]*)(.*)$"
  local m, remain = path:match(pattern)
  if m then
    root = m
    m, remain = remain:match(pattern)
    if m then
      yun_name = m
      m, remain = remain:match(pattern)
      if m then
        xiao_name = m
      end
    end
  end

  return root, yun_name, xiao_name
end

---@erturn Sbgy|unihan.Yun|unihan.Xiaoyun|nil
function Sbgy:resolve_url(url)
  if not url:find "^sbgy:" then
    return
  end

  -- sbgy:/平/東
  local root, yun_name, xiao_name = parse_path(url:sub(6))
  if not root then
    return self
  end

  if root == "x" then
    -- 小韻
    for _, s in ipairs { "平", "上", "去", "入" } do
      for _, y in ipairs(self[s]) do
        for _, z in ipairs(y.xiaoyun) do
          if z.chars[1] == yun_name then
            return z
          end
        end
      end
    end
  end

  -- 四声
  local list = self[root]
  if not list then
    return
  end
  if not yun_name then
    return self
  end

  ---@type unihan.Yun?
  local yun
  for _, y in ipairs(list) do
    if y.name == yun_name then
      -- 韻目
      yun = y
      break
    end
  end
  if not yun then
    return nil
  end
  if not xiao_name then
    return yun
  end

  ---@type unihan.Xiaoyun?
  local xiaoyun
  for _, x in ipairs(yun.xiaoyun) do
    if x.chars[1] == xiao_name then
      xiaoyun = x
      break
    end
  end
  if xiaoyun then
    return nil
  end

  return xiaoyun
end

---@return string[]
function Sbgy:render_lines(u)
  -- |  |[平聲](sbgy:/平)   |[上聲](sbgy:/上)   |[去聲](sbgy:/去)   |[入聲](sbgy:/入)   |
  -- |--|-------------------|-------------------|-------------------|-------------------|
  local yun_table = {
    -- ou
    { "/平/東", "/上/董", "/去/送", "/入/屋" }, --01
    { "/平/冬", "/上/腫", "/去/宋", "/入/沃" }, --02
    { "/平/鍾", nil, "/去/用", "/入/燭" }, --03
    { "/平/江", "/上/講", "/去/絳", "/入/覺" }, --04
    -- i
    { "/平/支", "/上/紙", "/去/寘" }, -- 05
    { "/平/脂", "/上/旨", "/去/至" }, -- 06
    { "/平/之", "/上/止", "/去/志" }, -- 07
    { "/平/微", "/上/尾", "/去/未" }, -- 08
    -- u,o
    { "/平/魚", "/上/語", "/去/御" }, -- 09
    { "/平/虞", "/上/麌", "/去/遇" }, -- 10
    { "/平/模", "/上/姥", "/去/暮" }, -- 11
    -- ei
    { "/平/齊", "/上/薺", "/去/霽" }, -- 12
    { nil, nil, "/去/祭" }, -- 13
    { nil, nil, "/去/泰" }, -- 14
    -- ai
    { "/平/佳", "/上/蟹", "/去/卦" }, -- 15
    { "/平/皆", "/上/駭", "/去/怪" }, -- 16
    { nil, nil, "/去/夬" }, -- 17
    { "/平/灰", "/上/賄", "/去/隊" }, -- 18
    { "/平/咍", "/上/海", "/去/代" }, -- 19
    { nil, nil, "/去/廢" }, -- 20
    -- in, it
    { "/平/眞", "/上/軫", "/去/震", "/入/質" }, -- 21
    { "/平/諄", "/上/準", "/去/稕", "/入/術" }, -- 22
    { "/平/臻", nil, nil, "/入/櫛" }, -- 23
    { "/平/文", "/上/吻", "/去/問", "/入/物" }, -- 24
    { "/平/欽", "/上/隱", "/去/焮", "/入/迄" }, -- 25
    { "/平/元", "/上/阮", "/去/願", "/入/月" }, -- 26
    { "/平/魂", "/上/混", "/去/慁", "/入/𣳚" }, -- 27
    { "/平/痕", "/上/很", "/去/恨" }, -- 28
    { "/平/寒", "/上/旱", "/去/翰", "/入/？" }, -- 29
    { "/平/𢘆", "/上/緩", "/去/換", "/入/末" }, -- 30
    { "/平/删", "/上/潸", "/去/諫", "/入/黠" }, -- 31
    { "/平/山", "/上/產", "/去/襉", "/入/鎋" }, -- 32
    { "/平/先", "/上/銑", "/去/霰", "/入/屑" }, -- 33
    { "/平/仙", "/上/獮", "/去/線", "/入/薛" }, -- 34
    -- eu
    { "/平/蕭", "/上/篠", "/去/嘯" }, -- 35
    { "/平/宵", "/上/小", "/去/𥬇" }, -- 36
    { "/平/肴", "/上/巧", "/去/效" }, -- 37
    { "/平/豪", "/上/晧", "/去/号" }, -- 38
    -- a
    { "/平/歌", "/上/哿", "/去/箇" }, -- 39
    { "/平/戈", "/上/果", "/去/過" }, -- 40
    { "/平/麻", "/上/馬", "/去/禡" }, -- 41
    -- au
    { "/平/陽", "/上/養", "/去/漾", "/入/藥" }, -- 42
    { "/平/唐", "/上/蕩", "/去/宕", "/入/鐸" }, -- 43
    { "/平/庚", "/上/梗", "/去/映", "/入/陌" }, -- 44
    { "/平/耕", "/上/耿", "/去/諍", "/入/麥" }, -- 45
    -- ei
    { "/平/淸", "/上/靜", "/去/勁", "/入/昔" }, -- 46
    { "/平/靑", "/上/迥", "/去/徑", "/入/錫" }, -- 47
    -- ou
    { "/平/蒸", "/上/拯", "/去/證", "/入/職" }, -- 48
    { "/平/登", "/上/等", "/去/嶝", "/入/德" }, -- 49
    -- iu
    { "/平/尤", "/上/有", "/去/宥" }, -- 50
    { "/平/侯", "/上/厚", "/去/候" }, -- 51
    { "/平/幽", "/上/黝", "/去/幼" }, -- 52
    -- im
    { "/平/侵", "/上/寢", "/去/沁", "/入/緝" }, -- 53
    -- am
    { "/平/覃", "/上/感", "/去/勘", "/入/合" }, -- 54
    { "/平/談", "/上/敢", "/去/闞", "/入/盍" }, -- 55
    -- em
    { "/平/鹽", "/上/琰", "/去/豔", "/入/？" }, -- 56
    { "/平/添", "/上/忝", "/入/帖" }, -- 57
    { "/平/嚴", "/上/檻", "/入/業" }, -- 58
    -- am
    { "/平/咸", "/上/儼", "/入/洽" }, -- 59
    { "/平/銜", "/上/豏", "/入/狎" }, -- 60
    { "/平/凡", "/上/范", "/入/乏" }, -- 61
  }

  local sbgy_file = self.sbgy_file
  if sbgy_file then
    table.insert(lines, 1, ("[宋本廣韻](%s)"):format(sbgy_file))
    table.insert(lines, 2, "")
  end

  -- return lines

  return {}
end

---@param glyph unihan.Glyph
---@return unihan.Xiaoyun[]
function Sbgy:xiaoyun_from_glyph(glyph)
  local list = {}
  local xiaoyun = self.xiaoyun_map[glyph.ch]
  if xiaoyun then
    for _, x in ipairs(xiaoyun) do
      table.insert(list, x)
    end
  end
  return list
end

return Sbgy
