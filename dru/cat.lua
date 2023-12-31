local cs = cs_common
local dru = cs.dru

dru.cat = {}


---@class dru.cat.Rip
dru.cat.Rip = cs.class()
function dru.cat.Rip:build()
  ---@type cs.Spell
  self.spell = dru.sp.Rip

  self.dam_by_combo = {}
  for _, line in self.spell:get_tooltip().text do
    self.dam_by_combo[1] = cs.regex(line, "1 point  : (%d+) damage over")
    if self.dam_by_combo[1] then
      self.dam_by_combo[2] = cs.regex(line, "2 points: (%d+) damage over")
      self.dam_by_combo[3] = cs.regex(line, "3 points: (%d+) damage over")
      self.dam_by_combo[4] = cs.regex(line, "4 points: (%d+) damage over")
      self.dam_by_combo[5] = cs.regex(line, "5 points: (%d+) damage over")
      break
    end
  end

  for i in pairs(self.dam_by_combo) do
    self.dam_by_combo[i] = tonumber(self.dam_by_combo[i])
  end

  cs_debug(self.dam_by_combo)
  assert(self.dam_by_combo[5])
end

function dru.cat.Rip:is_ready()
  local combo_points = GetComboPoints(cs.u.player, cs.u.target)
  if combo_points == 5 then
    return true
  end

  if combo_points > 1 then
    local hp_limit = self.dam_by_combo[combo_points] * 5 * (GetNumPartyMembers() + 1)
    return cs.check_target_hp(hp_limit)
  end
end

function dru.cat.Rip:cast()
  if not self:is_ready() then
    return
  end

  return self.spell:cast()
end



---@class dru.cat.Bite
dru.cat.Bite = cs.class()
function dru.cat.Bite:build()
  ---@type cs.Spell
  self.spell = dru.sp.FerociousBite

  self.dam_by_combo = {}
  for _, line in self.spell:get_tooltip().text do
    self.dam_by_combo[1] = cs.regex(line, "1 point  : [0-9]+-(%d+) damage")
    if self.dam_by_combo[1] then
      self.dam_by_combo[2] = cs.regex(line, "2 points: [0-9]+-(%d+) damage")
      self.dam_by_combo[3] = cs.regex(line, "3 points: [0-9]+-(%d+) damage")
      self.dam_by_combo[4] = cs.regex(line, "4 points: [0-9]+-(%d+) damage")
      self.dam_by_combo[5] = cs.regex(line, "5 points: [0-9]+-(%d+) damage")
      break
    end
  end

  for i in pairs(self.dam_by_combo) do
    self.dam_by_combo[i] = tonumber(self.dam_by_combo[i])
  end

  cs_debug(self.dam_by_combo)
  assert(self.dam_by_combo[5])
end

function dru.cat.Bite:is_ready()
  local combo_points = GetComboPoints(cs.u.player, cs.u.target)
  if combo_points == 5 then
    return true
  end

  if combo_points > 0 then
    local hp_limit = self.dam_by_combo[combo_points] * (2 + 2/combo_points)
    return cs.check_target_hp(hp_limit)
  end
end

function dru.cat.Bite:cast()
  if not self:is_ready() then
    return
  end

  return self.spell:cast()
end


---@class dru.cat.Form
dru.cat.Form = cs.class(dru.form.Base)
dru.cat.Form.name = "Cat Form"
function dru.cat.Form:build()
  ---@type dru.cat.Rip
  self.rip = dru.cat.Rip:create()
  ---@type dru.cat.Bite
  self.bite = dru.cat.Bite:create()
end

function dru.cat.Form:attack()
  if dru.sp.Prowl:check_exists() then
    if not cs.check_target(cs.t.attackable) then return end
  else
    if not cs.auto_attack() then return end
    if dru.sp.FaerieFire_Feral:cast() then return end
  end

  if dru.sp.Ravage:cast() then return end
  if self.bite:cast() then return end
  if dru.sp.Shred:cast() then return end
  if dru.sp.Rip:cast() then return end
  if dru.sp.TigerFury:rebuff() then return end
  if dru.sp.Rake:cast() then return end
  if dru.sp.Claw:cast() then return end
end