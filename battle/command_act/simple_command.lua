local TableFunc      = require('lib.TableFunc')
local StringDecode   = require('lib.StringDecode')

local map            = {
	compare = { '>=', '<=', '==', '>', '<' },

}
local simple_command = {}
local function excute_arg(battle, command, key_dic)
	local Simple_Command_Machine = require('battle.SimpleCommandMachine')
	local machine = Simple_Command_Machine.NewMachine()
	machine:ReadEffect(battle, command, key_dic)
	local result = TableFunc.Pop(machine.stack)
	--print(result ,#result)
	return result
end
local function findSymbol(str, tab_name)
	for k, v in pairs(map[tab_name]) do
		if str:find(v) then
			return k
		end
	end
end
local function group_with_condition(data, act)
	local Simple_Command_Machine = require('battle.SimpleCommandMachine')

	local act = act
	local machine = Simple_Command_Machine.NewMachine()
	local t = {}
	local key = act[1]:match("[^%.]*$")
	--key = act:match("[^%.]*$")
	--print('group_with_condition',act[1],key)
	--TableFunc.Dump(act)

	machine.stack = { data }
	machine:ReadEffect({}, act, {}) --battle

	local result = TableFunc.Pop(machine.stack)
	if type(result) == 'table' then
		for k, v in pairs(result) do
			if v then
				TableFunc.Push(t, data[k])
			end
		end
	elseif type(result) == 'number' then
		for i, j in pairs(data) do
			if j.data[key] == result then
				TableFunc.Push(t, data[i])
				break
			end
		end
	end

	return t
end
local function get_group(data, stack, t)
	--print('get_group ' ,t)
	--TableFunc.Dump(t)
	local group = {}
	if type(t) == 'number' then
		if data[t] then
			--print('data[i]')
			TableFunc.Push(group, data[t])

			--print('push data ',data[num] ,#stack)
		else
			--print('data[i] is empty')
			group = data[#data] and data[#data] or {}
		end
	else
		--print('not number',t)
		group = group_with_condition(data, t)
	end
	--TableFunc.Dump(group)
	return group
end

local function transArgToCommand(arg) --key
	--print('transArgToCommand ')
	--TableFunc.Dump(arg)
	local t = {}
	for k, v in pairs(arg) do
		if not tonumber(v) then
			--print('transArgToCommand ',v)
			if not v:find('state') then
				local symbol = v:match('[>=<:]+')
				--print('symbol',symbol)
				local compare, index, command, p1, p2

				if #symbol > 1 then
					p1, p2 = v:find(symbol)
					--compare = v:sub(p2+1 ,#v)
				else
					--print('single symbol')
					p1 = v:find(symbol)
					p2 = p1
					--compare = v:sub(p2 ,#v)
				end
				--key:gsub(key:match('%a*'),'')	
				compare = v:sub(p2 + 1, #v)
				index = v:sub(1, p1 - 1) --key:match('%a*')
				--print('symbol',symbol ,compare)

				if not symbol:find(':') or #symbol > 1 then
					command = 'get ' .. 'data.' .. index .. ' , ' .. symbol .. compare
				else
					command = 'get ' .. 'data.' .. index .. ' , ' .. compare
				end


				local split = { StringDecode.Split_by(command, ',') }
				--print('transToCommand ',command ,split)
				TableFunc.Push(t, split)
			elseif v:find('state') then
				local p = v:find(':')
				local arg = v:sub(p + 1, #v)
				local command = 'find_state(' .. arg .. ')'
				TableFunc.Push(t, { command })
				--print('find state',command)
			end
		else
			local number = tonumber(v)
			TableFunc.Push(t, number)
		end
	end

	return t
end

simple_command.get = function(battle, machine, ...)
	local arg            = { ... }
	local key            = TableFunc.Shift(arg)
	local stack, key_dic = machine.stack, machine.key_dic
	local target         = TableFunc.Pop(stack)
	--print('SCM get',key)
	--TableFunc.Dump(target)
	local t              = {}

	if key:find('%.') then
		local nextkey = key:sub(key:find('%.') + 1, #key)
		key = key:sub(1, key:find('%.') - 1)
		for k, v in pairs(target) do
			TableFunc.Push(t, v[key])
		end
		TableFunc.Push(stack, t)
		simple_command.get(battle, machine, nextkey)
	elseif TableFunc.IsArray(target) then
		for k, v in pairs(target) do
			TableFunc.Push(t, v[key])
		end
		TableFunc.Push(stack, t)
	else
		TableFunc.Push(stack, target[key])
	end
end

simple_command.enemy = function(battle, machine, ...)
	local data           = TableFunc.ShallowCopy(battle.characterData.monsterData)
	local arg            = { ... }
	local stack, key_dic = machine.stack, machine.key_dic

	local t              = transArgToCommand(arg)

	if #t <= 0 then
		TableFunc.Push(stack, data)
		return
	else
		for k, v in pairs(t) do
			data = get_group(data, stack, v)
		end
		TableFunc.Push(stack, data)
	end
end
simple_command.hero = function(battle, machine, ...)
	local data           = TableFunc.ShallowCopy(battle.characterData.heroData)
	local arg            = { ... }
	local stack, key_dic = machine.stack, machine.key_dic

	local t              = transArgToCommand(arg)

	if #t <= 0 then
		TableFunc.Push(stack, data)
		return
	else
		for k, v in pairs(t) do
			data = get_group(data, stack, v)
		end
		TableFunc.Push(stack, data)
	end
end
simple_command.target = function(battle, machine, ...)
	local arg            = { ... }
	local stack, key_dic = machine.stack, machine.key_dic
	--local target 		=TableFunc.Pop(stack)

	local data
	if key_dic.target_table then
		data = TableFunc.ShallowCopy(key_dic.target_table)
		local t = transArgToCommand(arg)
		--print('SCM target')
		--TableFunc.Dump(data)
		if #t <= 0 then
			--print('SCM target')
			TableFunc.Push(stack, data)
			return
		else
			for k, v in pairs(t) do
				data = get_group(data, stack, v)
			end
			TableFunc.Push(stack, data)
		end
	else
		--print('target is empty')
		TableFunc.Push(stack, {})
	end
end

simple_command.compare = function(battle, machine, ...)
	local func = {
		function(a, b) return a >= b end,
		function(a, b) return a <= b end,
		function(a, b) return a == b end,
		function(a, b) return a > b end,
		function(a, b) return a < b end
	}
	local arg = { ... }
	--print('compare arg')
	--TableFunc.Dump(arg)
	local key_dic = machine.key_dic
	local stack = machine.stack
	local key = arg[1]
	local value = TableFunc.Pop(stack)

	local a = tonumber(value) and tonumber(value) or value
	local b = tonumber(arg[2]) and tonumber(arg[2]) or arg[2]


	if type(b) == 'string' then
		b = excute_arg(battle, b, key_dic)
	end
	--print('compare', a, b)
	--TableFunc.Dump(a)
	--TableFunc.Dump(b)

	local index = findSymbol(key, 'compare')
	local t = {}

	if type(a) == 'table' and type(b) == 'table' then
		local max = #a > #b and a or b
		local other = #a < #b and a or b
		for k, v in pairs(max) do
			if other[k] then
				local value = func[index](max[k], other[k])
				TableFunc.Push(t, value)
			else
				local value = func[index](max[k], other[#other])
				TableFunc.Push(t, value)
			end
		end
		TableFunc.Push(stack, t)
	elseif type(a) == 'number' and type(b) == 'number' then
		TableFunc.Push(stack, func[index](a, b))
	elseif (type(a) == 'number' and type(b) == 'table') or (type(a) == 'table' and type(b) == 'number') then
		--print(a,b)
		local tab = type(a) == 'table' and a or b
		local num = type(a) == 'number' and a or b
		for k, v in pairs(tab) do
			--TableFunc.Dump(v)
			local parameter = type(a) == 'number' and { num, v } or { v, num }
			local value = func[index](table.unpack(parameter))
			TableFunc.Push(t, value)
		end
		TableFunc.Push(stack, t)
	end
end
simple_command.card = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	TableFunc.Push(stack, key_dic.card)
end
simple_command.self = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	assert(key_dic.self, 'key_dic don\'t have key \"self\"')
	TableFunc.Push(stack, key_dic.self)
end
simple_command.holder = function(battle, machine, ...) --取得card 或state 的持有者
	local stack, key_dic = machine.stack, machine.key_dic
	local holder
	--print('get holder', key_dic.card, key_dic.self)
	--TableFunc.Dump(key_dic)
	local function serial_to_character(str)
		local type, serial = StringDecode.Split_by(str, '%s')
		local tab = type == 'hero' and battle.characterData.heroData or battle.characterData.monsterData
		local index = TableFunc.MatchSerial(tab, serial)
		return tab[index]
	end
	if key_dic.self.holder then
		assert(type(key_dic.self.holder) == 'string', 'holder\'s data type not string')
		holder = serial_to_character(key_dic.self.holder)
	elseif key_dic.holder then
		assert(type(key_dic.holder) == 'string', 'holder\'s data type not string')
		holder = serial_to_character(key_dic.holder)
	elseif key_dic.self.data and key_dic.self.data.holder then
		assert(type(key_dic.self.data.holder) == 'string', 'holder\'s data type not string')
		holder = serial_to_character(key_dic.self.data.holder)
	elseif key_dic.card then
		assert(type(key_dic.card.holder) == 'string', 'holder\'s data type not string')
		holder = serial_to_character(key_dic.card.holder)
	else
		assert(nil, 'data don\'t have holder')
	end
	--print('holder')
	--TableFunc.Dump(holder)
	TableFunc.Push(stack, { holder })
	--[[if holder.data.hp > 0 then
		TableFunc.Push(stack ,holder)
	else
		TableFunc.Push(stack ,{})
	end]]
end
simple_command.caster = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	TableFunc.Push(key_dic.self.caster)
end

simple_command.max = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	local t = TableFunc.Pop(stack)
	local current = 1
	local compare_value = t[1]
	for k, v in pairs(t) do
		compare_value = math.max(compare_value, v)
	end
	TableFunc.Push(stack, compare_value)
end
simple_command.min = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	local t = TableFunc.Pop(stack)
	local current = 1
	local compare_value = t[1]
	for k, v in pairs(t) do
		compare_value = math.min(compare_value, v)
	end
	TableFunc.Push(stack, compare_value)
end
simple_command.value = function(battle, machine, ...)
	local stack, key_dic = machine.stack, machine.key_dic
	--print('SCM value?', #stack, key_dic)
	--TableFunc.Dump(stack)
	--local value=TableFunc.Pop(stack)
	--[[if key_dic.mapping then
		--print('key_dic have value')
		--TableFunc.Dump(key_dic.mapping)
		TableFunc.Push(stack, key_dic.mapping)
	end]]
end
simple_command.random = function(battle, machine, ...)
	local StringRead = require('lib.StringRead')
	_G.RandomMachine:Set_seed(_G.RandomMachine.seed)
	local arg = { ... }
	--print('random')
	--TableFunc.Dump(arg)
	local key_dic, stack, effect = machine.key_dic, machine.stack, machine.effect

	local num = TableFunc.Shift(arg)

	if not num:find('~') and num:find('%.') then
		num = StringRead.StrToValue(num, key_dic, battle)
	elseif num:find('~') and num:find('%.') then
		local dot = num:find('%.')
		local tilde = num:find('~')
		local dot_str
		--print('find dot & tilde')
		if dot > tilde then
			dot_str = num:sub(tilde + 1, #num)
			--print('dot_str', dot_str)
			local value = StringRead.StrToValue(dot_str, key_dic, battle)
			num = StringDecode.Gsub_by_index(num, value, tilde + 1, #num)
		else
			dot_str = num:sub(1, tilde - 1)
			--print('dot_str', dot_str)
			local value = StringRead.StrToValue(dot_str, key_dic, battle)
			num = StringDecode.Gsub_by_index(num, value, 1, tilde - 1)
		end
	end
	--print('num', num)
	local obj_string = TableFunc.Shift(arg)

	if tonumber(num) and not obj_string then
		num = tonumber(num)
		num = _G.RandomMachine:Random(num)
		--print('random num',num)
		TableFunc.Push(machine.stack, num)
	elseif num:find('~') and not obj_string then
		local a, b = StringDecode.Split_by(num, '~')

		if a:find('%.') then
			a = StringRead.StrToValue(a, key_dic, battle)
		end
		if b:find('%.') then
			b = StringRead.StrToValue(b, key_dic, battle)
		end
		a, b = tonumber(a), tonumber(b)

		local min = a < b and a or b
		local max = a > b and a or b
		num = _G.RandomMachine:Random(min, max)
		--print('random ~ ', num)
		TableFunc.Push(machine.stack, num)
	elseif tonumber(num) and obj_string then
		local effect = obj_string --and {obj..' '..obj_arg} or{obj}
		--print('random arg ', tonumber(num), effect)
		local result = excute_arg(battle, effect, key_dic)
		local t = {}
		if #result > 0 then
			--print('#result', #result)
			for i = 1, num do
				local ran = _G.RandomMachine:Random(#result)
				_G.RandomMachine:New_seed()
				--print('RandomMachine target ', ran)
				TableFunc.Push(t, result[ran])
			end
			TableFunc.Push(machine.stack, t)
		else
			TableFunc.Push(machine.stack, t)
		end
	elseif num:find('~') and obj_string then
		local a, b = StringDecode.Split_by(num, '~')
		if a:find('%.') then
			a = StringRead.StrToValue(a, key_dic, battle)
		end
		if b:find('%.') then
			b = StringRead.StrToValue(b, key_dic, battle)
		end
		a, b = tonumber(a), tonumber(b)

		local min = a < b and a or b
		local max = a > b and a or b
		num = _G.RandomMachine:Random(min, max)

		local effect = obj_string --and {obj..' '..obj_arg} or{obj}				
		local result = excute_arg(battle, effect, key_dic)
		local t = {}
		if #result > 0 then
			for i = 1, num do
				local ran = _G.RandomMachine:Random(#result)
				_G.RandomMachine:New_seed()
				TableFunc.Push(t, result[ran])
			end
			TableFunc.Push(machine.stack, t)
		else
			TableFunc.Push(machine.stack, t)
		end
	end
end
simple_command.find_state = function(battle, machine, ...)
	local arg            = ...
	local stack, key_dic = machine.stack, machine.key_dic
	local target         = TableFunc.Pop(stack)
	local t              = {}
	for k, obj in pairs(target) do
		for i, state_table in pairs(obj.state) do
			if TableFunc.Find(state_table, arg, 'name') then
				TableFunc.Push(t, obj)
				break
			end
		end
	end
	--print('find_state')
	TableFunc.Push(stack, t)
end
return simple_command
