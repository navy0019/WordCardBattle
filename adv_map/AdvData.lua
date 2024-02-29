local MapGenerator=require('adv_map.MapGenerator')
local SaveMgr=require('lib.saveManager')
local CharacterAssets = require('resource.characterAssets')

function Set_Adv_Character_Data(advData, CurrentSave)
	--print('SetAdvData')
	advData.hero_data={}

	for k,v in pairs(CurrentSave.CurrentTeam) do
		local hero = CharacterAssets.instance(v,k)
		hero.state={round_start={},round_end={}, every_card={},is_target={}}
		CurrentSave.CurrentTeamData[k]=CurrentSave.CurrentTeamData[k] or TableFunc.DeepCopy(hero.data)
		local current_team_data = CurrentSave.CurrentTeamData[k]

		hero.data.team_index=k
		TableFunc.Push(advData.hero_data ,hero)
	end
end

local AdvData={}
AdvData.default={Set_Adv_Character_Data=Set_Adv_Character_Data }
AdvData.metatable={}
AdvData.metatable.__index=function (table,key) return AdvData.default[key] end

function AdvData.Generate_Dungeon(setting,seed,floor)
	local setting = setting or {}
	local advData={
		player_pos={0,0},
		map_data={
			--6
			size=32,enter_room=1,exit_room=2,battle=6,normal_event=6,rare_event=3,
			passing_room=0,enable_effect={},dungeon_level=0,
			map_seed=seed~= nil and seed or RandomMachine:New_seed() ,	current_floor = floor~=nil and floor and 'first'
		},

	}
	--[[if seed ~=nil then
		print('Generate_Dungeon have seed',seed)
		advData.map_data.map_seed = seed
	else

		advData.map_data.map_seed = RandomMachine:New_seed()
		print('Generate_Dungeon new seed',advData.map_data.map_seed)
	end]]
	setmetatable(advData ,AdvData.metatable)
	local setting_path = _G.path..'setting'
	local setting_popen = io.popen(_G.cmd..setting_path)
	local t =Resource.GetAssets( setting_popen ,setting_path)

	--print('setting')
	--TableFunc.Dump(t)

	if t[floor] then
		for key,v in pairs(t[floor] ) do
			advData.map_data[key] = v     
		end

		advData.map_data.exit_room= t[floor]['next'] and #t[floor]['next'] or advData.map_data.exit_room

	else
		local array =TableFunc.DicToArray(t)
		assert(#array > 0 ,'no setting data')
		local data = TableFunc.Shift(array)
		for key,v in pairs(data) do
			advData.map_data[key] = v     
		end
		
		advData.map_data.exit_room= data['next'] and #data['next'] or advData.map_data.exit_room
		
	end

	local map_data = advData.map_data
	local room_number = map_data.enter_room + map_data.battle + map_data.normal_event + map_data.rare_event
	advData.map_data.empty_room = map_data.size - room_number


	advData.map ,advData.rooms= MapGenerator.New_Map(advData)
	advData:Set_Adv_Character_Data(SaveMgr.CurrentSave)

	return advData
end
return AdvData