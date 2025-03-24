local utf8 = require "utf8"

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

---@class unihan.Xiaoyun
---@field fanqie string
---@field ipa string
---@field onyomi string
---@field chars string[]
local Xiaoyun = {}
Xiaoyun.__index = Xiaoyun

---@param ipa string
---@param onyomi string
function Xiaoyun.new(ipa, onyomi)
  local self = setmetatable({
    ipa = ipa,
    onyomi = onyomi,
    chars = {},
  }, Xiaoyun)
  return self
end

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
    table.insert(lines, ("%s: %s"):format(xiao.chars[1], xiao.fanqie))
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
        assert(fanqie, w)
        x.fanqie = fanqie
      end
      table.insert(x.chars, pre and pre or w)
      j = j + 1
    end
    i = i + 1
  end
end

---@class unihan.Sbgy 宋本廣韻
---@field 平 unihan.Yun[]
---@field 上 unihan.Yun[]
---@field 去 unihan.Yun[]
---@field 入 unihan.Yun[]
local Sbgy = {}
Sbgy.__index = Sbgy

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

---@return unihan.Sbgy
function Sbgy.new()
  local self = setmetatable({
    ["平"] = {},
    ["上"] = {},
    ["去"] = {},
    ["入"] = {},
  }, Sbgy)

  return self
end

---@param data string
function Sbgy:load_sbgy(data)
  for title, v in data:gmatch "<volume[^>]+>%s*<volume_title>(.-)</volume_title>(.-)</volume>" do
    local volume = title
    ---@cast volume unihan.SbgyVolume
    self:load_sbgy_v(volume, v)
  end
end

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
  local name = volume_to_name(volume)
  table.insert(self[name], Yun.parse_entry(data, name))
end

---@param volume unihan.SbgyVolume
---@param i integer
---@param data string
function Sbgy:load_sbgy_rhyme(volume, i, data)
  local name = volume_to_name(volume)
  local yun = self[name][i]
  yun:parse_body(data)
end

---@param url string
---@return string[]
function Sbgy:render_lines(url)
  local root, child = url:match "^sbgy:/([^/]+)/([^/]+)"
  if root and child then
    local list = self[root]
    for _, yun in ipairs(list) do
      if yun.name == child then
        return yun:render_lines()
      end
    end

    return {
      ("/%s/%s: not found"):format(root, child),
    }
  else
    ---@type string[]
    local lines = {}

    local space = "                 "

    for i = 1, 60 do
      local yun = self["平"][i]
      lines[i] = ("|%02d|"):format(i) .. (yun and yun:md_link() or space)
    end
    for i = 1, 60 do
      local yun = self["上"][i]
      lines[i] = lines[i] .. "|" .. (yun and yun:md_link() or space)
    end
    for i = 1, 60 do
      local yun = self["去"][i]
      lines[i] = lines[i] .. "|" .. (yun and yun:md_link() or space)
    end
    for i = 1, 60 do
      local yun = self["入"][i]
      lines[i] = lines[i] .. "|" .. (yun and yun:md_link() or space) .. "|"
    end

    table.insert(lines, 1, "|  |[平聲](sbgy:/平) |[上聲](sbgy:/上) |[去聲](sbgy:/去) |[入聲](sbgy:/入) |")
    table.insert(lines, 2, "|--|-----------------|-----------------|-----------------|-----------------|")

    return lines
  end
end

return Sbgy
