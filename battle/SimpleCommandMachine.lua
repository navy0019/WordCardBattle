local StringDecode = require('lib.StringDecode')
local TableFunc = require('lib.TableFunc')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Basic_act = require('battle.command_act.simple_command')
--local Combine_act = require('lib.command_act.combine_act')
--local Deck_act = require('battle.command_act.deck_act')
--TableFunc.Merge(Basic_act,Combine_act)
--TableFunc.Merge(Basic_act,Deck_act)

--local universal_func = require('lib.command_act.universal_func')


local Simple_Command_Machine = {}
function Simple_Command_Machine.Trim_To_Simple_Command(str)
	local split = { StringDecode.Split_by(str, '%s') }
	--print(str)
	--TableFunc.Dump(split)
	local t = {}
	for k, v in pairs(split) do
		if not v:find('%.') and v:find('[><=]') then
			--print('push')
			TableFunc.Push(t, ',' .. split[k] .. split[k + 1])
			break
		elseif tonumber(v) then
			if #t > 0 then
				t[#t] = t[#t] .. tonumber(v)
			end
		else
			TableFunc.Push(t, v)
		end
	end
	--TableFunc.Dump(t)
	return t
end

local function analysis(str, machine)
	--print('str ',str)
	local complete, split = StringDecode.Trim_Command(str)
	local command = TableFunc.Shift(complete)
	local arg, left, right, other

	--print('SCM analysis ',command)
	--TableFunc.Dump(complete)	

	if command and command:find('%(') then
		left = command:find('%(')
		right = StringDecode.Find_symbol_scope(left, command, '(', ')')
		--print('find scope',right)
		other = command:sub(right + 1, #command)
		command = command:sub(1, right)
		command, arg = StringDecode.Split_Command_Arg(command)
		for k, v in pairs(arg) do
			TableFunc.Push(complete, v)
		end
		if other:find('%.') then
			print('find .', other)
			local StringRead = require('lib.StringRead')
			other = other:gsub('%.', ' ,get ')
			local act = { StringDecode.Split_by(other, ',') }
			for i = #act, 1, -1 do
				table.insert(machine.commands, machine.index + 1, act[i])
			end
		end
	end
	--print('SCM analysis ',command ,other)
	--TableFunc.Dump(complete)
	--TableFunc.Dump(machine.commands)	

	return command, complete
end

function Simple_Command_Machine.NewMachine()
	local Wait = State.new("Wait")
	local Compare = State.new("Compare")
	local Normal = State.new("Normal")

	local machine = Machine.new({
		initial = Wait,
		states = {
			Wait, Compare, Calculate, Normal
		},
		events = {

			{ state = Wait,    global = true, self = true },
			{ state = Compare, global = true, self = true },
			{ state = Normal,  global = true, self = true },
		}
	})
	machine.stop = false
	machine.stack = {}
	machine.record = {}

	Wait.Do = function(self, battle, ...)
		machine.index = machine.index + 1
		local command = machine.commands[machine.index]
		local arg

		--print('SCM current',command)
		--TableFunc.Dump(machine.stack)

		command, arg = analysis(command, machine)
		command = StringDecode.Trim_head_tail(command)
		--print('SCM command',command)
		--TableFunc.Dump(arg)

		if tonumber(command) then
			TableFunc.Push(machine.stack, tonumber(command))
		elseif type(command) == 'table' then
			TableFunc.Push(machine.stack, command)
			--elseif find_calculate_symbol(command) then
		elseif command:find('%.') then
			--print('find .')
			local StringRead = require('lib.StringRead')
			command = command:gsub('%.', ' ,get ')
			local act = { StringDecode.Split_by(command, ',') }
			for i = #act, 1, -1 do
				table.insert(machine.commands, machine.index + 1, act[i])
			end
		elseif StringDecode.Find_compare_symbol(command) then
			machine:TransitionTo('Compare', command, battle, arg)
		else
			--print('SCM transTo normal')
			machine:TransitionTo('Normal', command, battle, arg)
		end
	end

	Compare.DoOnEnter = function(self, command, battle, arg, ...)
		--print('Compare command',command )
		local num = tonumber(command:match('%d')) and tonumber(command:match('%d')) or table.unpack(arg)
		local symbol = StringDecode.Trim_head_tail(command:gsub(num, ''))
		--local arg = {s,num}--StringDecode.Split_by(command,'%s')
		local value = Basic_act['compare'](battle, machine, symbol, num)
		machine:TransitionTo('Wait')
	end

	Normal.DoOnEnter = function(self, command, battle, arg, ...)
		local key, arg = command, arg
		--print('Normal command',command)
		--TableFunc.Dump(arg)
		if key:find('input_target') then
			local num = key:match('%d+')
			TableFunc.Push(arg, num)
		end
		--print('key',key)
		assert(Basic_act[key], 'act[' .. key .. '] is nil')
		--print('SCM Normal ',key)
		--TableFunc.Dump(arg)
		local value = Basic_act[key](battle, machine, table.unpack(arg))
		if value == 'stop' then
			machine.stop = true
		end
		machine:TransitionTo('Wait')
	end

	function machine:ReadEffect(battle, command, key_link, print_log)
		local commands = type(command) == 'table' and command or { command }
		self.key_link = key_link
		self.commands = TableFunc.DeepCopy(commands)
		self.index = 0
		while self.index < #self.commands do
			self:Update(battle)
			if print_log then
				print('Simple_Command_Machine command:', self.commands[self.index])
				print(TableFunc.Print_one_line(self.stack), '\n')
			end
		end
	end

	return machine
end

return Simple_Command_Machine
