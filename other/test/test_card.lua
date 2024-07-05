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
卡片預設的 holder都是 hero[1]
target 預設都是monster[1]
]] 

local ComplexCommandMachine=require('battle.ComplexCommandMachine')
local SimpleCommandMachine=require('battle.SimpleCommandMachine')

local TableFunc=require('lib.TableFunc')
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()
RandomMachine = require('lib.RandomMachine').new()

Resource = require('resource.Resource')
Resource.Init_Test()
--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.translate)
--TableFunc.Dump(Resource.state)
local testData=require('other.test.data.test_data')
local CardAssets=require('resource.cardAssets')
local Preview = require('battle.card_preview')

local test_card={}
local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

local StateHandler = require('battle.StateHandler')
local final_process = require('battle.command_act.final_process')

for k,v in pairs(Resource.card) do
	local holder = 'hero '..TableFunc.GetSerial(testData.characterData.heroData[1])
	local card=CardAssets.instance(k,holder)
	--print('card.info ',card.info)
	--TableFunc.Dump(card.info)
	TableFunc.Push(test_card,card)
end

local function MakeToUse(card)
	local key_link={card=card,self=card,target_table = {}}
	return key_link
end
local function MakeTarget(card ,key_link)
	for k,v in pairs(card.use_condition) do
		local choose_type=v[1]
		local num =v[2]
		local race=v[3]
		--print('need: ',choose_type , num ,race)
		if choose_type =='select' then
			local rece_table = race=='hero' and heroData or monsterData
			for i=1,num do
				if rece_table[i] then
					TableFunc.Push(key_link.target_table , rece_table[i])
					key_link.current_choose_target=rece_table[i]
				end
			end
		end
	end
	--print()
end
local function Add_Protect()
	local data ={name='protect',round = 1}
	local serial = 'monster '..TableFunc.GetSerial(monsterData[3])
	data.caster=serial
	TableFunc.Push(monsterData[1].state.protect , data) 
end
local function Add_Power_up()
	local data ={name='power_up',round=2}
	local serial = 'hero '..TableFunc.GetSerial(heroData[1])
	data.caster=serial
	TableFunc.Push(heroData[1].state.use_atk_card ,data)
end
local function Add_Break()
	local data ={name='break',round=1}
	local serial = 'hero '..TableFunc.GetSerial(heroData[1])
	data.caster=serial
	TableFunc.Push(monsterData[3].state.be_atk ,data)
end
local function Reset_Data()
	for i,hero in pairs(heroData) do
		local origin =originData.characterData.heroData[i]
		for key,value in pairs(hero.data) do
			hero.data[key]=origin.data[key]
		end
	end
	for i,mon in pairs(monsterData) do
		local origin =originData.characterData.monsterData[i]
		for key,value in pairs(mon.data) do
			mon.data[key]=origin.data[key]
		end
	end
end
local function Test()
	local machine=ComplexCommandMachine.NewMachine()
	local SCM = SimpleCommandMachine.NewMachine()

	Add_Protect()
	Add_Power_up()
	Add_Break()
	for k,card in pairs(test_card) do
		Reset_Data()
		local key_link=MakeToUse(card)
		MakeTarget(card ,key_link)

		--ComplexCommandMachine.ReadEffect(testData ,machine ,v.effect ,key_link ,'print_log')
		--TableFunc.Dump(key_link)
		machine:ReadEffect(testData ,card.effect ,key_link )
		--TableFunc.Dump(card.effect)
		print('card result',#machine.result ,card.effect)
		--TableFunc.Dump(machine.result)
		for k,v in pairs(machine.result) do
			print('[')
			for key,value in pairs(v) do
				if key~='target' then
					if type(value)=='table'then
						TableFunc.Dump(value)
					else
						print('\t'..key,value)
					end
				end
			end
			for key,value in pairs(v.target) do
				print('\tteam_index: '..value.data.team_index)
			end
			print(']')
		end

		local state_update ={}
		for k,v in pairs(machine.result) do
			--TableFunc.Dump(v.value)
			if TableFunc.IsDictionary(v) then
				local key =v.key
				--print('result key',key)
				if final_process[key] then 
					final_process[key](testData , machine,v) 
					--TableFunc.Push(state_update, v.value_state)
					for i,t in pairs(v.value_state) do
						TableFunc.MergeDifferent(state_update,t)
					end
				end
			else
				for i,t in pairs(v) do
					local key =t.key
					if final_process[key] then 
						final_process[key](testData , machine,t)
						--TableFunc.Push(state_update, t.value_state) 
						for j,tab in pairs(t.value_state) do
							TableFunc.MergeDifferent(state_update,tab)
						end
					end
				end
			end
			
		end
		--local map={target = targets ,holder =holder}
		--print('every_card state_update',#state_update)
		--TableFunc.Dump(state_update)
		for i,info in pairs(state_update) do
			
				local target_string ,state_table_string  = info[1] , info[2] 
				SCM:ReadEffect(testData ,target_string , key_link )
				local targets =TableFunc.Pop(SCM.stack)
				for k,target in pairs(targets) do
					local state_table = target.state[state_table_string]
					for i,state in pairs(state_table) do		
						StateHandler.Update( testData, target ,state ,state_table_string ,'every_card')
						--StateHandler.Update(battle , target , state ,state_key ,'trigger') 
					end	
				end
			
		end

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
					--TableFunc.Dump(hero)
					break
				end
			end
			--print('name '..hero.key..' is safe')
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
					break
				end
			end
			--print('name '..mon.key..' is safe')
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


