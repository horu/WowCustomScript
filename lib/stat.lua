
local cs = cs_common



-- unit resist
cs.ur = {}
cs.ur.Physical = 0
cs.ur.Fire = 2
cs.ur.Nature = 3
cs.ur.Frost = 4
cs.ur.Shadow = 5
cs.ur.Arcane = 6
cs.ur.get_total_resist = function(index)
  local _, total = UnitResistance(cs.u.player, index)
  return total
end



cs.stat = {}

local frame_config_left = { x=347, y=94, text_relative=cs.ui.r.RIGHT, mono=true }
local frame_config_right = { x=1150, y=94, mono=true }

local period = 0.2


---@class cs.stat.Frame
cs.stat.Frame = cs.class()

--region
---@param self cs.stat.Frame
function cs.stat.Frame.build(self)
  self.text_left = cs.ui.Text:build_from_config(frame_config_left)
  do
    -- Reset speed saved map size ratio
    local button_point = cs.ui.Point:create(0, 0, cs.ui.r.LEFT, self.text_left:get_native(), cs.ui.r.LEFT)
    self.button_left = cs.ui.Button:new(40, 15, button_point, nil, nil, function()
      cs.services.speed_checker:reset_speed()
    end)
  end

  self.text_right = cs.ui.Text:build_from_config(frame_config_right)
  do
    -- Reset analyzer stat
    local button_point = cs.ui.Point:create(0, 0, cs.ui.r.RIGHT, self.text_right:get_native(), cs.ui.r.RIGHT)
    self.button_right = cs.ui.Button:new(40, 15, button_point, nil, nil, function()
      cs.damage.analyzer:reset_events()
    end)
  end

  cs.event.loop(period, self, self._update)
end

function cs.stat.Frame:_update()
  self:_update_left()
  self:_update_right()
end

function cs.stat.Frame:_update_left()
  local speed = cs.services.speed_checker:get_speed()

  local fire_resist = cs.color.orange_1..cs.ur.get_total_resist(cs.ur.Fire)
  local frost_resist = cs.color.blue..cs.ur.get_total_resist(cs.ur.Frost)
  local shadow_resist = cs.color.purple..cs.ur.get_total_resist(cs.ur.Shadow)
  local armor = cs.ur.get_total_resist(cs.ur.Physical) / 1000

  -- TODO: remove it
  --local fire_damage = cs.pal.resist.analyzer:get_sum_damage(cs.damage.s.Fire)
  --local frost_damage = cs.pal.resist.analyzer:get_sum_damage(cs.damage.s.Frost)
  --local shadow_damage = cs.pal.resist.analyzer:get_sum_damage(cs.damage.s.Shadow)
  --local phy_damage = cs.pal.resist.analyzer:get_sum_damage(cs.damage.st.Physical)
  local fire_damage = 0
  local frost_damage = 0
  local shadow_damage = 0
  local phy_damage = 0

  local text = string.format("%1.2f %s(%4d) %s(%4d) %s(%4d) |r%1.1f(%4d)",
          speed or -1,
          fire_resist, fire_damage,
          frost_resist, frost_damage,
          shadow_resist, shadow_damage,
          armor, phy_damage
  )

  self.text_left:set_text(text)
end

function cs.stat.Frame:_update_right()
  ---@type cs.damage.Stat
  local damage_stat = cs.damage.analyzer:get_stat()
  local source = damage_stat.source_counter
  local absorb = damage_stat.absorb_counter
  local template = string.format("%s%s", string.rep("%s%4d ", 2), string.rep("%s%s ", 6))
  local text = string.format(template,
          cs.color.purple, source:get(cs.damage.st.Spell),
          cs.color.white, source:get(cs.damage.st.Physical),
          cs.color.red, absorb:get_rate_str(cs.damage.at.none),
          cs.color.yellow, absorb:get_rate_str(cs.damage.at.miss),
          cs.color.blue, absorb:get_rate_str(cs.damage.at.dodge),
          cs.color.green, absorb:get_rate_str(cs.damage.at.parry),
          cs.color.white, absorb:get_rate_str(cs.damage.at.block),
          cs.color.purple, absorb:get_rate_str(cs.damage.at.resist)
  )
  self.text_right:set_text(text)
end


cs.stat.init = function()
  cs.stat.frame = cs.stat.Frame:new()
end