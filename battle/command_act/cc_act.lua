local TableFunc		= require('lib.TableFunc')
local StringDecode  = require('lib.StringDecode')
local StringRead 	= require('lib.StringRead')
local MathExtend 	= require('lib.math')

local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local SCMachine=Simple_Command_Machine.NewMachine()

local cc_act={

	condition=function(battle,machine,...)
		local Complex_Command_Machine=require('battle.ComplexCommandMachine')
		local CCMachine=Complex_Command_Machine.NewMachine()
		local con_arg =...
		local arg=StringDecode.TransToDic(con_arg)	
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
		end

		for k,v in pairs(result) do

			local bool =tostring(v)
			if arg[bool] and #result > 1 then
				local command =arg[bool]
				local target_string = command:match('(%a+)$')
				local new_target = target_string

				if not target_string:find('%(') then
					new_target = target_string..'('..k..')'
				end
				
				command = command:gsub(target_string ,new_target)
				--print('condition command', ,command)
				SCMachine:ReadEffect(battle ,new_target , key_link)
				local target = TableFunc.Pop(SCMachine.stack)
				local temp_key_link = TableFunc.ShallowCopy(key_link)
				temp_key_link.target_table =target

				CCMachine:ReadEffect(battle , command ,temp_key_link)--
				local result=TableFunc.Pop(CCMachine.result) 
				--print('result',command)
				--TableFunc.Dump(result)

				if TableFunc.IsDictionary(result) then
					TableFunc.Push(t ,result)
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
	end,
	calculate_value=function(battle,machine,...)
		local arg =...
		--print('calculate_value',arg)
		--TableFunc.Dump(arg)
		SCMachine.stack = machine.stack
		local target_string ,value ,limit =table.unpack(arg)

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
		--print('calculate_value ',target_string ,value ,limit )
		local is_dic = type(target_string)=='string' and target_string:find('%.') or false
		SCMachine:ReadEffect(battle, target_string , machine.key_link )
		local target_entity = TableFunc.Pop(SCMachine.stack) 
		--print('calculate_value target_entity')
		--TableFunc.Dump(SCMachine.stack)

		if TableFunc.IsArray(target_entity) then
			--print('calculate_value IsArray')
			local t={}
			for k,v in pairs(target_entity) do
				
				local final_value=v..value
				--print('before ',final_value)
				final_value = StringRead.StrToValue(final_value ,machine.key_link ,battle)

				if limit then final_value = MathExtend.clamp(final_value, min,max)end
				--print('after ',final_value)
				if is_dic then
					local key = target_string:sub(target_string:find('%.')+1 ,#target_string)
					local temp =final_value
					final_value ={}
					final_value[key]=temp
				end
				TableFunc.Push(t,final_value)
			end
			if #t > 0 then TableFunc.Push(machine.stack , t) end

		else
			
			value=target_entity..value	

			value = StringRead.StrToValue(value ,machine.key_link ,battle)
			if limit then value = MathExtend.clamp(value, min,max)end
			--print('calculate_value not array ',value)
			if is_dic then
				local key = target_string:sub(target_string:find('%.')+1 ,#target_string)
				local temp =value
				value ={}
				value[key]=temp
			end
			TableFunc.Push(machine.stack , value)
		end
	end,

}

return cc_act