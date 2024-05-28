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
final_process.buff_value=function (battle, target_string ,state_key ,key_link ,value)	

		
	SCMachine:ReadEffect(battle ,target_string , key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	if TableFunc.IsDictionary(targets) then targets ={targets} end

	--print('buff_value target',value)

	if #targets >0 then
		local target 
		if #targets > 1 then 
			target =targets[TableFunc.Find(targets , key_link.current_choose_target)] 
		else
			target=targets[#targets]
		end

		local StateHandler = require('battle.StateHandler')
		local state_table = target.state[state_key]
		if #state_table > 0 then
			for i,state in pairs(state_table) do		
				StateHandler.Excute(battle , target , state ,key_link ,value)
				StateHandler.Update(battle , target , state ,state_key ,'trigger') 
				--( battle, character ,state ,timing_key ,trigger,...)
			end
			local final_value = TableFunc.Pop(StateHandler.machine.stack)

			return final_value
		else
			return value
		end


	end

	--[[local StateHandler = require('battle.StateHandler')
	--print('state_table ',key)
	--TableFunc.Dump(target)
	local state_table = target.state[key]
	local res_state = Resource.state

	--print('state len: ',#state_table)
	--print('buff value ',value)

	if #state_table > 0 then
		for i,state in pairs(state_table) do		
			StateHandler.Excute(battle , target , state ,key_link ,value)

			--local res = Resource.state[state.name]
			--if TableFunc.Find(res.update_timing , 'trigger') then 						
				StateHandler.Update(battle , target , state ,key ,'trigger') 
			--end
		end
		local final_value = TableFunc.Pop(StateHandler.machine.stack)
		--print('buff_value ',final_value)
		return final_value
	else
		return value
	end]]
end
final_process.set_value=function(battle , machine ,...)
	local stack  ,key_link	=machine.stack ,machine.key_link
	local target ,value ,info = ... 
	local key = info.key

	value = math.max(0 , StringRead.StrToValue(value ,machine.key_link ,battle))

	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	if not TableFunc.IsArray(targets) then targets ={targets} end
	machine.key_link.target_table=targets

	local final_target 	,final_value

	if info.value_state then
		for k,v in pairs(info.value_state) do
		 	if not map[v[1]] and v[1]~='target' then
		 		SCMachine:ReadEffect(battle ,v[1], machine.key_link )
		 		local instance = TableFunc.Pop(SCMachine.stack)
		 		map[v[1]] =instance
		 	end
		end
	end

	for k,target in pairs(targets) do
		if info.value_state then
			for i,v in pairs(info.value_state) do
				value = MathExtend.round(final_process.buff_value(map[v[1]] , v[2],machine.key_link ,value))
			end
		end 
		local arg =info.symbol..tostring(value)	
		
		--print('target ',target ,key ,arg ,)
	 	final_process.calculate_value(battle ,machine ,target.data[key] ,arg)
	 	final_value = TableFunc.Pop(machine.stack)

		target.data[key] = final_value
	end
end
final_process.set_hp_value=function(battle , machine ,...)
	local stack  ,key_link	=machine.stack ,machine.key_link
	local target ,value ,info = ... 
	local map ={}
	local temp_hp
	--print('card_type',card_type)

	value = math.max(0 , StringRead.StrToValue(value ,machine.key_link ,battle))
	--print('set_value',value ,target)

	--print('set_value',target)
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	--print('set_value targets ',targets ,#targets)
	if not TableFunc.IsArray(targets) then targets ={targets} end
	machine.key_link.target_table=targets

	local final_target 	,final_value

	for k,v in pairs(info.value_state) do
	 	if not map[v[1]] and v[1]~='target' then
	 		SCMachine:ReadEffect(battle ,v[1], machine.key_link )
	 		local instance = TableFunc.Pop(SCMachine.stack)
	 		map[v[1]] =instance
	 	end
	end 

	for k,target in pairs(targets) do
		map['target']=target
		if info.protect then
			final_target = check_protect(target ,battle)
			--print('check protect')
			map['target']=final_target
		else
			--print('no protect')
			final_target = target
		end
		temp_hp = final_target.data.hp

		if info.value_state then
			for i,v in pairs(info.value_state) do
				value = MathExtend.round(final_process.buff_value(map[v[1]] , v[2],machine.key_link ,value))
			end
		end
		print('set_value final_value',value)
		if info.shield then
			local arg =info.symbol..tostring(value)	
			--print('set_value ,shield',final_target.data.shield  ,arg)		
			final_process.calculate_value(battle,machine,final_target.data.shield , arg)
			local shield_value = TableFunc.Pop(machine.stack)

			final_target.data.shield = shield_value

			if final_target.data.shield < 0 then
				final_process.calculate_value(battle,machine,final_target.data['hp'] ,info.symbol..math.abs(final_target.data.shield))
				final_value = TableFunc.Pop(machine.stack)

				final_target.data['hp'] =MathExtend.clamp(final_value , 0 ,final_target.data.max_hp)
				final_target.data.shield = 0
			end
		else
			final_process.calculate_value(battle,machine,final_target.data['hp'] ,info.symbol..value)
			final_value = TableFunc.Pop(machine.stack)
			final_target.data['hp'] = MathExtend.clamp(final_value , 0 ,final_target.data.max_hp)
		end

		if final_target.data.hp <= 0 then 
			local state_table = final_target.state['dead']
			for i,state in pairs(state_table) do
				StateHandler.Excute(battle , final_target , state ,key_link ,holder)	--target
				StateHandler.Update(battle , final_target , state ,'dead')
			end
		elseif final_target.data.hp < temp_hp then
			local state_table = final_target.state['injure']
			for i,state in pairs(state_table) do
				StateHandler.Excute(battle , final_target , state ,key_link ,holder)	--target
				StateHandler.Update(battle , final_target , state ,'injure')
			end			
		end
		
		
	end

end
final_process.calculate_value=function(battle,machine,...)

	SCMachine.stack = TableFunc.DeepCopy(machine.stack)

	local target_string ,value =...	
	--value = value:match('%((.-)%)')
	--print('calculate_value ',target_string ,value )

	SCMachine:ReadEffect(battle, target_string , machine.key_link )
	local target_entity = TableFunc.Pop(SCMachine.stack) 

	if TableFunc.IsArray(target_entity) then
		local t={}
		for k,t in pairs(target_entity) do
			value=t..value
			--print('calculate string value',value )
			value = StringRead.StrToValue(value ,machine.key_link ,battle)

			TableFunc.Push(t,value)
		end
		if #t > 0 then TableFunc.Push(machine.stack , t) end

	else
		--print('calculate string value',target_entity ,value )	
		value=target_entity..value	
		value = StringRead.StrToValue(value ,machine.key_link ,battle)
		--print('calculate value: ',value)
		TableFunc.Push(machine.stack , value)
	end
end
return final_process