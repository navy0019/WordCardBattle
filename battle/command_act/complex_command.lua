local TableFunc              = require('lib.TableFunc')
local StringDecode           = require('lib.StringDecode')
local StringRead             = require('lib.StringRead')

local Simple_Command_Machine = require('battle.SimpleCommandMachine')
local SCMachine              = Simple_Command_Machine.NewMachine()

local CC_T                   = require('battle.command_act.cc_t')
local CC_ACT                 = require('battle.command_act.cc_act')
--local final_process = require('battle.command_act.final_process')

local complex_command        = {}
--TableFunc.Merge(complex_command,final_process)

local function check_protect(targets, battle, info)
	local StateHandler = require('battle.StateHandler')
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
	--[[for key, value in pairs(t) do
		print('check protect ',value.data.team_index)
	end]]
	return t --targets
end

local function buff_value(battle, targets, state_key, key_link, value, is_dic)
	local t = {}
	local state_t = {}
	--print('buff_value is_dic ',is_dic)
	--讓value 根據 target數量 保持一至
	if type(value) ~= 'table' then
		--if is_dic then
		for i = 1, #targets do
			TableFunc.Push(t, value)
		end
		--print('value is not table')
	elseif #value ~= #targets then
		for i = 1, #targets do
			local nv
			if TableFunc.IsDictionary(value) then
				nv = value
			else
				nv = value[i] and value[i] or value[#value]
			end
			TableFunc.Push(t, nv)
		end
		--print('length diff')
		--TableFunc.Dump(value)
		--TableFunc.Dump(t)
	else
		--print('length is same')
		t = TableFunc.DeepCopy(value)
	end

	--print('buff_value target number',#targets)
	--TableFunc.Dump(t)

	if #targets > 0 then
		local StateHandler = require('battle.StateHandler')
		--print('targets > 0',#targets)

		for k, target in pairs(targets) do
			--TableFunc.Dump(targets)
			--print('buff value target index',target.data.team_index ,state_key)
			local state_table = target.state[state_key]
			local final_value --= t[k]and t[k] or t[#t]

			if #state_table > 0 then
				TableFunc.Push(state_t, { target = target, state_key = state_key })
				for i, state in pairs(state_table) do
					--print(target.key..' have state',state.name)
					if state.effect_number == 'multi' then
						final_value = t
					else
						final_value = t[k] and t[k] or t[#t]
					end
					StateHandler.Excute(battle, target, state, key_link, final_value)
				end
				local pop_value = TableFunc.Pop(StateHandler.machine.stack)

				--TableFunc.Push(t,final_value)
				--t[k]=final_value
				if type(pop_value) == 'table' then
					--print('pop_value is table')
					TableFunc.Dump(pop_value)
					t = pop_value
				else
					--t= final_value
					--print('single value index',k)
					t[k] = pop_value
				end
			else
				--print('enter else')
				local index = k <= #t and k or #t
				--print('else index',index)
				final_value = t[index]
				--print('buff_value else',final_value)
				--TableFunc.Dump(final_value)
				if not tonumber(final_value) and not is_dic then
					--print(target.team_index..' '..state_key..' is empty',final_value)					
					t[index] = StringRead.StrToValue(final_value, key_link, battle)
				elseif tonumber(final_value) then
					t[index] = tonumber(final_value)
				else
					--print('t[index]',index)
					t[index] = final_value
				end
			end
		end
	end
	return t, state_t
end

complex_command.preview = function(battle, machine, ...)
	local stack, key_link = machine.stack, machine.key_link
	local value           = { ... }
	local key             = TableFunc.Shift(value)
	local t, state_t

	--print('preview',key )
	--TableFunc.Dump(value)
	if CC_ACT[key] then
		t = CC_ACT[key](battle, machine, value)
	else
		t = CC_T[key](battle, machine, value)
	end
	--TableFunc.Dump(t)
	local target_string = TableFunc.Shift(value)
	--print('preview target_string',target_string)
	--TableFunc.Dump(stack)
	--TableFunc.Dump(value)


	if CC_T[key] then
		local is_dic = t.key:find('buff') and true or nil
		if is_dic then
			value = { t.dic }
			t.dic = nil
		end
		t.state_update = {}
		SCMachine:ReadEffect(battle, target_string, key_link)
		--print('preview target_string',target_string)
		local targets = TableFunc.Pop(SCMachine.stack)
		--[[for key, value in pairs(targets) do
			print('target ',value.data.team_index)
		end]]
		if TableFunc.IsDictionary(targets) then targets = { targets } end
		t.target = targets

		if t and t.protect then
			targets = check_protect(targets, battle, t)
			t.target = targets
			key_link.target_table = targets
		end
		if t and t.value_state then
			for k, v in pairs(t.value_state) do
				local target_string, state_table_string = v[1], v[2]

				SCMachine:ReadEffect(battle, target_string, key_link)
				targets = TableFunc.Pop(SCMachine.stack)

				--if not t.key:find('buff') then
				value, state_t = buff_value(battle, targets, state_table_string, key_link, value, is_dic) --target_string
				--[[else
					value ,state_t = buff_dic_value(battle ,targets ,state_table_string ,key_link ,value)
				end]]

				for i, s in pairs(state_t) do
					TableFunc.Push(t.state_update, s)
				end
			end
		end

		for k, v in pairs(value) do
			if t and t.value then
				value[k] = '(' .. v .. ') * ' .. t.value
			end

			if value[k] == 'true' then
				value[k] = true
			elseif value[k] == 'false' then
				value[k] = false
			elseif not tonumber(value[k]) and not is_dic then
				--print('value[k] ',value[k],type(value[k]))
				value[k] = StringRead.StrToValue(value[k], key_link, battle)
			end
		end
		--[[print('preview have key ',key,value)
		TableFunc.Dump(value)
		for key, value in pairs(t.target) do
			print('target ',value.data.team_index)
		end]]
		--TableFunc.Dump(stack)
		t.value_state = nil
		t.value = value
		--t.state_update=state_update
	end
	--print('preview final' ,key )
	--TableFunc.Dump(t)
	--TableFunc.Dump(stack)
	return t
end
complex_command.protect = function(battle, machine, ...)
	local t = {
		key = 'protect',
	}
	SCMachine.stack = TableFunc.DeepCopy(machine.stack)
	local target, value = ...
	SCMachine:ReadEffect(battle, target, machine.key_link)
	targets = TableFunc.Pop(SCMachine.stack)
	machine.key_link.target_table = targets

	for k, target in pairs(targets) do
		local state_table = target.state.protect
		if #state_table > 0 then
			TableFunc.Pop(state_table)
			TableFunc.Push(state_table, machine.key_link.card.holder)
		end
	end
	return t
end
complex_command.push = function(battle, machine, ...)
	local target, value = ...
	SCMachine:ReadEffect(battle, target, machine.key_link)
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
	SCMachine:ReadEffect(battle, target, machine.key_link)
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

--[[complex_command.assign_value=function(battle,machine,...)
	local bool_map={}
	bool_map["true"]	=true
	bool_map["false"]	=false
	local  target_string ,value ,key = ...
	--print('assign_value ,key ',value ,key)
	SCMachine:ReadEffect(battle ,target_string , machine.key_link )
	local targets = TableFunc.Pop(SCMachine.stack)
	for k,target in pairs(targets) do
		if tonumber(value) then
			target.data[key] = tonumber(value)
		elseif bool_map[value] then
			target.data[key] = bool_map[value]
		else
			target.data[key] = value
		end
	end


end]]



return complex_command
