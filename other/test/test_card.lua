local function script_path()
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

--[[
測試用 (hp atk..等素質)按照位置全部都是 2 ,3, 4..... 可到test_data裡更改
卡片預設的 holder都是 hero[1]
target 預設都是monster[1]
]]

local ComplexCommandMachine = require('battle.ComplexCommandMachine')

local TableFunc = require('lib.TableFunc')
local GetOs = require('lib.get_os_name')
CurrentOs = GetOs.get_os_name()
RandomMachine = require('lib.RandomMachine').new()

Resource = require('resource.Resource')
Resource.Init_Test()
--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.translate)
--TableFunc.Dump(Resource.state)
local testData = require('other.test.data.test_data')
local CardAssets = require('resource.cardAssets')
local StringDecode = require('lib.StringDecode')

local test_card = {}
local originData = TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData = testData.characterData.monsterData

local StateHandler = require('battle.StateHandler')
local final_process = require('battle.command_act.final_process')

for k, v in pairs(Resource.card) do
	local holder = 'hero ' .. TableFunc.GetSerial(testData.characterData.heroData[1])
	local card = CardAssets.instance(k, holder)
	--print('card.info ',card.info)
	--TableFunc.Dump(card.info)
	TableFunc.Push(test_card, card)
end

local function MakeToUse(card)
	local key_dic = { card = card, self = card, target_table = {} }
	return key_dic
end
local function MakeTarget(card, key_dic)
	--print('MakeTarget', card.use_condition)
	for k, v in pairs(card.use_condition) do
		local choose_type, num, race = StringDecode.Split_by(v, '%s')
		--print('need: ', choose_type, num, race)
		if choose_type == 'select' then
			local rece_table = race == 'hero' and heroData or monsterData
			for i = 1, num do
				if rece_table[i] then
					TableFunc.Push(key_dic.target_table, rece_table[i])
					key_dic.current_choose_target = rece_table[i]
				end
			end
		end
	end
	--print('MakeTarget', #key_dic.target_table)
end
local function Add_Protect()
	local data = { name = 'protect', round = 1 }
	local serial = 'monster ' .. TableFunc.GetSerial(monsterData[3])
	data.caster = serial
	TableFunc.Push(monsterData[1].state.protect, data)
end
local function Add_Power_up()
	local data = { name = 'power_up', round = 2 }
	local serial = 'hero ' .. TableFunc.GetSerial(heroData[1])
	data.caster = serial
	TableFunc.Push(heroData[1].state.use_atk_card, data)
end
local function Add_Fragile()
	local data = { name = 'fragile', round = 2 }
	local serial = 'hero ' .. TableFunc.GetSerial(heroData[1])
	data.caster = serial
	TableFunc.Push(monsterData[2].state.be_atk, data)
end
local function Add_State_Buff()
	local data = { name = 'bless', round = 2 }
	local serial = 'hero ' .. TableFunc.GetSerial(heroData[1])
	data.caster = serial
	TableFunc.Push(heroData[1].state.use_buff_card, data)
end
local function Reset_Data()
	for i, hero in pairs(heroData) do
		local origin = originData.characterData.heroData[i]
		for key, value in pairs(hero.data) do
			hero.data[key] = origin.data[key]
		end
	end
	for i, mon in pairs(monsterData) do
		local origin = originData.characterData.monsterData[i]
		for key, value in pairs(mon.data) do
			mon.data[key] = origin.data[key]
		end
	end
end

local function merge_state(t1, t2)
	function trigger_test(main, current)
		if main.trigger and current.trigger then
			if main.trigger == current.trigger then
				return true
			end
			return false
		else
			return true
		end
	end

	local t = {}
	for k, current in pairs(t2) do
		--print('merge k?',k)
		local test = true
		for i, main in pairs(t1) do
			--print('merge i?',i)
			if main.target == current.target and main.state_key == current.state_key and trigger_test(main, current) then
				test = false
			end
		end
		if test then
			--print('merge!!', current.target.key, current.state_key)
			TableFunc.Push(t, current)
		end
	end
	--print('merge_state',#t)
	for k, v in pairs(t) do
		TableFunc.Push(t1, v)
	end
end
local function Test()
	local machine = ComplexCommandMachine.NewMachine()

	Add_State_Buff()
	--Add_Protect()
	--Add_Power_up()
	--Add_Fragile()
	for k, card in pairs(test_card) do
		Reset_Data()
		local key_dic = MakeToUse(card)
		MakeTarget(card, key_dic)
		--ComplexCommandMachine.ReadEffect(testData ,machine ,v.effect ,key_dic ,'print_log')
		--TableFunc.Dump(key_dic)
		machine:ReadEffect(testData, card.effect, key_dic)
		--print('machine.key_dic', machine.key_dic)
		--TableFunc.Dump(key_dic)
		--TableFunc.Dump(card.effect)
		--print('card result',#machine.result ,card.effect)	
		--TableFunc.Dump(machine.result)

		key_dic.target_table = {}

		for k, v in pairs(machine.result) do
			if TableFunc.IsDictionary(v) then machine.result[k] = { v } end
		end

		local state_update = {}
		for k, v in pairs(machine.result) do --實現階段 + 整合會用到的state update
			--print('result', TableFunc.IsDictionary(v))
			--TableFunc.Dump(v)
			for i, t in pairs(v) do
				local key = t.key
				--print('result final_process ',key ,final_process[key])
				if final_process[key] then
					final_process[key](testData, machine, t)
				end

				if i >= 2 then
					local main = v[1].state_update
					local current = v[i].state_update
					--print('merge state')
					--TableFunc.Dump(current)
					merge_state(main, current)
					v[i].state_update = {}
				end

				for j, s in pairs(t.state_update) do
					local state_table = s.target.state[s.state_key]
					for i, state in pairs(state_table) do
						StateHandler.Update(testData, s.target, state, s.state_key, 'every_card')
					end
				end
			end
		end


		for i, hero in pairs(heroData) do
			local origin = originData.characterData.heroData[i]
			--print(hero.key ,hero.data.remove_shield)
			for key, value in pairs(hero.data) do
				if value ~= origin.data[key] and type(origin.data[key]) ~= 'table' then
					print('name ' .. hero.key)
					print('team_index ' .. hero.data.team_index)
					print('hp ' .. hero.data.hp)
					print('shield ' .. hero.data.shield)
					print('atk ' .. hero.data.atk)
					print('def ' .. hero.data.def)
					print('remove_shield ' .. tostring(hero.data.remove_shield) .. '\n')
					--TableFunc.Dump(hero)
					break
				end
			end
			--print('name '..hero.key..' is safe')
			for k, state_tab in pairs(hero.state) do
				if #state_tab > 0 then
					print(hero.key .. ',state: ' .. k)
					TableFunc.Dump(state_tab)
				end
			end
		end
		print('\n')
		for i, mon in pairs(monsterData) do
			local origin = originData.characterData.monsterData[i]
			for key, value in pairs(mon.data) do
				if value ~= origin.data[key] and type(origin.data[key]) ~= 'table' then
					print('name ' .. mon.key)
					print('team_index ' .. mon.data.team_index)
					print('hp ' .. mon.data.hp)
					print('shield ' .. mon.data.shield)
					print('atk ' .. mon.data.atk)
					print('def ' .. mon.data.def)
					print('remove_shield ' .. tostring(mon.data.remove_shield) .. '\n')
					break
				end
			end
			--print('name '..mon.key..' is safe')
			for k, state_tab in pairs(mon.state) do
				if #state_tab > 0 then
					print(mon.key .. ',state: ' .. k)
					TableFunc.Dump(state_tab)
				end
			end
		end
	end
end
Test()
