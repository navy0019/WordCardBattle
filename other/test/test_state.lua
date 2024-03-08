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
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local TableFunc=require('lib.TableFunc')


Resource = require('resource.Resource')
Resource.Init_Test()

local StateHandler=require('battle.StateHandler')

--TableFunc.Dump(Resource.state)
--print(type(Resource.state.poison.overlay))
local testData=require('other.test.data.test_data')
local CardAssets=require('resource.cardAssets')

local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

local test_num = 2
local function MakeToUse()
	local key_link={target_table = {}}
	for i=1,test_num  do
		if heroData[i] then
			TableFunc.Push(key_link.target_table , heroData[i])
		end
	end

	return key_link
end
local key_link=MakeToUse()
--TableFunc.Dump(key_link)

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
				print('def '..hero.data.def)
				print('remove_shield '..tostring(hero.data.remove_shield)..'\n')
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
				print('def '..mon.data.def)
				print('remove_shield '..tostring(mon.data.remove_shield)..'\n')

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
local function TestAddBuff()
	local caster = 'monster '..TableFunc.GetSerial(monsterData[1])
	StateHandler.AddBuff(testData ,{heroData[1]} ,'poison(round:2 ,atk:3)' ,caster)
	--StateHandler.AddBuff(testData ,{heroData[2]} ,'poison(round:2)' ,caster)


	--[[local caster2 = 'monster '..TableFunc.GetSerial(heroData[2])
	StateHandler.AddBuff(testData ,{heroData[1]} ,'solid' ,caster2)]]
	printData()

end
local function stateUpdate(character , key)
	
	for timing_key,timing_tab in pairs(character.state) do

		for k,state in pairs(timing_tab) do
			local res = Resource.state[state.name]
			--print('stateUpdate',state.data.name)
			if key~=timing_key then return end
			if not TableFunc.Find(res.update_timing ,'trigger') then
				StateHandler.Excute(testData , character , state ,key_link)
				StateHandler.Update(testData , character , state ,key)
			else
				StateHandler.Update(testData , character , state ,key ,'trigger' )
			end

		end
	end

end
local function TestStateUpdate()
	for k,hero in pairs(heroData) do
		for key,timing_tab in pairs(hero.state) do
			stateUpdate(hero , key)
		end	
	end
	printData()
end

TestAddBuff()

print('Update State')
TestStateUpdate()