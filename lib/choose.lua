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
			local o = { key = 'WaitIoRead', arg = { Msg.msg('can_need', num) } }
			TableFunc.Push(self.toView, o)
		else
			local o = { key = 'WaitIoRead', arg = { Msg.msg('need', diff) } }
			TableFunc.Push(self.toView, o)
		end
	else
		local o = { key = 'WaitIoRead', arg = { Msg.msg('can_need', diff) } }
		TableFunc.Push(self.toView, o)
	end
end
local function LoopAddCard(self, card)
	local isCard = getmetatable(card) == Card.metatable and true or false
	local current_condition = self.card_check[1]
	local diff

	if not isCard then
		local o = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } }
		TableFunc.Push(self.toView, o)
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
	self.current_choose = nil
	self.target_table = nil
	self.card_table = nil
	self.key_dic = {}
	self.condition_index = 1
	self.card_table_index = 1
	--self:TransitionTo('Wait')
end

local function Add(self, obj, table_type)
	--print('try add ' ,table_type)
	if self.current_choose then
		if table_type == 'card' then --and not TableFunc.Find(self.card.use_condition ,'input')
			local o = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } }
			TableFunc.Push(self.toView, o)
			self:Clear()
			self:TransitionTo('Wait')
		end

		local t = table_type .. '_table'
		--print('Add',t)
		if self[t] then
			--print('Add obj sucess', t)
			TableFunc.Push(self[t], obj)
		end
	elseif not self.current_choose and getmetatable(obj) ~= Card.metatable then
		local o = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } }
		TableFunc.Push(self.toView, o)
	elseif not self.current_choose then
		self.current_choose = obj
	end
end
local function InitUse_condition(self)
	--print('InitUse_condition')
	local card = self.current_choose
	self.target_table = {}
	self.card_table = {}

	--local input = TableFunc.Find(card.use_condition, 'input')
	--local select = TableFunc.Find(card.use_condition, 'select')
	--[[if input then
		--print('init input')
		self.card_table = {}
		self.card_check = {}
	end]]
	--[[if select then
		--print('init select')
		self.target_table = {}
		self.target_check = {}
		self.card_table = {}
		self.card_check = {}
	end]]
	local condition_table = {}
	for k, v in pairs(card.use_condition) do
		local choose_type = v[1]
		local num = v[2]
		local race = v[3]
		local max, min
		--print('InitUse_condition', choose_type, num, race)

		--local current_table = race == 'card' and self.card_check or self.target_check
		TableFunc.Push(condition_table, {})
		local len = #condition_table

		if type(num) == 'string' then
			local p = num:find('~')
			local a = tonumber(num:sub(1, p - 1))
			local b = tonumber(num:sub(p + 1, #num))
			max, min = math.max(a, b), math.min(a, b)
			condition_table[len]['max'] = max
			condition_table[len]['min'] = min
			condition_table[len]['choose_type'] = choose_type
			condition_table[len]['race'] = race
		else
			condition_table[len]['max'] = num
			condition_table[len]['min'] = num
			condition_table[len]['choose_type'] = choose_type
			condition_table[len]['race'] = race
		end
	end
	return condition_table
end

local Choose = {}

function Choose.new(toView) --option
	local Wait = State.new("Wait")
	local CheckCost = State.new("CheckCost")
	local CheckCondition = State.new('CheckCondition')
	local CheckSelectTarget = State.new("CheckSelectTarget")
	local CheckSelectCard = State.new("CheckSelectCard")
	local WaitSelect = State.new("WaitSelect")
	local Prepare_key_link = State.new("Prepare_key_link")
	local machine = Machine.new({
		initial = Wait,
		states = {
			Wait, CheckCost, CheckCondition, CheckSelectTarget, CheckSelectCard, Prepare_key_link, WaitSelect
		},
		events = {
			--[[ 	Wait(global)					
			 CheckCost--> CheckCondition --> Prepare_key_link
			 					|      \			
			 			CheckSelect  CheckSelectCard
								|		|
								 \		|
			 					  \		|
			 					WaitSelect
     					 				]]

			{ state = Wait,              global = true,           self = true },

			{ state = CheckCost,         to = 'CheckCondition' },
			--{ state = CheckCost,   to = 'CheckSelect' },
			--{ state = CheckCost,   to = 'CheckInput' },

			{ state = CheckCondition,    to = 'CheckSelectTarget' },
			{ state = CheckCondition,    to = 'CheckSelectCard' },
			{ state = CheckCondition,    to = 'Prepare_key_link' },

			{ state = CheckSelectTarget, to = 'CheckCondition' },
			{ state = CheckSelectTarget, to = 'WaitSelect' },

			{ state = CheckSelectCard,   to = 'CheckCondition' },
			{ state = CheckSelectCard,   to = 'WaitSelect' },

			{ state = WaitSelect,        to = 'CheckSelectCard' },
			{ state = WaitSelect,        to = 'CheckSelectTarget' },


		}
	})
	--machine.condition = option or nil
	assert(toView, "必須指定一個table")
	machine.toView = toView

	machine.current_choose = nil
	machine.condition_index = 1
	machine.card_table_index = 1
	machine.LoopAddCard = LoopAddCard
	machine.Add = Add
	machine.Clear = Clear

	machine.key_dic = {}

	Wait.Do = function(self, input_machine, battle, ...)
		if machine.current_choose then
			--print('TransitionTo cost')

			if battle then
				machine.condition_table = InitUse_condition(machine)
				machine:TransitionTo('CheckCost', input_machine, battle)
			end
			--elseif machine.condition then
			--machine:TransitionTo('CheckSelect', input_machine, battle)
		end
	end

	CheckCost.DoOnEnter = function(self, input_machine, battle, ...)
		local card = machine.current_choose
		--print('choose check cost', battle.battleData.actPoint)

		if card.cost > battle.battleData.actPoint then
			machine.current_choose = nil
			local o                = { key = 'WaitIoRead', arg = { Msg.msg('actpoint_not_enough') } }
			TableFunc.Push(machine.toView, o)
		else
			machine.key_dic.card = machine.current_choose
			machine.key_dic.self = machine.current_choose
			machine:TransitionTo('CheckCondition', input_machine, battle)
		end
	end
	--[[CheckCost.Do = function(self, input_machine, battle, ...)
		if machine.target_table and #machine.target_table > 0 then
			--print('cost TransitionTo Select')
			machine:TransitionTo('CheckSelect', battle)
		end
	end]]
	CheckCondition.DoOnEnter = function(self, input_machine, battle, ...)
		--print('CheckCondition', machine.condition_index, #machine.condition_table)
		if machine.condition_index > #machine.condition_table then
			--print('TransTo Prepare_key_link')
			machine.condition_index = 1
			machine:TransitionTo('Prepare_key_link', input_machine, battle)
		else
			local current_condition = machine.condition_table[machine.condition_index]
			local check_race = current_condition.race
			if check_race == 'card' then
				machine:TransitionTo('CheckSelectCard', input_machine, battle)
			else
				machine:TransitionTo('CheckSelectTarget', input_machine, battle)
			end
		end
	end
	WaitSelect.DoOnEnter = function(self, input_machine, battle, ...)
		self.target_num = #machine.target_table
		self.card_num = #machine.card_table
	end
	WaitSelect.Do = function(self, input_machine, battle, ...)
		if #machine.target_table ~= self.target_num then
			--print('WaitSelect TransTo CheckSelectTarget')
			machine:TransitionTo('CheckSelectTarget', input_machine, battle, ...)
		elseif #machine.card_table ~= self.card_num then
			machine:TransitionTo('CheckSelectCard', input_machine, battle, ...)
		end
	end
	CheckSelectTarget.DoOnEnter = function(self, input_machine, battle, ...)
		local current_condition = machine.condition_table[machine.condition_index]
		--print('check select ', #machine.target_table)
		for i, target in pairs(machine.target_table) do
			--print('check select race', target.data.race, current_condition.race)
			if target.data.race ~= current_condition.race then
				break
			else
				machine.condition_index = machine.condition_index + 1
				--print('check next', machine.condition_index)
				machine:TransitionTo('CheckCondition', input_machine, battle)
				return
			end
		end

		local monsterData = battle.characterData.monsterData
		local heroData = battle.characterData.heroData
		local msg = #machine.target_table > 0 and 'error_target' or 'need_target'
		local arg = msg == 'need_target' and { #heroData, #monsterData } or {}
		local o = { key = 'WaitIoRead', arg = { Msg.msg(msg, table.unpack(arg)) } }
		TableFunc.Push(machine.toView, o)

		if msg == 'error_target' then
			machine:Clear()
			machine:TransitionTo('Wait', input_machine, battle, ...)
		else
			--print('check select target TransTo WaitSelect')
			machine:TransitionTo('WaitSelect', input_machine, battle, current_condition)
		end
	end

	CheckSelectCard.DoOnEnter = function(self, input_machine, battle, ...)
		--print('let\'s CheckInput')
		local enforce = ...
		print('enforce', ...)
		local diff
		local current_condition = machine.condition_table[machine.condition_index]
		for key, target in pairs(machine.card_table) do
			if getmetatable(target) ~= Card.metatable then
				machine:Clear()
				local o = { key = 'WaitIoRead', arg = { Msg.msg('error_target') } }
				TableFunc.Push(machine.toView, o)
				machine:TransitionTo('Wait', input_machine, battle, ...)
				return
			end
			if not enforce then
				--print('not enforce', enforce)
				MakeDiff(machine, current_condition)
				machine:TransitionTo('WaitSelect', input_machine, battle, ...)
				return
			end
			--確認數量
			if #machine.card_table > current_condition.max or #machine.card_table < current_condition.min then
				--print('still need ',#machine.card_table ,tab.max ,tab.min)
				MakeDiff(machine, current_condition)
				machine:TransitionTo('WaitSelect', input_machine, battle, ...)
				return
			else
				local name = 'select_card' .. machine.card_table_index
				machine.key_dic[name] = {}
				for i = 1, #machine.card_table do
					local card = TableFunc.Shift(machine.card_table)
					TableFunc.Push(machine.key_dic[name], card)
				end
				machine.condition_index = machine.condition_index + 1
				machine:TransitionTo('CheckCondition', input_machine, battle, ...)
			end
			--enforce = nil
		end
	end

	Prepare_key_link.DoOnEnter = function(self, input_machine, battle, ...)
		print('Prepare_key_link !')
		local card = machine.current_choose
		local heroData = battle.characterData.heroData
		local monData = battle.characterData.monsterData

		--製作target
		if machine.target_table then
			machine.key_dic.target_table = {}
			local obj = machine.target_table[1]
			local race_table = obj.race == 'hero' and heroData or monData
			local index = TableFunc.Find(race_table, obj)
			assert(index, 'can\'t find target in race_table')

			local target_index = 0
			for index, value in pairs(machine.condition_table) do
				if value.race == 'hero' or value.race == 'enemy' then
					target_index = index
				end
			end
			local target_condition = machine.condition_table[target_index]

			local need_num = target_condition.max

			if need_num == 4 or need_num >= #race_table then
				machine.key_dic.target_table = race_table
			elseif need_num > 1 then
				local diff = need_num - 1 --(扣掉target_table已經包含的一個)
				local reverse = 0

				if index + diff > #race_table then
					reverse = index + diff - #race_table
					local start_index = index + 1
					for i = start_index, #race_table do
						TableFunc.Push(machine.key_dic.target_table, race_table[i])
					end
					for i = 1, reverse do
						TableFunc.Push(machine.key_dic.target_table, race_table[index - i])
					end
				else
					for i = 1, diff do
						TableFunc.Push(machine.key_dic.target_table, race_table[index + i])
					end
				end
			else
				TableFunc.Push(machine.key_dic.target_table, race_table[index])
			end
			--print('Prepare_key_link select done')
		end
		--TableFunc.Dump(machine.key_dic.card)
		local o = { key = 'ReadyToUse', arg = { battle, input_machine, machine.key_dic }, actName = 'ReadyToUse' }
		TableFunc.Push(battle.pending, o)
		--print('Prepare_key_link done')
		machine:Clear()
		machine:TransitionTo('Wait', input_machine, battle, ...)
		--TableFunc.Dump(machine.key_dic )
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
