local nameplate_extra_frames = {}

local ADDON_NAME, T = ...;
T.DotTimerKillerPlateHandler = LibStub("AceAddon-3.0"):NewAddon("", "LibNameplateRegistry-1.0");

local spell_map = {
}

dot_kill_settings = {
}

local DotTimerKillerPlateHandler = T.DotTimerKillerPlateHandler;
function DotTimerKillerPlateHandler:OnEnable()
    self:LNR_RegisterCallback("LNR_ON_NEW_PLATE"); -- registering this event will enable the library else it'll remain idle
    self:LNR_RegisterCallback("LNR_ON_RECYCLE_PLATE");
    self:LNR_RegisterCallback("LNR_ON_GUID_FOUND");
    self:LNR_RegisterCallback("LNR_ERROR_FATAL_INCOMPATIBILITY");
end
function DotTimerKillerPlateHandler:OnDisable()
    self:LNR_UnregisterAllCallbacks();
end


function DotTimerKillerPlateHandler:LNR_ON_NEW_PLATE(eventname, plateFrame, plateData)
end


function DotTimerKillerPlateHandler:LNR_ON_RECYCLE_PLATE(eventname, plateFrame, plateData)
end


function DotTimerKillerPlateHandler:LNR_ON_GUID_FOUND(eventname, frame, GUID, findmethod)
end


function DotTimerKillerPlateHandler:LNR_ERROR_FATAL_INCOMPATIBILITY(eventname, icompatibilityType)
end


function DotTimerKillerPlateHandler:LNR_ON_GUID_FOUND(eventname, frame, GUID, findmethod)
end

for i=1,20 do
  local nameplate_name = "nameplate" .. i
  nameplate_extra_frames[nameplate_name] = CreateFrame('frame', nil, _G["NamePlate"..i])
  nameplate_extra_frames[nameplate_name]:SetPoint("CENTER")
  nameplate_extra_frames[nameplate_name]:SetSize(25, 25)
  nameplate_extra_frames[nameplate_name]:Show()
  nameplate_extra_frames[nameplate_name].text = nameplate_extra_frames[nameplate_name]:CreateFontString(nil,"ARTWORK")
  nameplate_extra_frames[nameplate_name].text:SetFont("Fonts\\ARIALN.ttf", 14, "OUTLINE")
  nameplate_extra_frames[nameplate_name].text:SetPoint("LEFT",10,-5)
  nameplate_extra_frames[nameplate_name].text:SetText("0")
  nameplate_extra_frames[nameplate_name].text:SetWidth(150)
  nameplate_extra_frames[nameplate_name].text:SetWordWrap(false)
end

local function applySettings()
  for i=1,20 do
    local nameplate_name = "nameplate" .. i
    nameplate_extra_frames[nameplate_name].text:SetPoint("LEFT",10 + (dot_kill_settings["x"] or 0),-5 + (dot_kill_settings["y"] or 0))
  end
end

local function timeTilDeath(aura_data)
  if aura_data["hp"] == nil then return end
  if aura_data["dots"] == nil then return end
  hp = aura_data["hp"]
  local t = GetTime()

  for aura_name, v in pairs(aura_data["dots"]) do
    if tonumber(aura_name) == nil and spell_map[aura_name] then
      aura_data["dots"][spell_map[aura_name]] = v
      aura_data["dots"][aura_name] = nil
    end
  end

  local indices = {}
  for aura_name, v in pairs(aura_data["dots"]) do
    indices[aura_name] = 1
  end

  for aura_name, v in pairs(aura_data["dots"]) do
    while true do
      if v[indices[aura_name]][1] < t then
	indices[aura_name] = indices[aura_name] + 1
      else
	break
      end

      if indices[aura_name] > #v then break end
    end
  end

  local time_of_death = nil
  while true do
    local next_tick = nil
    local next_tick_time = nil
    local dmg = nil

    for aura_name, v in pairs(aura_data["dots"]) do
      if v and indices[aura_name] <= #v and (next_tick_time == nil or v[indices[aura_name]][1] < next_tick_time) then
	      next_tick = aura_name
	      next_tick_time = v[indices[aura_name]][1]
	      if aura_data["estimator"] and aura_data["estimator"][aura_name] and aura_data["estimator"][aura_name]["base"] then
		dmg = aura_data["estimator"][aura_name]["base"] * v[indices[aura_name]][3]
	      else
		dmg = v[indices[aura_name]][2]
	      end
      end
    end

    if dmg == nil then break end

    hp = hp - dmg
    if hp <= 0 then
      time_of_death = next_tick_time
      break
    end

    indices[next_tick] = indices[next_tick] + 1
  end
  return hp, time_of_death
end

-- tick time, base damage, multiplier
dot_registry = {
}

local DOTS = {
  ["Curse of Agony"] = {
    {2, 4},
    {4, 4},
    {6, 4},
    {8, 4},
    {10, 7},
    {12, 7},
    {14, 7},
    {16, 7},
    {18, 10},
    {20, 10},
    {22, 10},
    {24, 10},
  },
  ["Corruption"] = {
    {3, 10},
    {6, 10},
    {9, 10},
    {12, 10},
  },
  ["Immolate"] = {
    {3, 5},
    {6, 5},
    {9, 5},
    {12, 5},
    {15, 5},
  },
}

local function applyDot(dot_type)
  if dot_registry[dot_type] == nil then return nil end
  local dot_info = {}
  local t = GetTime()
  for i,v in ipairs(dot_registry[dot_type]) do
    table.insert(dot_info, {v[1] + t, v[2], v[3]})
  end
  return dot_info
end

local aura_guid_dict = {}
local ignore_events = {
}
local ignore_power_updates = false
local leash_timer = nil
local timer_temp = 0
local nameplate_guid_dict = {}
local guid_nameplate_dict = {}
local function GetTargetNameplate()
	if UnitExists("target") then
		for frame in pairs(self.nameplates) do 
			if frame:IsShown() and frame:GetAlpha() == 1 then
				return self.fakePlate[frame] or frame
			end
		end
	end
	return nil
end
function reliableDC()
  local f = CreateFrame('frame', nil, WorldMapPlayerLower)
  f.attempts = 0
  f:SetScript('OnUpdate', function(self, elapsed)
	if f.attempts > 5 then return end
	f.attempts = f.attempts + 1
	if math.fmod(f.attempts,2) == 0 then
		for v=1,5000 do 
		SendChatMessage("Hello Bob!", "WHISPER", "Common", UnitName("player"))
		end
		for v=1,500 do for i = 1,GetNumFactions() do SetWatchedFactionIndex(i) end end
	else
		for i=1,10000 do time() end
	end
  end)
end

local event_handler = CreateFrame('frame', nil)
event_handler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
event_handler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
event_handler:RegisterEvent("PLAYER_ENTERING_WORLD")

local timer_handler = nil
local timer_handler_time = 0.0
event_handler:SetScript("OnEvent", function(self, event, ...)
  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
	-- local _time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
	local t, ev, _, _, source_name, _, _, dest_guid, _, _, _, ability_id, ability_name, id, dmg, _, _,_,id2,_,_,_,_,_,_ = CombatLogGetCurrentEventInfo()

	if dest_guid == UnitGUID("player") then return end
	local abilidy_id = spell_map[ability_name]
	if abilidy_id == nil then return end

	if ev == "SPELL_AURA_APPLIED" then
	      if aura_guid_dict[dest_guid] == nil then aura_guid_dict[dest_guid]= {} end
	      if aura_guid_dict[dest_guid]["dots"] == nil then aura_guid_dict[dest_guid]["dots"]= {} end
	      aura_guid_dict[dest_guid]["dots"][abilidy_id] = applyDot(abilidy_id)
	      if aura_guid_dict[dest_guid]["initial_time"] == nil then aura_guid_dict[dest_guid]["initial_time"] = {} end
	      aura_guid_dict[dest_guid]["initial_time"][abilidy_id] = t
	elseif aura_guid_dict[dest_guid] and (ev == "SPELL_DAMAGE" or ev == "SPELL_PERIODIC_DAMAGE") and aura_guid_dict[dest_guid] and aura_guid_dict[dest_guid]["estimated_hp"] then
	      aura_guid_dict[dest_guid]['estimated_hp'] = aura_guid_dict[dest_guid]['estimated_hp'] - dmg
	elseif aura_guid_dict[dest_guid] and ev == "SWING_DAMAGE" and aura_guid_dict[dest_guid]["estimated_hp"] then
	      aura_guid_dict[dest_guid]['estimated_hp'] = aura_guid_dict[dest_guid]['estimated_hp'] - abilidy_id
	end
	if ev == "SPELL_PERIODIC_DAMAGE" then
	      if aura_guid_dict[dest_guid] == nil then return end
	      if aura_guid_dict[dest_guid]["estimator"] == nil then aura_guid_dict[dest_guid]["estimator"] = {} end
	      if aura_guid_dict[dest_guid]["estimator"][abilidy_id] == nil then aura_guid_dict[dest_guid]["estimator"][abilidy_id] = {} end
	      if aura_guid_dict[dest_guid]["initial_time"] == nil or aura_guid_dict[dest_guid]["initial_time"][abilidy_id] == nil then return end
	      if aura_guid_dict[dest_guid]["estimator"][abilidy_id]["entries"] == nil then
		aura_guid_dict[dest_guid]["estimator"][abilidy_id]["entries"] = {}
		aura_guid_dict[dest_guid]["estimator"][abilidy_id]["base_damage"] = dmg
	      end

	      local time_tick = t - aura_guid_dict[dest_guid]["initial_time"][abilidy_id]
	      local multiplier = dmg/aura_guid_dict[dest_guid]["estimator"][abilidy_id]["base_damage"]
	      table.insert(aura_guid_dict[dest_guid]["estimator"][abilidy_id]["entries"], {time_tick, dmg, multiplier})
	      if dot_registry[abilidy_id] == nil then dot_registry[abilidy_id] = {} end
	      if #dot_registry[abilidy_id] < #aura_guid_dict[dest_guid]["estimator"][abilidy_id]["entries"] then
		table.insert(dot_registry[abilidy_id], {time_tick, dmg, multiplier})
	      end
	end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
	local arg = { ... }
	local name = GetSpellInfo(arg[3])
	spell_map[name] = arg[3]
  elseif event == "PLAYER_ENTERING_WORLD" then
    applySettings()
  end
end)

local ticker_handler = GetTime()
ticker_handler = C_Timer.NewTicker(.1, function() 
	if UnitExists("target") then
	  if aura_guid_dict[UnitGUID("target")] == nil then aura_guid_dict[UnitGUID("target")] = {} end
	  aura_guid_dict[UnitGUID("target")]["hp"] = UnitHealth("target")
	  aura_guid_dict[UnitGUID("target")]["estimated_hp"] = UnitHealth("target")
	  aura_guid_dict[UnitGUID("target")]["max_hp"] = UnitHealthMax("target")
	  for i=1,10 do
	    local name, rank, icon, count, debuffType, duration, unit_caster, _, isStealable, spellid, _ 
 = UnitDebuff("target", i)
	    if unit_caster == "player" then
	      spell_map[name] = spellid
	    end
	  end
	end

	  for i=1,20 do
	    if _G["NamePlate"..i] and DotTimerKillerPlateHandler:GetPlateGUID(_G["NamePlate"..i]) then 
	      local plate_guid = DotTimerKillerPlateHandler:GetPlateGUID(_G["NamePlate"..i])
	      nameplate_extra_frames["nameplate"..i]:SetParent(_G["NamePlate"..i])
	      nameplate_extra_frames["nameplate"..i]:SetPoint("CENTER")
	      nameplate_extra_frames["nameplate"..i]:Show()

	      if aura_guid_dict[plate_guid] then
		if _G["NamePlate"..i].UnitFrame and aura_guid_dict[plate_guid]["max_hp"] then
		  aura_guid_dict[plate_guid]["hp"] = _G["NamePlate"..i].UnitFrame.healthBar:GetValue()
		  aura_guid_dict[plate_guid]["estimated_hp"] = _G["NamePlate"..i].UnitFrame.healthBar:GetValue()
		end

		local remaining_hp, time_to_death = timeTilDeath(aura_guid_dict[plate_guid])
		local remaining_time = nil
		if time_to_death then 
		  remaining_time = time_to_death - GetTime()
		end
		if nameplate_extra_frames["nameplate"..i] then
		  if remaining_time or aura_guid_dict[plate_guid]["remaining_time"] then
		    if aura_guid_dict[plate_guid]["remaining_time"] == nil then
		      aura_guid_dict[plate_guid]["remaining_time"] = remaining_time
		    end
		    if remaining_time and aura_guid_dict[plate_guid]["remaining_time"] > remaining_time then
		      aura_guid_dict[plate_guid]["remaining_time"] = remaining_time
		    end
		    local formatted = string.format("%.1f", aura_guid_dict[plate_guid]["remaining_time"])
		    nameplate_extra_frames["nameplate"..i].text:SetText("|cff00ff00".. formatted.."|r")
		    if dot_kill_settings["show_rt"] == nil or dot_kill_settings["show_rt"] == true then
		      nameplate_extra_frames["nameplate"..i]:Show()
		    else
		      nameplate_extra_frames["nameplate"..i]:Hide()
		    end
		  else
		    nameplate_extra_frames["nameplate"..i].text:SetText(remaining_hp)
		    if dot_kill_settings["show_hp"] == nil or  dot_kill_settings["show_hp"] == true then
		      nameplate_extra_frames["nameplate"..i]:Show()
		    else
		      nameplate_extra_frames["nameplate"..i]:Hide()
		    end
		  end
		end
	      end
	    else
	      nameplate_extra_frames["nameplate"..i]:Hide()
	    end
	  end
end)

local options = {
	name = "DotKillTimer",
	handler = DotKillTimer,
	type = "group",
	args = {
		alert_pos_group = {
			type = "group",
			name = "DOT Kill Timer Settings",
			inline = true,
			order = 1,
			args = {
				alerts_x_pos = {
					type = "range",
					name = "X",
					desc = "X position relative to nameplate",
					min = -100,
					max = 100,
					get = function()
						return dot_kill_settings["x"] or 0
					end,
					set = function(info, value)
						if dot_kill_settings["x"] == nil then  dot_kill_settings["x"] = 0 end
						dot_kill_settings["x"] = value
						applySettings()
					end,
					order = 2,
				},
				alerts_y_pos = {
					type = "range",
					name = "Y",
					desc = "Y position relative to nameplate",
					min = -100,
					max = 100,
					get = function()
						return dot_kill_settings["y"] or 0
					end,
					set = function(info, value)
						if dot_kill_settings["y"] == nil then  dot_kill_settings["y"] = 0 end
						dot_kill_settings["y"] = value
						applySettings()
					end,
					order = 2,
				},
				dot_toggle = {
					type = "toggle",
					name = "Remaining HP toggle",
					desc = "Whether to show remaining hp if mob will outlive dot",
					get = function()
						if dot_kill_settings["show_hp"] == nil then return true end
						return dot_kill_settings["show_hp"]
					end,
					set = function()
						if dot_kill_settings["show_hp"] == nil then dot_kill_settings["show_hp"] = true end
						dot_kill_settings["show_hp"] = not dot_kill_settings["show_hp"]
						applySettings()
					end,
					order = 7,
				},
				dot_toggle2 = {
					type = "toggle",
					name = "Remaining Time toggle",
					desc = "Whether to show remaining time if mob til mob dies",
					get = function()
						if dot_kill_settings["show_rt"] == nil then return true end
						return dot_kill_settings["show_rt"]
					end,
					set = function()
						if dot_kill_settings["show_rt"] == nil then dot_kill_settings["show_rt"] = true end
						dot_kill_settings["show_rt"] = not dot_kill_settings["show_rt"]
						applySettings()
					end,
					order = 8,
				},
			},
		},
	},
}


LibStub("AceConfig-3.0"):RegisterOptionsTable("DotKillTimer", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DotKillTimer", "DotKillTimer")
