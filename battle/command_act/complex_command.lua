local TableFunc		= require('lib.TableFunc')
local StringDecode  = require('lib.StringDecode')

local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local SCMachine=Simple_Command_Machine.NewMachine()
local final_process = require('battle.command_act.final_process')

local complex_command={}
TableFunc.Merge(complex_command,final_process)

local function check_protect(targets ,battle , info)
	local StateHandler = require('battle.StateHandler')
	local hero_data = battle.characterData.heroData
	local monster_data = battle.characterData.monsterData
	--local target =target
	local t ={}
	for k,target in pairs(targets) do
		if #target.state.protect > 0 then
			local serial_type ,serial = StringDecode.Split_by(target.state.protect[1].caster ,'%s') 
			local target_data = serial_type=='hero' and hero_data or monster_data	 
			--print('serial ',serial_type ,serial)
			local i = TableFunc.MatchSerial(target_data ,serial)
			if i and target_data[i].data.hp>0 then 
				--local state = target.state.protect[1]
				--StateHandler.Update(battle , target , state ,'protect' ,'trigger')
				--return target_data[k]
				--print('change target!!')
				t[k]=target_data[i]
			end
		else
			t[k]=target
		end
	end

	return t--targets
end

complex_command.condition=function(battle,machine,...)
	local Complex_Command_Machine=require('battle.ComplexCommandMachine')
	local CCMachine=Complex_Command_Machine.NewMachine()

	local arg=StringDecode.TransToDic({...})	
	local bool_target,t={},{}

	local stack  ,key_link	=machine.stack ,machine.key_link
	local condition = StringDecode.Trim_To_Simple_Command(key_link.card.condition) 
	--print('condition',TableFunc.Dump(condition))
	SCMachine:ReadEffect(battle ,condition , key_link)
	local result = TableFunc.Pop(SCMachine.stack)
	for k,v in pairs(result) do
		if type(v)~='boolean' then
			result[k]=tonumber(result[k]) > 0 and true or false
		end
		--print(result[k])
	end

	for k,v in pairs(result) do

		local bool =tostring(v)
		if arg[bool] and #result > 1 then
			local command =arg[bool]
			local target_string = command:match('(%a+)$')
			local new_target = target_string

			if not target_string:find('%(') then
				new_target = target_string..'('..k..')'
			else
				
			end
			
			command = command:gsub(target_string ,new_target)
			--print('condition command',new_target ,command)
			SCMachine:ReadEffect(battle ,new_target , key_link)
			local target = TableFunc.Pop(SCMachine.stack)
			local temp_key_link = TableFunc.ShallowCopy(key_link)
			temp_key_link.target_table =target
			--CCMachine:ReadEffect(battle , command ,temp_key_link)
			CCMachine:ReadEffect(battle , command ,temp_key_link,'p')
			local result=TableFunc.Pop(CCMachine.result) 
			--print('result',result)
			--TableFunc.Dump(result)

			if TableFunc.IsDictionary(result) then
				TableFunc.Push(t ,result)
			else

			end
			--print('t',t)
			--TableFunc.Dump(t)
		elseif arg[bool] then
			--print('bool type 2 :',bool  )
			local command =arg[bool]
			CCMachine:ReadEffect(battle , command ,key_link)
			t=TableFunc.Pop(CCMachine.result)
		end
	end
	return t
end

complex_command.state_atk=function(battle,machine,...)
	local t = 	{
		key ='set_hp_value',
		value=0,
		value_state={}
	}
	local stack  ,key_link	=machine.stack ,machine.key_link	
	local value  ={...}
	local target_string = TableFunc.Shift(value)

	--print('value!',value)
	--TableFunc.Dump(value)
	for k,v in pairs(value) do
		value[k] = v *-1
	end
	t.value = value
	t.target = target_string

	return t

end
complex_command.heal=function(battle,machine,...)
	local t = 	{
		key ='set_hp_value',
		value=0,
		value_state={
			{'holder', 'use_buff_card'} ,
			{'target', 'buff' } ,
		}
	}
	local stack  ,key_link	=machine.stack ,machine.key_link	
	local value  ={...}
	local target_string = TableFunc.Shift(value)

	--print('atk target_string',target_string)
	--print('before buff_value')
	--TableFunc.Dump(value)
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string  = v[1] , v[2] 
		value = final_process.buff_value(battle ,target_string ,state_table_string ,key_link ,value)	
	end
	--print('value!',value)
	--TableFunc.Dump(value)
	for k,v in pairs(value) do
		value[k] = v *-1
	end
	t.value = value
	t.target = target_string

	return t

end

complex_command.atk=function(battle,machine,...)
	local t = 	{
		protect = true,
		shield  = true,
		key ='set_hp_value',
		value=0,
		value_state={
			{'holder', 'use_atk_card'} ,
			{'target', 'be_atk' } ,
		}
	}
	local stack  ,key_link	=machine.stack ,machine.key_link	
	local value  ={...}
	local target_string = TableFunc.Shift(value)

	SCMachine:ReadEffect(battle ,target_string , key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	if TableFunc.IsDictionary(targets) then targets ={targets} end
	--print('target_string',target_string ,#targets)
	t.target = targets
	--print('atk target_string',target_string)
	--print('before buff_value')
	--TableFunc.Dump(value)
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string  = v[1] , v[2]

		SCMachine:ReadEffect(battle ,target_string , key_link )
		targets =TableFunc.Pop(SCMachine.stack)

		if state_table_string=='be_atk' and t.protect then
			targets = check_protect(targets ,battle)
			t.target = targets
			--[[for i,j in pairs(targets) do
				print(j.data.team_index)
			end]]
		end

		--print('value_state' ,target_string ,state_table_string)
		value = final_process.buff_value(battle ,targets ,state_table_string ,key_link ,value)	--target_string
	end
	--print('value!',value)
	--TableFunc.Dump(value)
	for k,v in pairs(value) do
		value[k] = v *-1
	end
	t.value = value
	

	return t
end
complex_command.ignore_shield_attack=function(battle,machine,...)
	local t = 	{
		protect = true,
		shield  = false,
		key ='set_hp_value',
		value=0,
		value_state={
			{'holder', 'use_atk_card'} ,
			{'target', 'be_atk' } ,
		}
	}
	local stack  ,key_link	=machine.stack ,machine.key_link	
	local value  ={...}
	local target_string = TableFunc.Shift(value)

	--print('atk target_string',target_string)
	--print('before buff_value')
	--TableFunc.Dump(value)
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string  = v[1] , v[2] 
		value = final_process.buff_value(battle ,target_string ,state_table_string ,key_link ,value)	
	end
	--print('value!',value)
	--TableFunc.Dump(value)
	for k,v in pairs(value) do
		value[k] = v *-1
	end
	t.value = value
	t.target = target_string

	return t

end
complex_command.def=function(battle,machine,...)
	local stack  ,key_link	=machine.stack ,machine.key_link	
	local value  ={...}
	local target_string = TableFunc.Shift(value)
	local t = 	{
		key = 'set_value',
		sub_key={'shield','0~999'},
		value=0,
		value_state={
			{'holder', 'use_def_card'} ,
			{'target', 'be_def' } ,
		}
	}
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string  = v[1] , v[2] 
		value = final_process.buff_value(battle ,target_string ,state_table_string ,key_link ,value)	
	end

	t.value = value
	t.target = target_string

	return t
end
complex_command.protect=function(battle,machine,...)
	local t = 	{
		key ='protect',
	}
	SCMachine.stack = TableFunc.DeepCopy(machine.stack)
	local  target ,value =...
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	targets =TableFunc.Pop(SCMachine.stack)
	machine.key_link.target_table=targets 

	for k,target in pairs(targets) do
		local state_table = target.state.protect
		if #state_table > 0 then
			TableFunc.Pop(state_table)
			TableFunc.Push(state_table , machine.key_link.card.holder)
		end
	end	
	return t
end
complex_command.push=function(battle,machine,...)

	local  target ,value =...
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	local race = TableFunc.Find(battle.characterData.heroData) and battle.characterData.heroData or battle.characterData.monsterData

	for i =#targets , 1 ,-1 do
		local target = targets[i]
		for j=1,value do
			local index = target.data.team_index
			if index+1 <= #race then
				target.data.team_index = index+1 
				race[index+1].data.team_index = index
				TableFunc.Swap(race , index ,index+1)
			end
		end
	end

end
complex_command.pull=function(battle,machine,...)
	local  target ,value =...
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)
	local race = TableFunc.Find(battle.characterData.heroData) and battle.characterData.heroData or battle.characterData.monsterData

	for i =1 , #targets  do
		local target = targets[i]
		for j=1,value do
			local index = target.data.team_index
			if index-1 >= 1 then
				target.data.team_index = index-1 
				race[index-1].data.team_index = index
				TableFunc.Swap(race , index ,index-1)
			end
		end
	end
end

complex_command.assign_value=function(battle,machine,...)
	local bool_map={}
	bool_map["true"]	=true
	bool_map["false"]	=false
	local  target_string ,value ,key = ...
	--print('assign_value ,key ',value ,key)
	SCMachine:ReadEffect(battle ,target_string , machine.key_link )
	local targets = TableFunc.Pop(SCMachine.stack)
	for k,target in pairs(targets) do
		if tonumber(value) then
			target.data[key] = tonumber(value) 
		elseif bool_map[value] then
			target.data[key] = bool_map[value]
		else
			target.data[key] = value 
		end
	end


end
complex_command.grow_up_and_atk=function(battle,machine,...)
	local t = 	{
		key = 'atk',
		symbol = '+'
	}
	local stack  ,key_link	=machine.stack ,machine.key_link
	local target  =...
	local value   = 1
	--print('complex_atk ',target , value)
	final_process.set_value(battle , machine ,target ,value ,t)

	local master = key_link.holder
	complex_command.atk(battle , machine ,target ,holder.data.atk )		
end
complex_command.add_buff=function(battle,machine,...)
	local StateHandler = require('battle.StateHandler')
	local key_link ,stack = machine.key_link ,machine.stack 
	local target ,key = ...

	local t ={		
		value_state={
			{'holder', 'use_debuff_card'} ,
			{'target', 'receive_debuff'} ,
		},
		
	}
	
	local value_key = key:match("%((.-)%)")
	value_key = value_key:sub(value_key:find(':')+1,#value_key)

	local t_key =value_key:match("[^%.]*$")
	
	
	--local value =value_key:match("[^%.]*$")
	print('add_buff',target  ,value_key ,t_key )
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string = v[1] , v[2]
		value = final_process.buff_value(battle ,target_string ,state_table_string ,key_link ,value)	
	end
	t.value_key = value
	--[[SCMachine:ReadEffect(battle ,'holder', machine.key_link )
	local holder = TableFunc.Pop(SCMachine.stack)

	--print('complex_command target2 ',target)
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)

	local race = TableFunc.Find(battle.characterData.heroData , holder) and 'hero ' or 'monster '
	local caster = race..TableFunc.GetSerial(holder)
	StateHandler.AddBuff(battle ,targets ,key ,caster)]]
end

return complex_command

