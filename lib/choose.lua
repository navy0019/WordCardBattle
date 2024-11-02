local TableFunc = require("lib.TableFunc")
local Card = require('lib.card')
local Msg = require('resource.Msg')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local function MakeDiff(self, current_condition)
	local diff = current_condition.max - #self.card_table
	if diff > 0 then
		if current_condition.max ~= current_condition.min then
			local min = #self.card_table >= current_condition.min and 0 or current_condition.min
			local num = current_condition.min < diff and min .. '~' .. diff or diff
			local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('can_need', num) } } }
			TableFunc.Push(self.queue, o)
		else
			local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('need', diff) } } }
			TableFunc.Push(self.queue, o)
		end
	else
		local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('can_need', diff) } } }
		TableFunc.Push(self.queue, o)
	end
end
local function LoopAdd(self, card)
	local isCard = getmetatable(card) == Card.metatable and true or false
	local current_condition = self.card_check[1]
	local diff

	if not isCard then
		local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } } }
		TableFunc.Push(self.queue, o)
		return
	end

	local p = TableFunc.Find(self.card_table, card)
	if p then
		table.remove(self.card_table, p)
		MakeDiff(self, current_condition)
		return
	end

	if #self.card_table + 1 > current_condition.max then
		TableFunc.Shift(self.card_table)
		TableFunc.Push(self.card_table, card)
		MakeDiff(self, current_condition)
	else
		TableFunc.Push(self.card_table, card)
		MakeDiff(self, current_condition)
	end
end

local function Clear(self)
	--print('Clear!')
	self.card = nil
	self.target_table, self.target_check = nil, nil
	self.card_table, self.card_check = nil, nil
	self.key_link = {}
	--self:TransitionTo('Wait')
end

local function Add(self, obj, table_type)
	--print('try add ' ,table_type)
	if self.card then
		if table_type == 'card' then --and not TableFunc.Find(self.card.use_condition ,'input')
			local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } } }
			TableFunc.Push(self.queue, o)
			self:Clear()
			self:TransitionTo('Wait')
		end

		local t = table_type .. '_table'
		--print('Add',t)
		if self[t] then
			print('Add obj sucess', t)
			TableFunc.Push(self[t], obj)
		end
	elseif not self.card and getmetatable(obj) ~= Card.metatable then
		local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } } }
		TableFunc.Push(self.queue, o)
	elseif not self.card then
		self.card = obj
	end
end
local function InitUse_condition(self)
	--print('InitUse_condition')
	local card = self.card
	local input = TableFunc.Find(card.use_condition, 'input')
	local select = TableFunc.Find(card.use_condition, 'select')
	--[[if input then
		--print('init input')
		self.card_table = {}
		self.card_check = {}
	end]]
	if select then
		--print('init select')
		self.target_table = {}
		self.target_check = {}
		self.card_table = {}
		self.card_check = {}
	end

	for k, v in pairs(card.use_condition) do
		local choose_type = v[1]
		local num = v[2]
		local race = v[3]
		local max, min
		print('InitUse_condition', choose_type, num, race)

		local current_table = choose_type == 'input' and self.card_check or self.target_check
		TableFunc.Push(current_table, {})
		local len = #current_table

		if type(num) == 'string' then
			local p = num:find('~')
			local a = tonumber(num:sub(1, p - 1))
			local b = tonumber(num:sub(p + 1, #num))
			max, min = math.max(a, b), math.min(a, b)
			current_table[len]['max'] = max
			current_table[len]['min'] = min
			current_table[len]['choose_type'] = choose_type
			current_table[len]['race'] = race
		else
			current_table[len]['max'] = num
			current_table[len]['min'] = num
			current_table[len]['choose_type'] = choose_type
			current_table[len]['race'] = race
		end
	end
end

local Choose = {}

function Choose.new() --option
	local Wait = State.new("Wait")
	local CheckCost = State.new("CheckCost")
	local CheckSelect = State.new("CheckSelect")
	local CheckInput = State.new("CheckInput")
	local InputWait = State.new("InputWait")
	local Prepare_key_link = State.new("Prepare_key_link")
	local machine = Machine.new({
		initial = Wait,
		states = {
			Wait, CheckCost, CheckSelect, CheckInput, Prepare_key_link, InputWait
		},
		events = {
			--[[ 	Wait(global)					
			 CheckCost--> CheckSelect --> CheckInput --> Prepare_key_link
			 								^
			 								|
			 								v
			 							  InputWait
     					 				]]

			{ state = Wait,        global = true,          self = true },

			{ state = CheckCost,   to = 'CheckSelect' },
			{ state = CheckCost,   to = 'CheckInput' },

			{ state = CheckSelect, to = 'CheckInput' },
			{ state = CheckSelect, to = 'Prepare_key_link' },
			{ state = CheckInput,  to = 'InputWait' },
			{ state = CheckInput,  to = 'Prepare_key_link' },
			{ state = InputWait,   to = 'CheckInput' },


		}
	})
	--machine.condition = option or nil
	--assert(toView, "必須指定一個table")
	--machine.toView = toView

	machine.card = nil
	machine.LoopAdd = LoopAdd
	machine.Add = Add
	machine.Clear = Clear

	machine.key_link = {}

	Wait.Do = function(self, input_machine, battle, ...)
		--print('Choose Wait')
		if machine.card then
			--print('TransitionTo cost')
			if battle then
				machine:TransitionTo('CheckCost', input_machine, battle)
			end
			--elseif machine.condition then
			--machine:TransitionTo('CheckSelect', input_machine, battle)
		end
	end
	CheckCost.DoOnEnter = function(self, input_machine, battle, ...)
		local card = machine.card
		print('choose check cost', battle.battleData.actPoint)

		if card.cost > battle.battleData.actPoint then
			machine.card = nil
			local o = { toBattleView = { key = 'WaitIoRead', arg = { Msg.msg('actpoint_not_enough') } } }
			TableFunc.Push(machine.toView, o)
		else
			machine.key_link.card = machine.card
			machine.key_link.self = machine.card
			InitUse_condition(machine)
			--print('find select',TableFunc.Find(card.use_condition,'select'))
			--print('find input ',TableFunc.Find(card.use_condition,'input'))
			if not TableFunc.Find(card.use_condition, 'select') and TableFunc.Find(card.use_condition, 'input') then
				--print('cost TransitionTo ExtraInput')
				local o = { toBattleView = { key = 'TransitionTo', arg = { 'ExtraInput' } } }
				TableFunc.Push(machine.toView, o)

				local current_condition = machine.card_check[1]
				MakeDiff(machine, current_condition)
			else
				local monsterData = battle.characterData.monsterData
				local heroData = battle.characterData.heroData
				--print('choose need target')
				local o = { toView = { key = 'WaitIoRead', arg = { Msg.msg('need_target', machine.key_link) } } }
				TableFunc.Push(machine.toView, o)
			end
		end
	end
	CheckCost.Do = function(self, input_machine, battle, ...)
		if machine.target_table and #machine.target_table > 0 then
			--print('cost TransitionTo Select')
			machine:TransitionTo('CheckSelect', battle)
		end
	end
	CheckSelect.DoOnEnter = function(self, input_machine, battle, ...)
		print('check select ', #machine.target_table)
		for i, target in pairs(machine.target_table) do
			--TableFunc.Dump(target)
			for k, t in pairs(machine.target_check) do
				--print('target race ',target.race ,t.race)
				if target.race == t.race then
					machine.key_link.current_target = target
					if machine.card_table then
						--print('Select TransitionTo Input')
						local o = { toSceneBattleView = { key = 'TransitionTo', arg = { 'ExtraInput' } } }
						TableFunc.Push(machine.toView, o)
						machine:TransitionTo('CheckInput', input_machine, battle)
						return
					else
						machine:TransitionTo('Prepare_key_link', input_machine, battle)
						return
					end
				end
			end
		end

		local monsterData = battle.characterData.monsterData
		local heroData = battle.characterData.heroData
		local msg = #machine.target_table > 0 and 'error_target' or 'need_target'
		local arg = msg == 'need_target' and { #heroData, #monsterData } or {}
		local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg(msg, table.unpack(arg)) } } }
		TableFunc.Push(machine.toView, o)

		machine:Clear()
		machine:TransitionTo('Wait')
	end

	CheckInput.DoOnEnter = function(self, input_machine, battle, ...)
		--print('let\'s CheckInput')
		local input, enforce = ...
		--print('input,enforce,battle',...)
		local diff
		if machine.card_table then
			for i = 1, #machine.card_check do
				local current_condition = machine.card_check[1]
				--確認種類
				for i, target in pairs(machine.card_table) do
					if getmetatable(target) ~= Card.metatable then
						machine:Clear()
						local o = { toSceneBattleView = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } } }
						TableFunc.Push(machine.toView, o)
						machine:TransitionTo('Wait')
						return
					end
				end

				if not enforce then
					print('not enforce', enforce)
					MakeDiff(machine, current_condition)
					machine:TransitionTo('InputWait')
					return
				end
				--確認數量
				if #machine.card_table > current_condition.max or #machine.card_table < current_condition.min then
					--print('still need ',#machine.card_table ,tab.max ,tab.min)
					MakeDiff(machine, current_condition)
					machine:TransitionTo('InputWait')
					return
				else
					local name = 'input_target_' .. i
					machine.key_link[name] = {}
					for i = #machine.card_table, 1, -1 do
						TableFunc.Push(machine.key_link[name], machine.card_table[1])
						TableFunc.Shift(machine.card_table)
					end
					TableFunc.Shift(machine.card_check)
					--print('complete input',name)
				end
				enforce = nil
			end
			machine:TransitionTo('Prepare_key_link', battle)
		else
			--print('TransitionTo Prepare_key_link')
			machine:TransitionTo('Prepare_key_link', battle)
		end
	end
	--[[InputWait.DoOnEnter=function(self,battle,...)
		print('input wait')
		self.current_num = #machine.card_table
	end
	InputWait.Do=function(self,battle,...)
		if #machine.card_table > self.current_num then
			machine:TransitionTo('CheckInput')
		end
	end]]
	Prepare_key_link.DoOnEnter = function(self, input_machine, battle, ...)
		local card = machine.card
		local heroData = battle.characterData.heroData
		local monData = battle.characterData.monsterData

		--製作target
		if machine.target_table then
			machine.key_link.target_table = {}
			local obj = machine.target_table[1]
			local race_table = obj.race == 'hero' and heroData or monData
			local index = TableFunc.Find(race_table, obj)
			assert(index, 'can\'t find target in race_table')

			local current_condition
			for k, v in pairs(machine.target_check) do
				if TableFunc.Find(v, obj.race, 'race') then
					current_condition = v
					break
				end
			end
			assert(current_condition, 'can\'t find current_condition')
			local need_num = current_condition.max

			if need_num == 4 or need_num >= #race_table then
				machine.key_link.target_table = race_table
			elseif need_num > 1 then
				local diff = need_num - 1 --(扣掉target_table已經包含的一個)
				local reverse = 0

				if index + diff > #race_table then
					reverse = index + diff - #race_table
					local start_index = index + 1
					for i = start_index, #race_table do
						TableFunc.Push(machine.key_link.target_table, race_table[i])
					end
					for i = 1, reverse do
						TableFunc.Push(machine.key_link.target_table, race_table[index - i])
					end
				else
					for i = 1, diff do
						TableFunc.Push(machine.key_link.target_table, race_table[index + i])
					end
				end
			else
				TableFunc.Push(machine.key_link.target_table, race_table[index])
			end
			--print('Prepare_key_link select done')
		end
		--TableFunc.Dump(machine.key_link.card)
		local o = { toPending = { key = 'ReadyToUse', arg = { machine.key_link, battle, 'hero' }, actName = 'ReadyToUse' } }
		TableFunc.Push(machine.toView, o)
		--print('Prepare_key_link done')
		machine:Clear()
		machine:TransitionTo('Wait')
		--TableFunc.Dump(machine.key_link )
	end
	machine.Update = function(self, ...)
		--[[if #machine.toView > 0 then
			local o = TableFunc.Shift(machine.toView)
			return o
		end]]
		self.current:Do(...)
		--print(self.current.name)
	end
	return machine
end

--Choose.metatable.__index=function (table,key) return Choose.default[key] end

return Choose
