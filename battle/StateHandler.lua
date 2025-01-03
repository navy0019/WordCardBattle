local Resource              = require('resource.Resource')
local StringRead            = require('lib.StringRead')
local TableFunc             = require('lib.TableFunc')
local StateAssets           = require('resource.stateAssets')

local StateHandler          = {}
local ComplexCommandMachine = require('battle.ComplexCommandMachine')
StateHandler.machine        = ComplexCommandMachine.NewMachine()

--[[local function get_parameter(key)

	if key:find('%(') then
		
		local left , right = key:find('%(.-%)')
		local parameter = key:match('%((.-)%)')
		--print('parameter ',parameter , left , right)
		key = StringDecode.Trim_head_tail( key:sub(1, left-1) )
		--print('buff key',key)
		--parameter = StringDecode.Trim_head_tail(parameter):sub(2,#parameter-1)
		parameter = {StringDecode.Split_by(parameter ,',')}
		parameter = StringDecode.TransToDic(parameter)
		return key,parameter
	else
		return key
	end
end]]

function StateHandler.Remove(battle, character, timing_tab, res, index)
	if res.remove then
		--print('res remove')
		local effect = res.remove
		local key_dic = { self = res, target_table = character }
		StateHandler.machine:ReadEffect(battle, effect, key_dic)
	else
		--print('remove')
	end

	table.remove(timing_tab, index)
end

function StateHandler.Excute(battle, character, state, key_dic, ...)
	local name = state.name
	local res = Resource.state[name]
	--TableFunc.Dump(res)
	local arg = { ... }
	--print('StateHandler Excute')
	--TableFunc.Dump(arg)
	for k, v in pairs(arg) do
		--print('push ',v)
		TableFunc.Push(StateHandler.machine.stack, v)
	end
	--print('StateHandler Update ',#StateHandler.machine.stack)
	--TableFunc.Dump(StateHandler.machine.stack)
	local t = {}
	if res.update then
		local effect = res.update
		--print('state update ')
		--TableFunc.Dump(effect)
		local key_dic = TableFunc.DeepCopy(key_dic)
		key_dic.self = state
		key_dic.target_table = TableFunc.IsArray(character) and character or { character }

		--print('StateHandler Excute ',state.name ,effect)
		--TableFunc.Dump(state)

		StateHandler.machine:ReadEffect(battle, effect, key_dic)


		--print('StateHandler Update ',#StateHandler.machine.stack)
		--TableFunc.Dump(StateHandler.machine.stack)
		--table.insert(t,{key='UpdateState' ,arg={state.name}})
		if key_dic.value then
			--print('StateHandler key_dic have value')
			--TableFunc.Dump(key_dic.value)
		end
	end
	--return machine.result
end

function StateHandler.Update(battle, character, state, timing_key, trigger, ...)
	local name = state.name
	local res = Resource.state[name]
	local timing_tab = character.state[timing_key]


	if state.round and type(state.round) == 'number' then
		--[[if trigger and not TableFunc.Find(res.update_timing ,'trigger') then return end
		if not trigger and not TableFunc.Find( res.update_timing  ,timing_key ) then return end
		--print('State Update',timing_key ,state.data.name)]]
		--print('State Update',timing_key ,trigger)
		if trigger and not TableFunc.Find(res.update_timing, trigger) then
			--print('trigger and not find')
			return
		end
		if not trigger and not TableFunc.Find(res.update_timing, timing_key) then
			--print('not trigger and not find')
			return
		end
		state.round = state.round - 1


		if state.round <= 0 then
			local index = TableFunc.Find(timing_tab, state)
			--print('remove ',timing_key ,name ,index)
			StateHandler.Remove(battle, character, timing_tab, res, index)
		end
	end
end

function StateHandler.AddBuff(battle, target, key, caster, key_dic) --targets
	--local state_key,parameter = get_parameter(key)
	local heroData = battle.characterData.heroData
	local monsterData = battle.characterData.monsterData
	--print('StateHandler targets',targets)
	--for k,target in pairs(targets) do
	local target_serial = TableFunc.GetSerial(target)
	if TableFunc.MatchSerial(heroData, target_serial) then
		target_serial = 'hero ' .. target_serial
	else
		target_serial = 'monster ' .. target_serial
	end

	local state = StateAssets.instance(key, target_serial, caster, key_dic, battle)
	--print('AddBuff')
	--TableFunc.Dump(state)
	local res = Resource.state[state.name]
	local state_location, name = res.location, state.name

	local index = TableFunc.Find(target.state[state_location], name, 'name')
	if index then
		local target_state = target.state[state_location][index]
		if res.overlay_effect or res.overlay then
			for key, value in pairs(state) do
				--print('state overlay', key, value)
				if tonumber(value) then
					target_state[key] = target_state[key] + tonumber(value)
					--[[else
					print('res overlay', res.name, value)
					local v = StringRead.StrToValue(value, key_dic, battle)
					target_state[key] = target_state[key] + v]]
				end
			end
			if res.overlay_effect then
				local effect = res.overlay_effect
				local key_dic = { self = state, target_table = target }
				StateHandler.machine:ReadEffect(battle, effect, key_dic)
			end
		elseif res.replace_effect or res.replace then
			table.remove(target.state[state_location], index)
			TableFunc.Push(target.state[state_location], state)
			if res.replace_effect then
				local effect = res.replace_effect
				local key_dic = { self = state, target_table = target }
				StateHandler.machine:ReadEffect(battle, effect, key_dic)
			end
		else --已存在同樣state但沒定義overlay則以新增狀態處理
			TableFunc.Push(target.state[state_location], state)
		end
	else
		TableFunc.Push(target.state[state_location], state)
		--print('add state', state)
		--TableFunc.Dump(state)
		if res.add_effect then
			--print('StateHandler add_effect')
			--TableFunc.Dump(res.add_effect)
			local effect = res.add_effect
			local key_dic = { self = state, target_table = target }
			StateHandler.machine:ReadEffect(battle, effect, key_dic)
			--print('AddBuff effect',#StateHandler.machine.result)
			--TableFunc.Dump(StateHandler.machine.result)
		end
	end

	--end
	--return machine.result
end

return StateHandler
