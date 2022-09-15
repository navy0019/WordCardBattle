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

for k,v in pairs(Resource.card) do
	local master = TableFunc.Copy(testData.characterData.heroData[1])
	--print(master)
	local card=CardAssets.instance(k,master)
	--TableFunc.Dump(card)
	TableFunc.Push(test_card,card)
end

local function Test()
	for k,v in pairs(test_card) do
		local toUse=MakeToUse(v)
		print(v.name)
		StringAct.UseCard(testData,toUse)
		
		--[[for k,v in pairs(toUse.target_table) do
			TableFunc.Dump(v.data)
			for key,j in pairs(v.data) do
				--reset 對象的資料
				v.data[key]=k
			end
		end]]
		for i,hero in pairs(heroData) do
			local origin =originData.characterData.heroData[i]
			for key,data in pairs(hero.data) do
				if data~=origin.data[key] and key~='state'  then
					print(hero.key)
					TableFunc.Dump(hero.data)
					hero.data[key] = origin.data[key]
					break
				end
			end
		end
		for i,mon in pairs(monsterData) do
			local origin =originData.characterData.monsterData[i]
			for key,data in pairs(mon.data) do
				if data~=origin.data[key] and key~='state' then
					print(mon.key)
					TableFunc.Dump(mon.data)
					mon.data[key] = origin.data[key]
					break
				end
			end
		end
	end
end
--Test()
local t={'70% atk random 1 hero'}
local mAI =monsterAI.new()
for k,v in pairs(monsterData) do
	--mAI.MakeChance(testData, v.think_weights)
end
mAI.MakeChance(testData, t)
--[[
測試用 英雄2隻 怪物2隻 (hp atk..等素質)按照位置全部都是 1 or 2 
卡片預設的 master都是 英雄1號(素質全部都是 1)
target 預設都是怪物1號(素質全部都是 1)
]]

