local StringRead 	= require('lib.StringRead')
local StringDecode 	= require('lib.StringDecode')
local MathExtend 	= require('lib.math')
local TableFunc		= require('lib.TableFunc')
local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local SCMachine=Simple_Command_Machine.NewMachine()


local final_process ={}


local function check_protect(target ,battle)
	local StateHandler = require('battle.StateHandler')
	local hero_data = battle.characterData.heroData
	local monster_data = battle.characterData.monsterData
	local target =target
	if #target.state.protect > 0 then
		local serial_type ,serial = StringDecode.Split_by(target.state.protect[1].caster ,'%s') 
		local target_data = serial_type=='hero' and hero_data or monster_data	 
		--print('serial ',serial_type ,serial)
		local k = TableFunc.MatchSerial(target_data ,serial)
		if k and target_data[k].data.hp>0 then 
			local state = target.state.protect[1]
			StateHandler.Update(battle , target , state ,'protect' ,'trigger')
			return target_data[k]
		end
	end
	return target
end
local function state_trigger_update(targets ,holder , info)
	local StateHandler = require('battle.StateHandler')
	local map={target = targets ,holder =holder}
	for k,v in pairs(info.value_state) do
		--print('state!',v[1])
		local targets ,state_table_string  = map[v[1]] , v[2] 
		for k,target in pairs(targets) do
			local state_table = target.state[state_table_string]
			for i,state in pairs(state_table) do		
				StateHandler.Update(battle , target , state ,state_table_string ,'trigger') 
			end	
		end
	end
end
final_process.buff_value=function (battle, targets ,state_key ,key_link ,value)--target_string	
	local t={}
	--print('buff value',target_string )
	--print('target_table',#key_link.target_table)
	--SCMachine:ReadEffect(battle ,target_string , key_link )
	--local targets =TableFunc.Pop(SCMachine.stack)
	--if TableFunc.IsDictionary(targets) then targets ={targets} end
	if type(value)~='table' then 
		for i=1,#targets do
			TableFunc.Push(t , value)
		end
		
	elseif #value ~= #targets then
		for i=1,#targets do
			local nv =value[i] and value[i] or value[#value]
			TableFunc.Push(t , nv)
		end
	else
		--print('length is same')
		t=TableFunc.DeepCopy(value)
	end

	--print('buff_value target number',#targets)
	--TableFunc.Dump(t)

	if #targets >0 then
		local StateHandler = require('battle.StateHandler')
		--print('targets > 0',#targets)
		
		for k,target in pairs(targets) do
			--TableFunc.Dump(targets)
			--print('buff value target index',target.data.team_index)
			local state_table = target.state[state_key]
			local final_value --= t[k]and t[k] or t[#t]

			if #state_table > 0 then
				for i,state in pairs(state_table) do		
					print(target.key..' have state',state.name)
					
					--StateHandler.Update(battle , target , state ,state_key ,'trigger') 
					if state.effect_number =='multi' then 
						final_value = t
					else
						final_value = t[k]and t[k] or t[#t]
					end
					StateHandler.Excute(battle , target , state ,key_link ,final_value)
				end
				pop_value = TableFunc.Pop(StateHandler.machine.stack)
				--print('state update final_value')
				TableFunc.Dump(pop_value)
				--TableFunc.Push(t,final_value)
				--t[k]=final_value
				if type(pop_value)=='table' then 
					--print('pop_value is table')
					
					t = pop_value
				else
					--t= final_value
					--print('single value index',k)
					t[k]=pop_value
				end
			else
				local index = k <= #t and k or #t
				final_value = t[index]
				if not tonumber(final_value) then
					print('buff value state is empty',final_value)
					t[index] =StringRead.StrToValue(final_value , key_link , battle)
				else
					t[index] = tonumber(final_value)
				end


			end
		end
	
	end
	return t
end
final_process.set_value=function(battle , machine ,...)
	local StateHandler = require('battle.StateHandler')
	local info =...


	--print('final_process set_hp_value')
	local target ,value   =info.target ,info.value 
	local key,limit = table.unpack(info.sub_key)
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	--print('set_value targets ',targets ,#targets)
	if not TableFunc.IsArray(targets) then targets ={targets} end

	SCMachine:ReadEffect(battle ,'holder' , machine.key_link )
	local holder = TableFunc.Pop(SCMachine.stack)

	state_trigger_update(targets , holder ,info)

	for k,target in pairs(targets) do
		local current_value = value[k] and value[k] or value[#value]
	 	final_process.calculate_value(battle ,machine ,target.data[key] ,current_value, limit )
	 	final_value = TableFunc.Pop(machine.stack)

		target.data[key] = final_value
	end

end
final_process.set_hp_value=function(battle , machine ,...)
	local StateHandler = require('battle.StateHandler')
	local info =...
	local final_target

	--print('final_process set_hp_value')
	local targets ,value  =info.target ,info.value
	--SCMachine:ReadEffect(battle ,target , machine.key_link )
	--local targets =TableFunc.Pop(SCMachine.stack)
	--print('set_value targets ',targets ,#targets)
	if not TableFunc.IsArray(targets) then targets ={targets} end

	SCMachine:ReadEffect(battle ,'holder' , machine.key_link )
	local holder = TableFunc.Pop(SCMachine.stack)

	state_trigger_update(targets , holder ,info)

	for k,target in pairs(targets) do
		local current_value = value[k] and value[k] or value[#value]
		final_target = target
		--[[if info.protect then
			final_target = check_protect(target ,battle)
		else
			final_target = target
		end]]
		temp_hp = final_target.data.hp --辨認target 是否有受到傷害
		if info.shield then

			final_target.data.shield = final_target.data.shield + current_value

			if final_target.data.shield < 0 then
				--final_process.calculate_value(battle,machine ,final_target.data.hp ,final_target.data.shield ,'0~'..final_target.data.max_hp)
				--final_target.data.hp = TableFunc.Pop(machine.stack)
				final_target.data.hp = MathExtend.clamp(final_target.data.hp + final_target.data.shield , 0 ,final_target.data.max_hp)
				final_target.data.shield = 0
			end
		else
			--final_process.calculate_value(battle,machine ,final_target.data.hp ,current_value ,'0~'..final_target.data.max_hp)
			--final_target.data.hp = TableFunc.Pop(machine.stack)
			final_target.data.hp = MathExtend.clamp(final_target.data.hp + current_value , 0 ,final_target.data.max_hp)
			
		end


		if final_target.data.hp <= 0 then 
			local state_table = final_target.state['dead']
			for i,state in pairs(state_table) do
				StateHandler.Excute(battle , final_target , state ,machine.key_link ,holder)	--target
				StateHandler.Update(battle , final_target , state ,'dead')
			end
		elseif final_target.data.hp < temp_hp then
			local state_table = final_target.state['injure']
			for i,state in pairs(state_table) do
				StateHandler.Excute(battle , final_target , state ,machine.key_link ,holder)	--target
				StateHandler.Update(battle , final_target , state ,'injure')
			end			
		end

	end

end

final_process.calculate_value=function(battle,machine,...)

	SCMachine.stack = TableFunc.DeepCopy(machine.stack)
	--TableFunc.Dump(SCMachine.stack)

	local target_string ,value ,limit =...	
	--value = value:match('%((.-)%)')
	--print('calculate_value ',target_string ,value ,limit )
	if tonumber(value) and tonumber(value) >=0 and not StringDecode.Find_calculate_symbol(tostring(value)) then
		value ="+"..tostring(value)
	end
	
	local min,max
	if limit then 
		min ,max =StringDecode.Split_by(limit ,'~') 
		
		if tonumber(min) then 
			min = tonumber(min)
		else

			min =StringRead.StrToValue(min ,machine.key_link,battle)
		end
		if tonumber(max) then 
			max = tonumber(max)
		else

			max =StringRead.StrToValue(max ,machine.key_link,battle)
		end
		--print('min~max',min ,max)
	end

	SCMachine:ReadEffect(battle, target_string , machine.key_link )
	local target_entity = TableFunc.Pop(SCMachine.stack) 
	--print('target_entity',target_string ,target_entity)
	--TableFunc.Dump(target_entity)

	if TableFunc.IsArray(target_entity) then
		--print('IsArray')
		local t={}
		for k,v in pairs(target_entity) do
			
			local final_value=v..value
			--print('calculate string value',v ,value )
			final_value = StringRead.StrToValue(final_value ,machine.key_link ,battle)
			if limit then final_value = MathExtend.clamp(final_value, min,max)end

			TableFunc.Push(t,final_value)
		end
		if #t > 0 then TableFunc.Push(machine.stack , t) end

	else
		--print('calculate string value',target_entity ,value )	
		
		value=target_entity..value	
		--print('value' ,value)
		value = StringRead.StrToValue(value ,machine.key_link ,battle)
		if limit then value = MathExtend.clamp(value, min,max)end
		--print('calculate value: ',value)
		TableFunc.Push(machine.stack , value)
	end
end
final_process.protect=function(battle,machine,...)
end
return final_process