local TableFunc		= require('lib.TableFunc')
local StringDecode  = require('lib.StringDecode')

local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local SCMachine=Simple_Command_Machine.NewMachine()
local final_process = require('battle.command_act.final_process')

local complex_command={}
TableFunc.Merge(complex_command,final_process)

complex_command.condition=function(battle,machine,...)
	local Complex_Command_Machine=require('battle.ComplexCommandMachine')
	local CCMachine=Complex_Command_Machine.NewMachine()
	--print('condition')
	--TableFunc.Dump(arg)
	local arg=StringDecode.TransToDic({...})	
	local bool_target={}
	--TableFunc.Dump(arg)

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

	for key,v in pairs(arg) do
		local complete  = StringDecode.Trim_Command(v)
		local target_string = complete[#complete]

		SCMachine:ReadEffect(battle ,target_string , key_link)
		local target = TableFunc.Pop(SCMachine.stack)
		bool_target[key] = target
	end
	--[[ result & bool_target可能的結果:
			result & bool_target長度一致  ->依照result 分別執行
			#result ==1 -> 取 result 的結果來執行
		]]

	for k,v in pairs(result) do

		local bool =tostring(v)
		if arg[bool] and #result == #bool_target[bool] then
			--print('bool type 1 :',bool ,#bool_target[bool] ,bool_target[bool][k]  )
			local command =arg[bool]
			local temp_key_link = TableFunc.ShallowCopy(key_link)
			temp_key_link.target_table ={bool_target[bool][k]}
			CCMachine:ReadEffect(battle , command ,temp_key_link)
		elseif arg[bool] and #result==1 then
			--print('bool type 2 :',bool  )
			local command =arg[bool]
			CCMachine:ReadEffect(battle , command ,key_link)
		end
	end
end

complex_command.state_atk=function(battle,machine,...)
	local t = 	{
		value_state={
			{'holder', 'use_debuff_card'} ,
			{'target', 'be_debuff' } ,
		},
		key = 'hp',
		symbol = '-'
	}
	local  target ,value =...
	--print('complex_state_atk ',target , value)
	final_process.set_hp_value(battle , machine ,target ,value ,t)
end
complex_command.heal=function(battle,machine,...)
	local t = 	{
		value_state={
			{'holder', 'use_buff_card'} ,
			{'target', 'buff' } ,
		},
		key = 'hp',
		symbol = '+'
	}
	local  target ,value =...
	--print('complex_heal ',target , value)
	final_process.set_hp_value(battle , machine ,target ,value ,t)
end
complex_command.set_final=function(battle,machine,...)
	local  target ,value ,t =...
	--print('complex_atk ',target , value)
	final_process.set_hp_value(battle , machine ,target ,value ,t)
end

complex_command.atk=function(battle,machine,...)

	local t = 	{
		protect = true,
		shield  = true,
		value_state={
			{'holder', 'use_atk_card'} ,
			{'target', 'be_attacked' } ,
		},
		key = 'hp',
		symbol = '-'
	}
	local stack  ,key_link	=machine.stack ,machine.key_link
	
	local  target ,value =...
	print('atk ',target ,value)
	--[[final_process.set_hp_value(battle , machine ,target ,value ,t)

	machine.state_update={'use_atk_card' ,'be_attacked' }]]
	for k,v in pairs(t.value_state) do
		local target_string ,state_table_string = v[1] , v[2]
		value = final_process.buff_value(battle ,target_string ,state_table_string ,key_link ,value)	
	end
	local final = value
	--print('final',final)
	return final
end
complex_command.ignore_shield_attack=function(battle,machine,...)
	local t = 	{
		protect = true,
		shield  = false,
		value_state={
			{'holder', 'use_atk_card'} ,
			{'target', 'be_attacked' } ,
		},
		key = 'hp',
		symbol = '-'
	}
	local stack  ,key_link	=machine.stack ,machine.key_link
	local  target ,value =...
	--print('complex_atk ',target , value)
	final_process.set_hp_value(battle , machine ,target ,value ,t)

	--machine.state_update={'use_atk_card' ,'be_attacked' }
end
complex_command.protect=function(battle,machine,...)

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
complex_command.def=function(battle,machine,...)
	local  target ,value =...
	local t = 	{
		key = 'shield',
		symbol = '+'
	}
	print('complex_def ',target , value)	
	final_process.set_value(battle , machine ,target ,value ,t)
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

	print('add_buff',target , key)
	SCMachine:ReadEffect(battle ,'holder', machine.key_link )
	local holder = TableFunc.Pop(SCMachine.stack)

	--print('complex_command target2 ',target)
	SCMachine:ReadEffect(battle ,target , machine.key_link )
	local targets =TableFunc.Pop(SCMachine.stack)

	local race = TableFunc.Find(battle.characterData.heroData , holder) and 'hero ' or 'monster '
	local caster = race..TableFunc.GetSerial(holder)
	StateHandler.AddBuff(battle ,targets ,key ,caster)
end

return complex_command

