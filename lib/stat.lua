
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

local frame_config = { x=347, y=94, text_relative=cs.ui.r.RIGHT, mono=true }

local period = 0.2


---@class cs.stat.Frame
cs.stat.Frame = cs.class()

--region
---@param self cs.stat.Frame
function cs.stat.Frame.build(self)
  self.text = cs.ui.Text:build_from_config(frame_config)

    -- Reset speed saved map size ratio
  local button_point = cs.ui.Point.build(0, 0, cs.ui.r.BOTTOMLEFT, self.text.frame, cs.ui.r.BOTTOMLEFT)
  self.button = cs.create_simple_button(nil, nil, button_point, function()
    cs.services.speed_checker:reset_speed()
  end)

  cs.event.loop(period, self, self._update)
end

function cs.stat.Frame:_update()
  local speed = cs.services.speed_checker:get_speed()

  local fire_resist = cs.color.orange_1..cs.ur.get_total_resist(cs.ur.Fire)..cs.color.none
  local frost_resist = cs.color.blue..cs.ur.get_total_resist(cs.ur.Frost)..cs.color.none
  local shadow_resist = cs.color.purple..cs.ur.get_total_resist(cs.ur.Shadow)..cs.color.none
  local armor = cs.ur.get_total_resist(cs.ur.Physical) / 1000

  local text = string.format("%1.2f %s %s %s %1.1f",
          speed or -1, fire_resist, frost_resist, shadow_resist, armor)

  self.text:set_text(text)
end


cs.stat.init = function()
  cs.stat.frame = cs.stat.Frame:new()
end