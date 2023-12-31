local cs = cs_common
local pal = cs.pal


local school_timeout = 8
-- when sum school damage for last %school_timeout seconds more then pick this school even phy damage more
local spell_critical_damage_ratio = 0.07
local retr_aura_ratio = 0.005

pal.resist = {}

-- analyzer current damage and detect max school damage
---@class pal.resist.Analyzer
pal.resist.Analyzer = cs.class()

function pal.resist.Analyzer:build()
  self.school_damage = {}
  self.school_damage_phy = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Fire] = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Frost] = cs.FixTable:new(school_timeout)
  self.school_damage[cs.damage.s.Shadow] = cs.FixTable:new(school_timeout)

  --TODO: Remove it
  self.damage_sum_list = {}

  self.current_school = nil -- phy

  local filter = {}
  filter[cs.damage.p.target] = { cs.damage.u.player, cs.damage.u.party }
  filter[cs.damage.p.datatype] = cs.damage.dt.damage
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
    self.school_damage_phy:add(retr_aura_ratio * max_hp)
  end

  local spell_school = event.school
  local school = self.school_damage[spell_school]
  if not school then
    return
  end

  school:add(event.value + event.resisted)
end

function pal.resist.Analyzer:_calculate_school()
  local max_damage = 1
  for school, damage in pairs(self.school_damage) do
    local sum = damage:get_sum()
    self.damage_sum_list[school] = sum
    if sum > max_damage then
      max_damage = sum
      self.current_school = school
    end
  end

  local phy_sum = self.school_damage_phy:get_sum()

  self.damage_sum_list[cs.damage.st.Physical] = phy_sum

  if max_damage > phy_sum then
    -- magic damage more then phy
    return
  end

  local party_max_hp = cs.get_party_hp_sum()
  if max_damage > spell_critical_damage_ratio * party_max_hp then
    -- magic damage has critical value
    return
  end

  -- reset magic school. use phy
  self.current_school = nil
end


pal.resist.init = function()
  ---@type pal.resist.Analyzer
  pal.resist.analyzer = pal.resist.Analyzer:new()
end

pal.resist.test = function()
  local party_max_hp = cs.get_party_hp_sum()
  local spell_critical_damage = math.floor(spell_critical_damage_ratio * party_max_hp)
  local damage_part = math.floor(spell_critical_damage / 10)

  do
    cs.damage.parser:handle_event(
            string.format("Bob's Frostbolt hits you for %d Shadow damage. (%d resisted)", damage_part, 4 * damage_part))
    cs.damage.parser:handle_event(
            string.format("Bob's Frostbolt hits you for %d Frost damage. (%d resisted)", 3 * damage_part, damage_part))

    local school = pal.resist.analyzer:get_school()
    local shadow_sum = pal.resist.analyzer:get_sum_damage(cs.damage.s.Shadow)
    local frost_sum = pal.resist.analyzer:get_sum_damage(cs.damage.s.Frost)
    assert(school == cs.damage.s.Shadow, school)
    assert(shadow_sum == 5 * damage_part, shadow_sum)
    assert(frost_sum == 4 * damage_part, frost_sum)
  end

  local hit_part = UnitHealthMax(cs.u.player) * retr_aura_ratio

  do
    for i=hit_part, spell_critical_damage * 2, hit_part do
      -- about 2x spell_critical_damage
      cs.damage.parser:handle_event("Bob hits you for 1 Frost damage. (1 blocked)")
    end

    assert(pal.resist.analyzer:get_school() == nil)
  end

  do
    --
    cs.damage.parser:handle_event(
            string.format("Bob's Frostbolt hits you for %d Shadow damage.", 6 * damage_part))

    local school = pal.resist.analyzer:get_school()
    assert(school == cs.damage.s.Shadow, school)

    local shadow_sum = pal.resist.analyzer:get_sum_damage(cs.damage.s.Shadow)
    local phy_sum = pal.resist.analyzer:get_sum_damage(cs.damage.st.Physical)
    assert(shadow_sum < phy_sum)
  end
end