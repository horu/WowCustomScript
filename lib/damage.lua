
local cs = cs_common


local DamageParser = cs.create_class_(function()
  --local frame = cs.create_simple_frame()
  --
  --frame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
  --frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
  --frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
  --frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
  ----
  ----frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
  ----frame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
  --
  --frame:SetScript("OnEvent", function()
  --  cs.print_table({ e = event, a1=arg1, a2=arg2, a3=arg3, a4=arg4, a5=arg5})
  --end)
  --
  --local parser = DamageParser:new()
  --
  --parser.frame = frame
  --return parser
end)

local st_damage_parser = DamageParser.build()