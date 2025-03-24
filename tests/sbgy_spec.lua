local Sbgy = require "unihan.Sbgy"
local util = require "unihan.util"
local uv = require "luv"

describe("宋本廣韻", function()
  local sbgy = Sbgy.new()

  setup(function()
    local path = os.getenv "GHQ_ROOT" .. "/github.com/cjkvi/cjkvi-dict/sbgy.xml"
    local data = util.readfile_sync(uv, path)
    assert(data)
    sbgy:load_sbgy(data)
  end)

  it("Sbgy", function()
    assert.are_equal(28 + 29, #sbgy["平"])
    assert.are_equal(55, #sbgy["上"])
    assert.are_equal(60, #sbgy["去"])
    assert.are_equal(34, #sbgy["入"])
    -- 206
  end)

  it("render", function()
    sbgy:render_lines "sbgy:"
  end)

  describe("平", function()
    ---@type unihan.Yun[]
    local hei

    setup(function()
      hei = sbgy["平"]
    end)

    it("東第一", function()
      local yun = hei[1]
      assert.are_equal("東第一", yun.name)
      assert.are_equal(57, #yun.xiaoyun)
      local x = yun.xiaoyun[1]
      assert.are_equal("德紅切", x.fanqie)
      assert.are_equal("トウ", x.onyomi)
      assert.are_equal(17, #x.chars)
      assert.are_equal("東", x.chars[1])
      assert.are_equal("菄", x.chars[2])
      assert.are_equal("鶇", x.chars[3])
      assert.are_equal("䰤", x.chars[17])
    end)

    it("凡第二十九", function()
      assert.are_equal("凡第二十九", hei[#hei].name)
    end)
  end)

  it("上", function()
    local hei = sbgy["上"]
    assert.are_equal("董第一", hei[1].name)
    assert.are_equal("范第五十五", hei[#hei].name)
  end)

  it("去", function()
    local hei = sbgy["去"]
    assert.are_equal("送第一", hei[1].name)
    assert.are_equal("梵第六十", hei[#hei].name)
  end)

  it("入", function()
    local hei = sbgy["入"]
    assert.are_equal("屋第一", hei[1].name)
    assert.are_equal("乏第三十四", hei[#hei].name)
  end)
end)
