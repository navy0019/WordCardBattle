local StringRead             = require('lib.StringRead')
local StringDecode           = require('lib.StringDecode')
local MathExtend             = require('lib.math')
local TableFunc              = require('lib.TableFunc')

local Simple_Command_Machine = require('battle.SimpleCommandMachine')
local SCMachine              = Simple_Command_Machine.NewMachine()


local final_process = {}

local function state_trigger_update(battle, targets, holder, info)
	local StateHandler = require('battle.StateHandler')
	local map = { target = targets, holder = holder }

	for k, v in pairs(info.state_update) do
		local state_table = v.target.state[v.state_key]
		for i, state in pairs(state_table) do
			if state.name == v.state_name then
				StateHandler.Update(battle, v.target, state, v.state_key, 'trigger')
			end
		end
	end
end

final_process.set_value = function(battle, machine, ...)
	local StateHandler   = require('battle.StateHandler')
	local info           = ...

	local targets, value = info.target, info.value
	local key, limit     = table.unpack(info.sub_key)
	--print('final_process set_value', targets, value)
	local final_value
	--SCMachine:ReadEffect(battle ,target , machine.key_dic )
	--local targets =TableFunc.Pop(SCMachine.stack)
	--print('set_value targets ',targets ,#targets)
	if not TableFunc.IsArray(targets) then targets = { targets } end

	SCMachine:ReadEffect(battle, 'holder', machine.key_dic)
	local holder = TableFunc.Pop(SCMachine.stack)
	state_trigger_update(battle, targets, holder, info)

	for k, target in pairs(targets) do
		local current_value = value[k] and value[k] or value[#value]
		current_value = StringRead.StrToValue(current_value, machine.key_dic, battle, k)
		--CC_ACT['calculate_value'](battle, machine, { target.data[key], current_value, limit })
		--local final_value = TableFunc.Pop(machine.stack)
		local min, max
		if limit then
			min, max = StringDecode.Split_by(limit, '~')

			if tonumber(min) then
				min = tonumber(min)
			else
				min = StringRead.StrToValue(min, machine.key_dic, battle)
			end
			if tonumber(max) then
				max = tonumber(max)
			else
				max = StringRead.StrToValue(max, machine.key_dic, battle)
			end
			--print('min~max',min ,max)
			final_value = MathExtend.clamp(target.data[key] + current_value, min, max)
		else
			final_value = target.data[key] + current_value
		end


		target.data[key] = final_value
	end
end
final_process.set_hp_value = function(battle, machine, ...)
	local StateHandler   = require('battle.StateHandler')
	local info           = ...
	local final_target, temp_hp

	--print('final_process set_hp_value')
	local targets, value = info.target, info.value
	if info.mapping then
		machine.key_dic.mapping = info.mapping
	end
	--SCMachine:ReadEffect(battle ,target , machine.key_dic )
	--local targets =TableFunc.Pop(SCMachine.stack)
	--print('set_value targets ',targets ,#targets)
	if not TableFunc.IsArray(targets) then targets = { targets } end

	SCMachine:ReadEffect(battle, 'holder', machine.key_dic)
	local holder = TableFunc.Pop(SCMachine.stack)

	--print('targets',targets ,holder)
	state_trigger_update(battle, targets, holder, info)

	for k, target in pairs(targets) do
		local current_value = value[k] and value[k] or value[#value]
		if tonumber(current_value) then
			current_value = tonumber(current_value)
		else
			current_value = StringRead.StrToValue(current_value, machine.key_dic, battle, k)
			--print('current_value', current_value)
		end
		final_target = target
		--print('set_hp_value ', final_target.data.team_index, current_value, type(current_value))
		temp_hp = final_target.data.hp --辨認target 是否有受到傷害
		if info.shield then
			final_target.data.shield = final_target.data.shield + current_value

			if final_target.data.shield < 0 then
				final_target.data.hp = MathExtend.clamp(final_target.data.hp + final_target.data.shield, 0,
					final_target.data.max_hp)
				final_target.data.shield = 0
			end
		else
			final_target.data.hp = MathExtend.clamp(final_target.data.hp + current_value, 0, final_target.data.max_hp)
			--print('no shield',final_target.data.hp )
		end


		if final_target.data.hp <= 0 then
			local state_table = final_target.state['dead']
			for i, state in pairs(state_table) do
				StateHandler.Excute(battle, final_target, state, machine.key_dic, holder) --target
				StateHandler.Update(battle, final_target, state, 'dead')
			end
		elseif final_target.data.hp < temp_hp then
			local state_table = final_target.state['injure']
			for i, state in pairs(state_table) do
				StateHandler.Excute(battle, final_target, state, machine.key_dic, holder) --target
				StateHandler.Update(battle, final_target, state, 'injure')
			end
		end
	end
end
final_process.add_buff = function(battle, machine, ...)
	local StateHandler = require('battle.StateHandler')
	--print('ADD BUFF')
	local info         = ...
	local targets      = info.target
	--TableFunc.Dump(info.value)
	SCMachine:ReadEffect(battle, 'holder', machine.key_dic)
	local holder = TableFunc.Pop(SCMachine.stack)
	state_trigger_update(battle, targets, holder, info)
	--TableFunc.Dump(holder)


	for index, target in ipairs(targets) do
		local t = info.value[index] and info.value[index] or info.value[#info.value]
		--print('info value ', TableFunc.IsDictionary(t))
		--TableFunc.Dump(t)
		local s = ''
		for key, v in pairs(t) do
			--print('mix',key ,v)
			s = s .. key .. ':' .. v .. ','
		end
		s = s:sub(1, #s - 1) --去除最後的逗號

		local key = info.sub_key .. '(' .. s .. ')'
		--print('ADD BUFF', key, target.key)
		local current = holder[index] and holder[index] or holder[#holder]
		local serial = TableFunc.GetSerial(current)
		local caster = current.data.race .. ' ' .. serial
		StateHandler.AddBuff(battle, target, key, caster, machine.key_dic)
		for i, result in ipairs(StateHandler.machine.result) do
			local nr = result
			if TableFunc.IsDictionary(result) then nr = { result } end
			TableFunc.Push(machine.result, nr)
		end
	end
end
final_process.assign_value = function(battle, machine, ...)
	--print('ASSIGN VALUE')
	local info         = ...
	local targets, key = info.target, info.sub_key
	--print('assign_value targets', #targets)
	for index, target in ipairs(targets) do
		local value = info.value[index] and info.value[index] or info.value[#info.value]
		--print(target.data.team_index, value)
		value = StringRead.StrToValue(value, machine.key_dic, battle)

		target.data[key] = value
	end
end
--[[final_process.protect = function(battle, machine, ...)
end]]
return final_process
