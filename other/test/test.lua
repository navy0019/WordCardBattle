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

local testData=require('test_data')
local CardAssets=require('resource.cardAssets')

local test_card={}
local function MakeToUse(card)
	local toUse={card=card,target_table = {}}
	local heroData = testData.characterData.heroData
	local monsterData =testData.characterData.monsterData
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

local function ReadEffect()
	for k,v in pairs(test_card) do
		local toUse=MakeToUse(v)
		print(v.name)
		local record=StringAct.ReadEffect(toUse)
		TableFunc.Dump(record)
		
		for k,v in pairs(toUse.target_table) do
			TableFunc.Dump(v.data)
			for key,j in pairs(v.data) do
				--reset 對象的資料
				v.data[key]=k
			end
		end
	end
end
ReadEffect()
--[[
測試用 英雄2隻 怪物2隻 (hp atk..等素質)按照位置全部都是 1 or 2 
卡片預設的 master都是 英雄1號(素質全部都是 1)
target 預設都是怪物1號(素質全部都是 1)
]]

