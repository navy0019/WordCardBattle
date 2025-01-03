local TableFunc              = require('lib.TableFunc')
local StringDecode           = require('lib.StringDecode')

local Simple_Command_Machine = require('battle.SimpleCommandMachine')
local SCMachine              = Simple_Command_Machine.NewMachine()

local CC_T                   = require('battle.command_act.cc_t')
local CC_ACT                 = require('battle.command_act.cc_act')
--local final_process = require('battle.command_act.final_process')

local complex_command        = {}
--TableFunc.Merge(complex_command,final_process)

local function check_protect(targets, battle, info)
	--StateHandler.machine=
	local hero_data = battle.characterData.heroData
	local monster_data = battle.characterData.monsterData
	--local target =target
	local t = TableFunc.ShallowCopy(targets)
	--print('check_protect len',#t)
	--print('check_protect')
	--TableFunc.Dump(targets)
	for k, target in pairs(targets) do
		if #target.state.protect > 0 then
			--print('have protect')
			local serial_type, serial = StringDecode.Split_by(target.state.protect[1].caster, '%s')
			local target_data = serial_type == 'hero' and hero_data or monster_data
			--print('serial ',serial_type ,serial)
			local i = TableFunc.MatchSerial(target_data, serial)
			if i and target_data[i].data.hp > 0 then
				TableFunc.Push(info.state_update, { target = target, state_key = 'protect' })
				--local state = target.state.protect[1]
				--StateHandler.Update(battle , target , state ,'protect' ,'trigger')
				--return target_data[k]
				--print('change target!!')
				t[k] = target_data[i]
			end
		end
	end

	return t --targets
end

local function buff_value(battle, targets, state_key, key_dic, value, sub_key)
	--print('buff!')
	--TableFunc.Dump(value)
	local t = TableFunc.DeepCopy(value)
	local sub_key = sub_key and sub_key or math.huge
	local state_t = {}
	--local is_dic = TableFunc.IsDictionary(t[#t])

	if #targets > 0 then
		local StateHandler = require('battle.StateHandler')

		for target_index, target in pairs(targets) do
			--TableFunc.Dump(targets)
			--print('buff value target index', target.data.team_index, state_key)
			local state_table = target.state[state_key]
			local final_value --= t[k]and t[k] or t[#t]

			if #state_table > 0 then
				--print('buffValue')
				--TableFunc.Dump(t)

				for i, state in pairs(state_table) do
					if state.name ~= sub_key then
						TableFunc.Push(state_t, { target = target, state_key = state_key, state_name = state.name }) --記錄要update
						--print(target.key .. ' have state', state.name)
						local res = _G.Resource.state[state.name]
						--TableFunc.Dump(state)
						if res.effect_number == 'multi' then
							final_value = t
							--print('is multi')
						else
							final_value = t[target_index] and t[target_index] or t[#t]
						end
						StateHandler.Excute(battle, target, state, key_dic, final_value)
					end
				end

				local pop_value = TableFunc.Pop(StateHandler.machine.stack)

				if type(final_value) == "table" then
					--print('final_value value is table', pop_value)
					if type(pop_value) == 'table' and not TableFunc.IsDictionary(pop_value) then
						for index, v in pairs(t) do
							t[index] = pop_value[index] and pop_value[index] or pop_value[#pop_value]
						end
					else
						for index, v in pairs(t) do
							t[index] = pop_value
						end
					end
				elseif pop_value ~= nil then
					--print('final_value not table')
					t[target_index] = pop_value
				end
			end
		end
	end
	return t, state_t
end

complex_command.preview = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	local value          = { ... }
	local key            = StringDecode.Trim(TableFunc.Shift(value))
	local t, state_t
	--print('preview', key)
	--TableFunc.Dump(value)
	if CC_ACT[key] then
		t = CC_ACT[key](battle, machine, value)
	else
		t = CC_T[key](battle, machine, value)
	end

	local target_string = TableFunc.Shift(value)

	if CC_T[key] then
		--print('have CC_T', key)
		--TableFunc.Dump(value)
		local is_dic = t.key:find('buff') and true or nil
		if is_dic then
			value = { t.dic }
			t.dic = nil
		end
		t.state_update = {}
		SCMachine:ReadEffect(battle, target_string, key_dic)
		local targets = TableFunc.Pop(SCMachine.stack)
		--TableFunc.Dump(targets)
		if TableFunc.IsDictionary(targets) then targets = { targets } end
		t.target = targets

		--[[for key, value in pairs(targets) do
			print('serial', value.serial)
		end]]
		if #targets > #value then --讓value 根據 target數量 保持一至
			--print('#targets ~= #value')
			for index, target in pairs(targets) do
				value[index] = value[index] and value[index] or value[#value]
			end
			--TableFunc.Dump(value)
		end

		--print('t.target ', targets)
		if t and t.protect then
			--print('check_protect', targets)
			--TableFunc.Dump(targets)
			targets = check_protect(targets, battle, t)
			t.target = targets
			key_dic.target_table = targets
		end
		if t and t.value_state then
			--print('t', t.key, t.sub_key)
			for k, v in pairs(t.value_state) do
				local target_string, state_table_string = v[1], v[2]

				SCMachine:ReadEffect(battle, target_string, key_dic)
				targets = TableFunc.Pop(SCMachine.stack)
				--print('Ready to buff value', target_string, #targets)
				--TableFunc.Dump(value)
				value, state_t = buff_value(battle, targets, state_table_string, key_dic, value, t.sub_key) --target_string
				--print('mapping', mapping)
				--TableFunc.Dump(mapping)
				for i, s in pairs(state_t) do
					TableFunc.Push(t.state_update, s)
				end
			end
		end

		--print('preview value len', #value)
		for k, v in pairs(value) do
			if t and t.value_decrease then
				value[k] = '(' .. v .. ') * ' .. t.value_decrease
			end
		end

		t.value_state = nil
		t.value = value

		--print('preview value')
		--TableFunc.Dump(t)

		--t.state_update=state_update
		local final_process = require('battle.command_act.final_process')
		if final_process[t.key] then
			final_process[t.key](battle, machine, t)
		end
	end
	return t
end
complex_command.protect = function(battle, machine, ...)
	local t = {
		key = 'protect',
	}
	SCMachine.stack = TableFunc.DeepCopy(machine.stack)
	local target, value = ...
	SCMachine:ReadEffect(battle, target, machine.key_dic)
	local targets = TableFunc.Pop(SCMachine.stack)
	machine.key_dic.target_table = targets

	for k, target in pairs(targets) do
		local state_table = target.state.protect
		if #state_table > 0 then
			TableFunc.Pop(state_table)
			TableFunc.Push(state_table, machine.key_dic.card.holder)
		end
	end
	return t
end
complex_command.push = function(battle, machine, ...)
	local target, value = ...
	SCMachine:ReadEffect(battle, target, machine.key_dic)
	local targets = TableFunc.Pop(SCMachine.stack)
	local race = TableFunc.Find(battle.characterData.heroData) and battle.characterData.heroData or
		battle.characterData.monsterData

	for i = #targets, 1, -1 do
		local target = targets[i]
		for j = 1, value do
			local index = target.data.team_index
			if index + 1 <= #race then
				target.data.team_index = index + 1
				race[index + 1].data.team_index = index
				TableFunc.Swap(race, index, index + 1)
			end
		end
	end
end
complex_command.pull = function(battle, machine, ...)
	local target, value = ...
	SCMachine:ReadEffect(battle, target, machine.key_dic)
	local targets = TableFunc.Pop(SCMachine.stack)
	local race = TableFunc.Find(battle.characterData.heroData) and battle.characterData.heroData or
		battle.characterData.monsterData

	for i = 1, #targets do
		local target = targets[i]
		for j = 1, value do
			local index = target.data.team_index
			if index - 1 >= 1 then
				target.data.team_index = index - 1
				race[index - 1].data.team_index = index
				TableFunc.Swap(race, index, index - 1)
			end
		end
	end
end



return complex_command
