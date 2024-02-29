local Resource = require('resource.Resource')
local StringDecode = require('lib.StringDecode')
local TableFunc = require('lib.TableFunc')

local StateHandler={}
local ComplexCommandMachine=require('battle.ComplexCommandMachine')
StateHandler.machine=ComplexCommandMachine.NewMachine()

local function get_parameter(key)

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
end

function StateHandler.Remove( battle,character ,timing_tab ,res ,index)
	
	if res.remove then
		--print('res remove')
		local effect = res.remove 
		local key_link={self = res ,target_table=character }
		StateHandler.machine:ReadEffect(battle,effect, key_link)
	else
		--print('remove')
	end

	table.remove(timing_tab , index)
end
function StateHandler.Excute( battle, character ,state ,key_link ,...)
	local name = state.data.name
	local res = Resource.state[name]
	--TableFunc.Dump(res)
	local arg = {...}
	for k,v in pairs(arg) do
		--print('push ',v)
		TableFunc.Push(StateHandler.machine.stack , v )
	end
	--print('StateHandler Update ',#StateHandler.machine.stack)
	--TableFunc.Dump(StateHandler.machine.stack)
	local t= {}
	if res.update then 
		local effect = res.update 
		--print('state update ')
		--TableFunc.Dump(effect)
		local key_link= TableFunc.DeepCopy(key_link)
		key_link.self = state 
		key_link.target_table=TableFunc.IsArray(character) and character or {character}

		--print('StateHandler Excute ',state.name)
		--TableFunc.Dump(state)
		StateHandler.machine:ReadEffect(battle ,effect, key_link)
		--TableFunc.Dump(StateHandler.machine.stack)
		table.insert(t,{key='UpdateState' ,arg={state.data.name}})
	end
	return t
end
function StateHandler.Update( battle, character ,state ,timing_key ,trigger,...)
	local name = state.data.name
	local res = Resource.state[name]
	local timing_tab = character.state[timing_key]
	

	if state.data.round and type(state.data.round )=='number' then

		if trigger and not TableFunc.Find(res.update_timing ,'trigger') then return end
		if not trigger and not TableFunc.Find( res.update_timing  ,timing_key ) then return end
		--print('State Update',timing_key ,state.data.name)
		state.data.round=state.data.round -1 
		
		if state.data.round <=0 then
			local index = TableFunc.Find(timing_tab ,state)
			--print('remove ',timing_key ,name ,index)
			StateHandler.Remove( battle, character ,timing_tab ,res , index)
		end
	end
end

function StateHandler.AddBuff(battle,targets,key ,caster)
	local state_key,parameter = get_parameter(key)
	local heroData = battle.characterData.heroData
	local monsterData =battle.characterData.monsterData
	--print('StateHandler targets',targets)
	for k,target in pairs(targets) do
		local state = TableFunc.DeepCopy(Resource.state[state_key])

		local serial = TableFunc.GetSerial(target)
		if TableFunc.MatchSerial(heroData ,serial) then serial ='hero '..serial else serial ='monster '..serial end
		state.target=serial

		local state_time ,name = state.location ,state.data.name
		if parameter then
			local new_data = TableFunc.DeepCopy(parameter)
			for i,v in pairs(state.data) do
				new_data[i] = new_data[i] or v
			end
			state.data=new_data
		end
		state.data.caster=caster
		state.data.holder=serial
		--print('v',v)
		--TableFunc.Dump(v.state)
		local index = TableFunc.Find(target.state[state_time] , name ,'name')

		if index then
			local target_state = target.state[state_time][index]
			if state.overlay_effect or state.overlay then
				
				for key ,value in pairs(state.data) do
					if tonumber(value) then
						target_state[key]=target_state[key]+value
					end
				end
				if state.overlay_effect then
					local effect = state.overlay_effect
					local key_link={self = state ,target_table=target}
					StateHandler.machine:ReadEffect(battle ,effect, key_link)
				end
			elseif state.replace_effect or state.replace then
				table.remove(target.state[state_time] , index)
				TableFunc.Push(target.state[state_time] ,state)
				if state.replace_effect then
					local effect = state.replace_effect
					local key_link={self = state ,target_table=target}
					StateHandler.machine:ReadEffect(battle ,effect, key_link)
				end
			end
			--[[local effect = state.overlay
			local key_link={self = state ,target_table=v.state[state_time][index]}
			StateHandler.machine:ReadEffect(battle ,effect, key_link)]]

		else --已存在同樣state但沒定義overlay則以新增狀態處理
			--[[local effect = state.add
			local key_link={self = state ,target_table=v}
			StateHandler.machine:ReadEffect(battle ,effect, key_link)]]
			TableFunc.Push(target.state[state_time] ,state)
			if state.add_effect then
				local effect = state.add_effect
				local key_link={self=state ,target_table=target }
				StateHandler.machine:ReadEffect(battle ,effect, key_link)
			end 
		end
	end
	--return {key='AddBuff' ,arg={state_key}}
end

return StateHandler