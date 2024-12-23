--local Assets = require('resource.allAssets')
local Character = require('lib.character')
local CharacterAssets = require('resource.characterAssets')
local TableFunc = require('lib.TableFunc')

local monsterGenerator = {}
function CompairMin(t1, t2)
	return t1[2] < t2[2]
end

function monsterGenerator.GrowByRoomNum(adv_data, data)
	local roomNum = adv_data.map_data.passed_room
	local value   = math.floor(roomNum / 5)
	data.hp       = data.hp + value
	data.def      = data.def + value
	data.atk      = data.atk + value
end

function monsterGenerator.RandomMonster(adv_data)
	local max = 8
	local monsterValue = { 2, 2, 2, 4 }
	local monsterType = { 'm_small_1', 'm_mid_1', 'm_mid_2', 'm_XL_1' }
	--local posy = {420,195,165}

	local temp = {}
	local monsterInstance = {}

	local smallNum = 0


	while max > 0 do --2 ~ 4 monster	
		local ran1 = math.random(#monsterValue)
		local value = monsterValue[ran1]
		if max - value >= 0 then
			local monName = monsterType[ran1]
			TableFunc.Push(temp, { monName, value })
			max = max - value
		end
	end
	--temp={'m_small_01',}
	table.sort(temp, CompairMin)
	for k, monster in pairs(temp) do
		--local m = Assets.Monsters.instance(monster[1],0,0)
		local m = CharacterAssets.instance(monster[1], k)
		print('monsterGenerator state')
		TableFunc.Dump(m.state)
		m.data.team_index = k
		monsterGenerator.GrowByRoomNum(adv_data, m.data)
		TableFunc.Push(monsterInstance, m)
	end
	--table.sort( monsterInstance, CompairMin )

	--[[local posx = 773
	local posy = 472
	local accumulationOffset = 0
	local accumulationWidth = 0
	for k,monster in pairs(monsterInstance) do
		if monster ~='empty' then
			accumulationOffset=accumulationOffset+monster.space
			posx=773+accumulationWidth-accumulationOffset

			accumulationWidth=accumulationWidth+monster.width
			--monster.sprite.transform.position.x=posx
			--monster.sprite.transform.position.y=posy-monster.height
		end
	end]]

	return monsterInstance
end

return monsterGenerator
