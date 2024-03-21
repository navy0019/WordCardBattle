local StringDecode = require('lib.StringDecode')
local Dungeon_Rule={
	level_effect={
		{number=25,effect='greed'},
		{number=25,effect='monster 2'},
		{number=20,effect='monster_leve 1'},
		{number=15,effect='greed'},
		{number=15,effect='monster 2'},
		{number=10,effect='monster_leve 1'},
		{number=8,effect='monster 3'},
		{number=7,effect='greed'},
		{number=6,effect='monster_leve 2'},

	},
	extra_level_effect={
		{number=5,effect='monster 3'},
		{number=5,effect='greed'},
		{number=5,effect='monster_leve 2'},
	},

}
Dungeon_Rule.Add_effect=function(self,map_data ,t)
	local key ,arg = StringDecode.Split_by(t.effect ,'%s')
	if map_data.enable_effect[key] then
		if arg then
			map_data.enable_effect[key] = map_data.enable_effect[key] + tonumber(arg)
		else
			map_data.enable_effect[key] = map_data.enable_effect[key] + 1
		end
	else
		if arg then
			map_data.enable_effect[key] = tonumber(arg)
		else
			map_data.enable_effect[key] =  1
		end
	end
end

local function next_level(map_data ,num)
	map_data.total_passed_room = map_data.total_passed_room + num
	map_data.passed_room = map_data.passed_room - num
	map_data.dungeon_level = map_data.dungeon_level +1
end
Dungeon_Rule.Check_Level=function(self,map_data )

	if map_data.dungeon_level  > #self.level_effect then
		local next_level = (map_data.dungeon_level  - #self.level_effect )%3 +1
		local effect = self.extra_level_effect[next_level]
		local need_number = effect.number 
		if map_data.passed_room >= need_number then
			next_level(map_data ,need_number)
			Dungeon_Rule:Add_effect(map_data , effect)
		end

		
	else
		local next_level = map_data.dungeon_level +1
		local effect = self.extra_level_effect[next_level]
		local need_number = effect.number
		if map_data.passed_room >= need_number then
			next_level(map_data ,need_number)
			Dungeon_Rule:Add_effect(map_data , effect)
		end

	end

end
Dungeon_Rule.Load_Level=function(self,map_data)
	map_data.enable_effect={}

	local extra_num = 0
	local extra_loop = 0
	local normal_loop= map_data.dungeon_level

		--make effect
	if map_data.dungeon_level  > #self.level_effect then
		normal_loop = #self.level_effect 
		extra_num= map_data.dungeon_level  - #self.level_effect 
		extra_loop= math.floor(extra_num / #self.extra_level_effect)
		extra_num=extra_num % #self.extra_level_effect		

	end

	for i=1 ,normal_loop do
		Dungeon_Rule:Add_effect(map_data , self.level_effect[i])
	end
	for i=1,extra_loop do
		for k,v in pairs(self.extra_level_effect) do
			Dungeon_Rule:Add_effect(map_data , v)
		end
	end
	for i=1,extra_num do
		Dungeon_Rule:Add_effect(map_data , self.extra_level_effect[i])
	end
end
return Dungeon_Rule