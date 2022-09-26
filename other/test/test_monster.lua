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

local test_card={}
local originData =TableFunc.Copy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData
local function MakeToUse(card)
	local toUse={card=card,target_table = {}}

	for k,v in pairs(card.use_condition) do
		local choose_type=v[1]
		local num =v[2]
		local race=v[3]
		if choose_type =='select' then
			local rece_table = race=='hero' and heroData or monsterData
			if num <= 1 then
				TableFunc.Push(toUse.target_table , rece_table[1])
			else
				toUse.target_table = rece_table
			end
		end
	end
	return toUse
end


local mAI =monsterAI.new()
local skill_card={}
local preview_data = TableFunc.Copy(testData)
for k,v in pairs(monsterData) do
	local master = 'monster '..TableFunc.GetSerial(testData.characterData.monsterData[1])
	TableFunc.Push(skill_card,{})

	for i,skill in pairs(v.skill) do	
		local len = #skill_card
		local mon_skill_card = CardAssets.instance(skill,master)
		TableFunc.Push(skill_card[len] , mon_skill_card)
	end

	v.machine =mAI.decideMachine(preview_data ,v ,skill_card[len])
	v.machine:Update(preview_data,v)
	--make group and use
end

--[[
測試用 英雄2隻 怪物2隻 (hp atk..等素質)按照位置全部都是 1 or 2 
卡片預設的 master都是 英雄1號(素質全部都是 1)
target 預設都是怪物1號(素質全部都是 1)
]]

