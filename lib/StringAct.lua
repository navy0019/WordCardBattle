local StringRead = require('lib.StringRead')
local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local StringAct={}
local compare_map={'>','<','==','>=','<='}
local calculate_map={'sum','minus','multiplie','divided'}
local function FindSymbol(str,t)
	for k,v in pairs(t) do
		if str:find(v) then
			return k
		end
	end
end
local function RemakeArg(arg)
	local str=''
	local t={}
	local index=1 
	for k,v in pairs(arg) do
		str=str..' '..v
	end
	--print('str!',str,#str)
	while index < #str do
		if str:find('%]',index) then
			local p=str:find('%]',index)		
			local new_str = str:sub(index,p)
			new_str=StringDecode.trim_head_tail(new_str)
			--print('p~',p,new_str)
			TableFunc.Push(t,new_str)
			index = p+1
		else
			index=index+1
		end		
	end

	return t
end
local function MakeAct(command)
	local act={}										
	scope_start= command:find('%[')
	scope_end  = command:find('%]')
	local str = command:sub(scope_start+1,scope_end-1)					
	local temp={StringDecode.split_by(str,',')}
	for k,v in pairs(temp) do
		local w=StringDecode.trim_head_tail(v)							
		TableFunc.Push(act , w)
	end
	return act
end
local actMap={
		get= function(machine,effect,stack,toUse,...)
			--print('get')
			local target =TableFunc.Pop(stack)
			local arg=...
			
			local t={}
			for k,v in pairs(target) do
				local value 
				if type(v.data[arg])=='string' then
					value=StringRead.StrToValue(v.data[arg] ,v)
				else
					value=v.data[arg]
				end
				TableFunc.Push(t , value) 
			end
			TableFunc.Push(stack ,t)
		end,

		set= function(machine,effect,stack,toUse,...)
			--print('set somthing')
			local target =TableFunc.Pop(stack)
			local value  =TableFunc.Pop(stack)
			local arg=...
			for k,character in pairs(target) do
				for i,v in pairs(value) do
					character.data[arg]=v
				end				
			end
		end,

		card=function(machine,effect,stack,toUse,...)
			TableFunc.Push(stack ,{toUse.card}) 
			--TableFunc.Dump(toUse.card)
		end,

		select_target=function(machine,effect,stack,toUse,...)
			TableFunc.Push(stack ,toUse.select_table) 
		end,

		input_target=function(machine,effect,stack,toUse,...)
			local num =... or 1
			TableFunc.Push(stack ,toUse['input_target_'..num])  
		end,
		melee=function(machine,effect,stack,toUse,...)
			local atk_value = TableFunc.Pop(stack)
			local tab={
				atk_value,	
				'select_target','get team_index',
				'> 2','boolean true[2,divided]',
			}
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,
		built_in_atk=function(machine,effect,stack,toUse,...)
			local arg={...}
			local atk_type=TableFunc.Shift(arg)
			local atk_value = TableFunc.Shift(arg)
			if tonumber(atk_value) then
				atk_value = tonumber(atk_value)
			else
				atk_value = StringRead.StrToValue(atk_value ,toUse.card)
			end
			local condition
			if atk_type =='melee' then condition ='> 2'end
			if atk_type =='range' then condition ='< 2'end
			if atk_type =='magic' then condition ='> 4'end

			local tab={
				'select_target','get shield',
				atk_value ,atk_type ,'minus',
				'select_target','set shield',
				'select_target','get shield',
				'< 0' ,'boolean true[select_target,get shield,select_target, get hp,sum] false[stop]'
			}
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,

		boolean=function(machine,effect,stack,toUse,...)			
			local bool_tab = TableFunc.Pop(stack)
			local arg={...}	--裡面必須是{true[xxx] ,false[xxx]}	
			local scope_start,scope_end
			--[[if #arg>2 then
				arg=RemakeArg(arg)
			end]]
			--print('bool tab',bool_tab)
			for k,bool in pairs(bool_tab) do
				for i,command in pairs(arg) do
					if command:find(tostring(bool))then
						local act=MakeAct(command)
						--StringAct.Act(stack,act,toUse)
						for i=#act,1,-1 do
							table.insert(effect, machine.index+1 , act[i])
						end
					end
				end
			end

		end,
		stop=function(machine,effect,stack,toUse,...)
			print('stop!')
			return 'stop'
		end,
		calculate=function(machine,effect,stack,toUse,...)
			local func = {
				function(a,b)return a+b end,
				function(a,b)return a-b end,
				function(a,b)return a*b end,
				function(a,b)return math.floor(a/b) end
			}
			local v1 = TableFunc.Pop(stack)
			local v2 = TableFunc.Pop(stack)
			local b = tonumber(v1) and tonumber(v1) or v1
			local a = tonumber(v2) and tonumber(v2) or v2
			local key = ...
			--print('calculate key',key,a,b)
			local index =FindSymbol(key,calculate_map)
			local t={}
			if type(a)=='table' and type(b)~='table' then
				for k,v in pairs(a) do
					local value=func[index](v,b) 
					TableFunc.Push(t,value)
				end
				TableFunc.Push(stack, t)
			elseif type(a)~='table' and type(b)=='table' then
				for k,v in pairs(b) do
					local value=func[index](a,v) 
					TableFunc.Push(t,value)
				end
				TableFunc.Push(stack, t)
			elseif type(a)~='table' and type(b)~='table' then
				local value = func[index](a,b)
				TableFunc.Push(stack, value)
			elseif type(a)=='table' and type(b)=='table' then
				local max = #a > #b and a or b
				local other = #a < (#b) and a or b
				for k,v in pairs(max) do
					if other[k] then
						local value=func[index](a[k] ,b[k]) 
						TableFunc.Push(t,value)
					end
				end
				TableFunc.Push(stack, t)
			end
		end,
		compare=function(machine,effect,stack,toUse,...)
			local func={
				function(a,b) return a>b end,
				function(a,b) return a<b end,
				function(a,b) return a==b end,
				function(a,b) return a>=b end,
				function(a,b) return a<=b end
			}
			local arg={...}
			local key =arg[1]
			local value=TableFunc.Pop(stack)
			local a = tonumber(value) and tonumber(value) or value
			local b = tonumber(arg[2]) and tonumber(arg[2]) or arg[2]
			local index =FindSymbol(key,compare_map)
			local t={}
			if type(a)=='table' and type(b)~='table' then
				for k,v in pairs(a) do
					TableFunc.Push(t,func[index](v,b))
				end
				TableFunc.Push(stack, t)
			elseif type(a)~='table' and type(b)=='table' then
				for k,v in pairs(b) do
					TableFunc.Push(t,func[index](a,v))
				end
				TableFunc.Push(stack, t)
			elseif type(a)~='table' and type(b)~='table' then
				local value = func[index](a,b)
				TableFunc.Push(stack, value)
			elseif type(a)=='table' and type(b)=='table' then
				local max = #a > #b and a or b
				local other = #a < (#b) and a or b
				for k,v in pairs(max) do
					if other[k] then
						local value=func[index](a[k] ,b[k]) 
						TableFunc.Push(t,value)
					end
				end
				TableFunc.Push(stack, t)
			end			
		end,

}

function StringAct.NewMachine(stack,effect,toUse)
	local Wait = State.new("Wait")
	local Compare = State.new("Compare")
	local Calculate= State.new("Calculate")
	local Act= State.new("Act")
	local Normal = State.new("Normal")
	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait  ,Act,Compare ,Calculate,Normal
		},
		events={
			--[[ 	Wait(global)					
			 Classification-->CheckBuff--> ReadEffect
     					 				]]
			{state=Wait,global=true,self=true},
			{state=Compare,global=true,self=true},
			{state=Calculate,global=true,self=true},
			{state=Act,global=true,self=true},							
			{state=Normal,global=true,self=true},
		}
	})
	machine.stop=false
	machine.index=0
	machine.effect=effect
	machine.stack={}
	machine.toUse=toUse
	Wait.Do=function(self,...)
		if not stop then
			machine.index=machine.index+1
			local command = machine.effect[machine.index]
			--print('wait command',command)
			local arg={}
			if tonumber(command) then
				--print('is number')
				TableFunc.Push(machine.stack,tonumber(command))

			elseif command:find('%[') then
				machine:TransitionTo('Act',command)

			elseif FindSymbol(command ,compare_map) then
				machine:TransitionTo('Compare',command)

			elseif FindSymbol(command ,calculate_map) then
				machine:TransitionTo('Calculate',command)

			else
				machine:TransitionTo('Normal',command)
			end
			
			
		end

	end
	Act.DoOnEnter=function(self,command,...)
		local arg={}
		local index=1
		local key
		if command:find('boolean') then
			command=command:gsub('boolean','')						
			key='boolean'
		elseif command:find('repeat') then
			command=command:gsub('repeat','')						
			key='repeat'
		end
		--print('Act command',command)
		while index < #command do
			if command:find('%]',index) then
				local p=command:find('%]',index)		
				local new_str = command:sub(index,p)
				new_str=StringDecode.trim_head_tail(new_str)
				--print('new_str',new_str)
				TableFunc.Push(arg,new_str)
				index=p+1
			else
				index=index+1
			end	
		end

		local value = actMap[key](machine, machine.effect ,machine.stack , machine.toUse ,table.unpack(arg))
		if value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')
	end

	Compare.DoOnEnter=function(self,command,...)
		local arg = {StringDecode.split_by(command,'%s')}
		local value = actMap['compare'](machine, machine.effect ,machine.stack , machine.toUse,table.unpack(arg))
		machine:TransitionTo('Wait')
	end

	Calculate.DoOnEnter=function(self,command,...)
		local arg = {StringDecode.split_by(command,'%s')}
		local value = actMap['calculate'](machine, machine.effect ,machine.stack , machine.toUse ,table.unpack(arg))
		machine:TransitionTo('Wait')
	end

	Normal.DoOnEnter=function(self,command,...)
		--print('normal command',command)
		local arg = {StringDecode.split_by(command,'%s')}
		local key = TableFunc.Shift(arg)
		if key:find('input_target')then
			print('normal ',key)
			local num = key:match('%d+')
			TableFunc.Push(arg ,num)
		end
		assert(actMap[key],'act['..key..'] is nil')
		local value = actMap[key](machine, machine.effect ,machine.stack , machine.toUse,table.unpack(arg))
		if value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')

	end
	return machine

end
function StringAct.ReadEffect(toUse)
	local card = toUse.card
	local effect=TableFunc.Copy(card.effect)
	local stack={}
	local machine=StringAct.NewMachine(stack ,effect,toUse)
	--[[for k,v in pairs(stack) do
		print('stack: '..k,TableFunc.Dump(v))
		print('\n')
	end]]
	--if #stack==0 then print('stack clear')end
	while not machine.stop and machine.index < #machine.effect do
		machine:Update()
		--print(TableFunc.Print_one_line(machine.stack))
	end
	--TableFunc.Dump(toUse.select_table)
end
return StringAct