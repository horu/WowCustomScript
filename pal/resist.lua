local cs = cs_common
local pal = cs.pal


pal.resist = {}

-- analyzer current damage and detect max school damage
---@class pal.resist.Analyzer
pal.resist.Analyzer = cs.class()

function pal.resist.Analyzer:build()
  self.enemy_attack = { base = nil, ts = 0 }
  self.enemy_attack.is_valid = function(self)
    return self.school and cs.compare_time(7, self.ts)
  end

  --cs.st_target_cast_detector:subscribe(self, self._on_cast_detected)

  self.school_damage = {}

  local filter = {}
  filter[cs.damage.p.school] = cs.dict_to_list(cs.ss, "string")
  filter[cs.damage.p.target] = { cs.damage.u.player, cs.damage.u.party }
  cs.damage.parser:subscribe(filter, self, self._on_damage_detected)
end

-- nil - phy damage
function pal.resist.Analyzer:get_school()
  local school = self:_detect_target_cast()
  -- if target is casting then the school is must be detected now
  if school then
    return school
  end

  if self.enemy_attack:is_valid() then
    return self.enemy_attack.school
  end
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

function pal.resist.Analyzer:_on_cast_detected(spell_data)
  if not cs.check_target(cs.t.attackable) then
    return
  end

  local spell_school = spell_data:get_school()
  if not spell_school then
    return
  end

  self:_on_enemy_attack_school(spell_school)
end

---@param event cs.damage.Event
function pal.resist.Analyzer:_on_damage_detected(event)
  -- every hit phy damage is retr aura return 20 damage

  local spell_school = event.school
  self:_on_enemy_attack_school(spell_school)
end

-- reacion for enenmy cast to change resist aura
---@param spell_school cs.ss
function pal.resist.Analyzer:_on_enemy_attack_school(spell_school)
  if not self.enemy_attack:is_valid() or self.enemy_attack.school ~= spell_school then
    -- cs.print("SPELL DETECTED: ".. cs.ss.to_print(spell_school))
  end
  self.enemy_attack.school = spell_school
  self.enemy_attack.ts = GetTime()
end



pal.resist.init = function()
  ---@type pal.resist.Analyzer
  pal.resist.analyzer = pal.resist.Analyzer:new()
end