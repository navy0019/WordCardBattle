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
]]
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Resource = require('resource.Resource')
Resource.Init_Test()

--TableFunc.Dump(Resource.state)
local testData=require('test_data')
local monsterAI=require('battle.monsterAI')
local CardAssets=require('resource.cardAssets')

local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

--狀態要施加幾隻角色 ,target 預設都是hero
local test_num = 2
local function MakeToUse()
	local toUse={target_table = {}}
	for i=1,test_num  do
		if heroData[i] then
			TableFunc.Push(toUse.target_table , heroData[i])
		end
	end

	return toUse
end
local toUse=MakeToUse()


local function printData()
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
				origin[key] = hero[key]
				break
			else
				--print('same ',value ,origin.data[key] ,key)
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

				origin[key] = mon[key]
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
local function Test()
	local effect={'target','add_buff test_state[round:1]'}-- {'target','add_buff test_state[round:1]'}
	local machine=StringAct.NewMachine()
	StringAct.ReadEffect(testData ,machine ,effect ,toUse )

	--測試狀態的疊加 
	--StringAct.ReadEffect(testData ,machine ,effect ,toUse )
	printData()

end
local function stateUpdate(character , timing_tab)
	local StateHandler=require('battle.StateHandler')
	for k,state in pairs(timing_tab) do
		StateHandler.Update(testData , character , state ,timing_tab)
	end
end
local function TestStateUpdate()
	for k,hero in pairs(heroData) do
		for i,timing_tab in pairs(hero.state) do
			stateUpdate(hero , timing_tab)
		end	
	end
	printData()
end
Test()

print('Update State')
TestStateUpdate()