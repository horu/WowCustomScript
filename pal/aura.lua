
local cs = cs_common
local pal = cs.pal


local aura_dict = {}

pal.aura = {}


-- stub
pal.aura.get_buff = function(spell_name)
  if not aura_dict[spell_name] then
    cs.print("CREATE AURA: "..pal.to_short(spell_name))
    aura_dict[spell_name] = cs.Buff.build(spell_name)
  end

  return aura_dict[spell_name]
end