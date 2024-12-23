local loop_map = {
	jump = function(battle, key_dic)
		for k, mon in pairs(battle.characterData.monsterData) do
			for i, target in pairs(key_dic.target_table) do
				if mon == target then
					return 'random (1 ,enemy (hp > 0))'
				end
			end
		end
		for k, hero in pairs(battle.characterData.heroData) do
			for i, target in pairs(key_dic.target_table) do
				if hero == target then
					return 'random (1 ,hero (hp > 0))'
				end
			end
		end
	end,
	loop = function(battle, key_dic)
		return 'target (hp > 0)'
	end
}
return loop_map
