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

--[[
測試用 (hp atk..等素質)按照位置全部都是 2 ,3, 4..... 可到test_data裡更改
卡片預設的 master都是 hero[1]
target 預設都是monster[1]
]]
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Resource = require('resource.Resource')
Resource.Init_Test()
--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.translate)
--TableFunc.Dump(Resource.state)
local testData=require('test_data')
local monsterAI=require('battle.monsterAI')
local CardAssets=require('resource.cardAssets')

local test_card={}
local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

for k,v in pairs(Resource.card) do
	local master = 'hero '..TableFunc.GetSerial(testData.characterData.heroData[1])
	local card=CardAssets.instance(k,master)
	TableFunc.Push(test_card,card)
end

local function MakeToUse(card)
	local toUse={card=card,self=card,target_table = {}}

	for k,v in pairs(card.use_condition) do
		local choose_type=v[1]
		local num =v[2]
		local race=v[3]
		if choose_type =='select' then
			local rece_table = race=='hero' and heroData or monsterData
			for i=1,num do
				if rece_table[i] then
					TableFunc.Push(toUse.target_table , rece_table[i])
				end
			end
		end
	end
	return toUse
end

local function Test()
	local machine=StringAct.NewMachine()
	for k,v in pairs(test_card) do
		local toUse=MakeToUse(v)
		print(v.name)
		StringAct.ReadEffect(testData ,machine ,v.effect,toUse ,'print_log')

		for i,hero in pairs(heroData) do
			local origin =originData.characterData.heroData[i]
			for key,value in pairs(hero.data) do

				if value~=origin.data[key] and type(origin.data[key])~='table'  then
					print('name '..hero.key)
					print('team_index '..hero.data.team_index)
					print('hp '..hero.data.hp)
					print('shield '..hero.data.shield)
					print('ak '..hero.data.atk)
					print('def '..hero.data.def..'\n')
					--TableFunc.Dump(hero)
					hero[key] = origin[key]
					break
				end
			end
			for k,state_tab in pairs(hero.state) do
				if #state_tab >0 then
					print(hero.key..',state: '..k)
					TableFunc.Dump(state_tab)
				end
			end
		end
		print('\n')
		for i,mon in pairs(monsterData) do
			local origin =originData.characterData.monsterData[i]
			for key,value in pairs(mon.data) do
				if value~=origin.data[key] and type(origin.data[key])~='table' then
					print('name '..mon.key)
					print('team_index '..mon.data.team_index)
					print('hp '..mon.data.hp)
					print('shield '..mon.data.shield)
					print('atk '..mon.data.atk)
					print('def '..mon.data.def..'\n')
					mon[key] = origin[key]
					break
				end
			end
			for k,state_tab in pairs(mon.state) do
				if #state_tab >0 then
					print(mon.key..',state: '..k)
					TableFunc.Dump(state_tab)
				end
			end
		end
	end
end
Test()


