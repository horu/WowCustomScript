local cs = cs_common
local pal = cs.pal


local school_timeout = 8
local school_phy = cs.damage.st.Physical

pal.resist = {}

-- analyzer current damage and detect max school damage
---@class pal.resist.Analyzer
pal.resist.Analyzer = cs.class()

function pal.resist.Analyzer:build()
  self.school_damage = {}
  self.school_damage[school_phy] = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Fire] = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Frost] = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Shadow] = cs.FixTable:new(school_timeout)

  --TODO: Remove it
  self.damage_sum_list = {}

  self.current_school = nil -- phy

  local filter = {}
  filter[cs.damage.p.target] = { cs.damage.u.player, cs.damage.u.party }
  cs.damage.parser:subscribe(filter, self, self._on_damage_detected)
end

function pal.resist.Analyzer:get_sum_damage(school)
  return self.damage_sum_list[school] or 0
end

-- nil - phy damage
function pal.resist.Analyzer:get_school()
  local school = self:_detect_target_cast()
  -- if target is casting then the school is must be detected now
  if school then
    return school
  end

  self:_calculate_school()

  return self.current_school
end

function pal.resist.Analyzer:_detect_target_cast()
  if not cs.check_target(cs.t.attackable) then
    return
  end

  local unit_cast = cs.get_cast_info(cs.u.target)
  if not unit_cast then
    return
  end

  local spell_school = unit_cast:get_school()
  if not spell_school then
    return
  end

  return spell_school
end

---@param event cs.damage.Event
function pal.resist.Analyzer:_on_damage_detected(event)
  if event.sourcetype == cs.damage.st.Physical then
    local max_hp = UnitHealthMax(cs.u.player)

    -- every hit phy damage is retr aura return 20 damage
    -- add value ~ 2 * retr aura damage
    self.school_damage[school_phy]:add(max_hp / 200)
  end

  local spell_school = event.school
  local school = self.school_damage[spell_school]
  if not school then
    return
  end

  school:add(event.value)
end

function pal.resist.Analyzer:_calculate_school()
  local max_damage = 1
  for school, damage in pairs(self.school_damage) do
    local sum = damage:get_sum()
    self.damage_sum_list[school] = sum
    if sum > max_damage then
      max_damage = sum
      self.current_school = school ~= school_phy and school
    end
  end
end


pal.resist.init = function()
  ---@type pal.resist.Analyzer
  pal.resist.analyzer = pal.resist.Analyzer:new()
end