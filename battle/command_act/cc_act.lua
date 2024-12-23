local TableFunc              = require('lib.TableFunc')
local StringDecode           = require('lib.StringDecode')
local StringRead             = require('lib.StringRead')
local MathExtend             = require('lib.math')

local Simple_Command_Machine = require('battle.SimpleCommandMachine')
local SCMachine              = Simple_Command_Machine.NewMachine()

local cc_act                 = {

	condition = function(battle, machine, ...)
		local Complex_Command_Machine = require('battle.ComplexCommandMachine')
		local CCMachine = Complex_Command_Machine.NewMachine()
		local con_arg = ...
		local arg = StringDecode.TransToDic(con_arg)
		local bool_target, t = {}, {}

		local stack, key_dic = machine.stack, machine.key_dic
		local condition = Simple_Command_Machine.Trim_To_Simple_Command(key_dic.card.condition)
		--print('condition',TableFunc.Dump(condition))
		SCMachine:ReadEffect(battle, condition, key_dic)
		local result = TableFunc.Pop(SCMachine.stack)
		for k, v in pairs(result) do
			if type(v) ~= 'boolean' then
				result[k] = tonumber(result[k]) > 0 and true or false
			end
		end

		for k, v in pairs(result) do
			local bool = tostring(v)
			if arg[bool] and #result > 1 then
				local command = arg[bool]
				local target_string = command:match('(%a+)$')
				local new_target = target_string

				if not target_string:find('%(') then
					new_target = target_string .. '(' .. k .. ')'
				end

				command = command:gsub(target_string, new_target)
				--print('condition command', ,command)
				SCMachine:ReadEffect(battle, new_target, key_dic)
				local target = TableFunc.Pop(SCMachine.stack)
				local temp_key_link = TableFunc.ShallowCopy(key_dic)
				temp_key_link.target_table = target

				CCMachine:ReadEffect(battle, command, temp_key_link) --
				local result = TableFunc.Pop(CCMachine.result)
				--print('result',command)
				--TableFunc.Dump(result)

				if TableFunc.IsDictionary(result) then
					TableFunc.Push(t, result)
				end
				--print('t',t)
				--TableFunc.Dump(t)
			elseif arg[bool] then
				--print('bool type 2 :',bool  )
				local command = arg[bool]
				CCMachine:ReadEffect(battle, command, key_dic)
				t = TableFunc.Pop(CCMachine.result)
			end
		end
		return t
	end,
	calculate_value = function(battle, machine, ...)
		local arg = ...
		--print('calculate_value', arg)
		--TableFunc.Dump(arg)
		SCMachine.stack = machine.stack
		local target_string, value = table.unpack(arg)
		local copy_value = machine.stack[#machine.stack]

		if tonumber(value) and tonumber(value) >= 0 and not StringDecode.Find_calculate_symbol(tostring(value)) then
			value = "+" .. tostring(value)
		end

		if target_string:find('value') then
			SCMachine:ReadEffect(battle, target_string, machine.key_dic)
			local target_entity = TableFunc.Pop(SCMachine.stack)
			--print('target_string is value', target_string, value)
			--TableFunc.Dump(target_entity)
			if type(target_entity) == 'table' then
				for index, v in pairs(target_entity) do
					target_entity[index] = '(' .. target_entity[index] .. ')' .. value
					--print('is value', target_entity[index])
				end
			else
				target_entity = '(' .. target_entity .. ')' .. value
			end
			--print('is value', target_entity)
			--TableFunc.Dump(target_entity)
			--machine.key_dic.for_mapping = target_entity
			TableFunc.Unshift(machine.stack, target_entity)
		else
			local s = '(' .. target_string .. ')' .. value
			--print('not value', s)

			TableFunc.Unshift(machine.stack, s)
		end
		if target_string:find('%.') then
			local t = { StringDecode.Split_by(target_string, '%.') }
			local last_key = TableFunc.Pop(t)
			local s = ''
			for key, value in pairs(t) do
				if key > 1 then
					s = s .. '.' .. value
				else
					s = s .. value
				end
			end
			TableFunc.Push(machine.stack, copy_value)
			SCMachine:ReadEffect(battle, s, machine.key_dic)
			local target_entity = TableFunc.Pop(SCMachine.stack)

			local value = TableFunc.Pop(machine.stack)
			target_entity[last_key] = value
			--print('find .', target_entity)
			--TableFunc.Dump(target_entity)
			TableFunc.Unshift(machine.stack, target_entity)
		end
		--print('calculate_value', target_string .. value, machine.key_dic)
		--TableFunc.Unshift(machine.stack, '(' .. target_string .. value .. ')')
	end,

}

return cc_act
