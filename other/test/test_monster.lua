function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   if str:match("(.*/)") then
   	return str:match("(.*/)")
   else
   	return str:match("(.*[/\\])")
   end
end
path = script_path()
local head,tail =path:find('WordCardBattle')
path=path:sub(1,tail+1)

package.path = package.path..';'..path..'?.lua'

local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Resource = require('resource.Resource')
Resource.Init_Test()
--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.translate)
local testData=require('test_data')
local monsterAI=require('battle.monsterAI')
local CardAssets=require('resource.cardAssets')

local monsterData =testData.characterData.monsterData

local mAI =monsterAI.new()
local skill_card={}
for k,v in pairs(monsterData) do
	for key,c in pairs(Resource.card) do
		TableFunc.Push(v.skill ,key)
	end

	local master = 'monster '..TableFunc.GetSerial(testData.characterData.monsterData[1])
	TableFunc.Push(skill_card,{})
	local len = #skill_card

	for i,skill in pairs(v.skill) do	
		local mon_skill_card = CardAssets.instance(skill ,master)
		TableFunc.Push(skill_card[len] , mon_skill_card)
	end
	--print('skill card',#skill_card[len])
	--TableFunc.Dump(skill_card[len])
	v.machine =mAI.DecideMachine(testData ,v ,skill_card[len])
	v.machine:Update(testData ,v)
end


