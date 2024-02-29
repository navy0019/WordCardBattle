local loop_map={
	jump=function(battle , key_link)
		for k,mon in pairs(battle.characterData.monsterData) do
			for i,target in pairs(key_link.target_table) do
				if mon == target then
					return 'random (1 ,enemy (hp > 0))'
				end
			end
		end
		for k,hero in pairs(battle.characterData.heroData) do
			for i,target in pairs(key_link.target_table) do
				if hero == target then
					return 'random (1 ,hero (hp > 0))'
				end
			end
		end
	end,
	loop=function(battle , key_link)
		return 'target (hp > 0)'
	end
}
return loop_map