function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	if str:match("(.*/)") then
		return str:match("(.*/)")
	else
		return str:match("(.*[/\\])")
	end
end

Path = script_path()
local head, tail = Path:find('WordCardBattle')
Path = Path:sub(1, tail + 1)

package.path = package.path .. ';' .. Path .. '?.lua'

local TableFunc = require('lib.TableFunc')
local GetOs = require('lib.get_os_name')
CurrentOs = GetOs.get_os_name()

Resource = require('resource.Resource')
Resource.Init_Test()
--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.translate)
local testData = require('other.test.data.test_data')
local monsterAI = require('battle.monsterAI')
local CardAssets = require('resource.cardAssets')
--local StringDecode=require('lib.StringDecode')


local monsterData = testData.characterData.monsterData
local heroData = testData.characterData.heroData

local skill_card = {}

for i = 1, #monsterData do
	local v = monsterData[i]

	local holder = 'monster ' .. TableFunc.GetSerial(testData.characterData.monsterData[1])
	TableFunc.Push(skill_card, {})
	local len = #skill_card

	for i, skill in pairs(v.skill) do
		local mon_skill_card = CardAssets.instance(skill, holder)
		TableFunc.Push(skill_card[len], mon_skill_card)
	end

	--print('monster think ',i)
	v.AI = monsterAI.new(testData, v, skill_card[len])
	v.AI.machine:TransitionTo('MakeOptions', testData, v)
	v.AI:Think(testData, v)


	print('monster[' .. i .. '] think:' .. v.AI.machine.decide)
	print('\n\n')
end
