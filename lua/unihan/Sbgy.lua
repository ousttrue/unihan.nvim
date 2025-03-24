---@alias guangyun.volume '廣韻上平聲卷第一'|'廣韻下平聲卷第二'|'廣韻上聲卷第三'|'廣韻去聲卷第四'|'廣韻入聲卷第五'

---@class unihan.Sbgy 宋本廣韻
local Sbgy = {}
Sbgy.__index = Sbgy

---@return unihan.Sbgy
function Sbgy.new()
  local self = setmetatable({
    --
  }, Sbgy)

  return self
end

---@param data string
function Sbgy:load_sbgy(data)
  for title, v in data:gmatch "<volume[^>]+>%s*<volume_title>(.-)</volume_title>(.-)</volume>" do
    self:load_sbgy_v(title, v)
  end
end

-- <catalog>
-- 	<rhythmic_entry>
-- 		<fanqie>德紅</fanqie>東第一<note>獨用</note>
-- 	</rhythmic_entry>
---@param volume guangyun.volume
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

---@param volume guangyun.volume
---@param i integer
---@param data string
function Sbgy:load_sbgy_entry(volume, i, data) end

---@param volume guangyun.volume
---@param i integer
---@param data string
function Sbgy:load_sbgy_rhyme(volume, i, data) end

return Sbgy
