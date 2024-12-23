function script_Path()
	local str = debug.getinfo(2, "S").source:sub(2)
	if str:match("(.*/)") then
		return str:match("(.*/)")
	else
		return str:match("(.*[/\\])")
	end
end

Path = script_Path()
local head, tail = Path:find('WordCardBattle')
Path = Path:sub(1, tail + 1)

package.path = package.path .. ';' .. Path .. '?.lua'

--[[
測試用 (hp atk..等素質)按照位置全部都是 2 ,3, 4..... 可到test_data裡更改
]]
local GetOs = require('lib.get_os_name')
CurrentOs = GetOs.get_os_name()

local ComplexCommandMachine = require('battle.ComplexCommandMachine')
local SimpleCommandMachine = require('battle.SimpleCommandMachine')
local TableFunc = require('lib.TableFunc')


Resource = require('resource.Resource')
Resource.Init_Test()

local StateHandler = require('battle.StateHandler')

--TableFunc.Dump(Resource.state)
--print(type(Resource.state.poison.overlay))
local testData = require('other.test.data.test_data')
local CardAssets = require('resource.cardAssets')
local final_process = require('battle.command_act.final_process')

local originData = TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData = testData.characterData.monsterData

local test_num = 2
local function MakeToUse(state)
	local key_dic = { target_table = {}, self = state }
	for i = 1, test_num do
		if heroData[i] then
			TableFunc.Push(key_dic.target_table, heroData[i])
		end
	end

	return key_dic
end
--TableFunc.Dump(key_dic)

local function printData()
	for i, hero in pairs(heroData) do
		local origin = originData.characterData.heroData[i]
		--print(hero.key ,hero.data.remove_shield)
		for key, value in pairs(hero.data) do
			if value ~= origin.data[key] and type(origin.data[key]) ~= 'table' then
				print('name ' .. hero.key)
				print('team_index ' .. hero.data.team_index)
				print('hp ' .. hero.data.hp)
				print('shield ' .. hero.data.shield)
				print('ak ' .. hero.data.atk)
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
				for index, state in ipairs(state_tab) do
					print('[')
					--print('\tname:'..state.name)
					--print('\tround:'..state.round)
					for key, value in ipairs(state) do
						print('\t' .. key, value)
					end
					print(']')
				end
				--TableFunc.Dump(state_tab)
			end
		end
	end
end
local function TestAddBuff()
	local caster = 'monster ' .. TableFunc.GetSerial(monsterData[1])
	local state
	StateHandler.AddBuff(testData, heroData[1], 'poison(round:2 ,atk:3)', caster)
	--StateHandler.AddBuff(testData ,{heroData[2]} ,'poison(round:2)' ,caster)


	--[[local caster2 = 'monster '..TableFunc.GetSerial(heroData[2])
	StateHandler.AddBuff(testData ,{heroData[1]} ,'solid' ,caster2)]]
	printData()
end
local function stateUpdate(character, key, machine)
	for timing_key, timing_tab in pairs(character.state) do
		for k, state in pairs(timing_tab) do
			local res = Resource.state[state.name]
			--print('stateUpdate',state.data.name)
			if key ~= timing_key then return end
			if not TableFunc.Find(res.update_timing, 'trigger') then
				print("Excute", state.name)
				machine.key_dic = MakeToUse(state)
				StateHandler.Excute(testData, character, state, machine.key_dic)
				StateHandler.Update(testData, character, state, key)

				for i, result in ipairs(StateHandler.machine.result) do
					local nr = result
					if TableFunc.IsDictionary(result) then nr = { result } end
					TableFunc.Push(machine.result, nr)
				end
				TableFunc.Clear(StateHandler.machine.result)
				for k, v in pairs(machine.result) do --實現階段 + 整合會用到的state update
					for i, t in pairs(v) do
						local key = t.key
						--print('result final_process ',key ,final_process[key])
						if final_process[key] then
							final_process[key](testData, machine, t)
						end

						--[[if i >=2 then
							local main = v[1].state_update
							local current = v[i].state_update
							merge_state(main ,current)
							v[i].state_update={}
						end]]

						for j, s in pairs(t.state_update) do
							local state_table = s.target.state[s.state_key]
							for i, state in pairs(state_table) do
								StateHandler.Update(testData, s.target, state, s.state_key, 'every_card')
							end
						end
					end
				end
			else
				StateHandler.Update(testData, character, state, key, 'trigger')
			end
		end
	end
end
local function TestStateUpdate(machine)
	for k, hero in pairs(heroData) do
		for key, timing_tab in pairs(hero.state) do
			stateUpdate(hero, key, machine)
		end
	end

	printData()
end

TestAddBuff()
local machine = ComplexCommandMachine.NewMachine()
--machine.key_dic = key_dic
print('Update State')
TestStateUpdate(machine)
