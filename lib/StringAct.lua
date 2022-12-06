local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Basic_act =require('lib.command_act.basic_act')
local Combine_act = require('lib.command_act.combine_act')
local Deck_act = require('lib.command_act.deck_act')
TableFunc.Merge(Basic_act,Combine_act)
TableFunc.Merge(Basic_act,Deck_act)

local universal_func = require('lib.command_act.universal_func')


local StringAct={}

local function analysis(str,machine,battle)

	local stack ,effect = machine.stack ,machine.effect
	
	local arg ,copy_scope

	local command = str
	
	if not tonumber(command) and type(command)~='table' then
		--處理key[arg...]中間沒有空隔相連的狀況
		if command:find('%[') then
			local left = command:find('%[') 
			local str_left = command:sub(1,left-1)
			local str_right = command:sub(left ,#command)
			command=str_left ..' '..str_right
		end
		arg ,copy_scope = StringDecode.Split_Command(command)
		arg={StringDecode.split_by(arg[1],'%s')}

		arg=StringDecode.Replace_copy_scope(arg,copy_scope)
	end

	if tonumber(str) then
		command =tonumber(str)
	elseif arg then
		command = TableFunc.Shift(arg)
	end

	if arg then
		for i=#arg ,1 ,-1 do
			--arg當中 被[]包含的部分會被視為前一個arg(arg[i-1])的參數
			arg[i]=StringDecode.trim_head_tail(arg[i]) 
			local len ,value = 0 ,arg[i]
			local left ,right = value:find('%[') , 0
			if left then
				right =StringDecode.FindCommandScope(left+1, value ,'[',']')
				len =right-left+1
			end
			if left and len ==#value and #arg >1 then
				local parameter = ' '..arg[i]
				assert(arg[i-1],'out of range')
				arg[i-1]=arg[i-1]..parameter
				table.remove(arg,i)
			end
		end
	end

	return command ,arg
end
function StringAct.NewMachine()
	local Wait = State.new("Wait")
	local Compare = State.new("Compare")
	local Calculate= State.new("Calculate")
	local Normal = State.new("Normal")

	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait  ,Compare ,Calculate,Normal
		},
		events={

			{state=Wait,global=true,self=true},
			{state=Compare,global=true,self=true},
			{state=Calculate,global=true,self=true},						
			{state=Normal,global=true,self=true},
		}
	})
	machine.stop=false
	machine.stack={}
	machine.record={}

	Wait.Do=function(self,battle,...)
		if not stop then
			machine.index=machine.index+1
			local command = machine.effect[machine.index]
			local arg
			command,arg=analysis(command , machine ,battle)

			if tonumber(command) then
				TableFunc.Push(machine.stack,tonumber(command))

			elseif type(command)=='table' then
				TableFunc.Push(machine.stack,command)

			elseif command:find('(%a+%.%a+)')then
				local StringRead = require('lib.StringRead')
				command=command:gsub('%.',' ,get ')
				local act = {StringDecode.split_by(command,',')}
				for i=#act,1,-1 do
					table.insert(machine.effect, machine.index+1 , act[i])
				end

			elseif universal_func.findSymbol(command ,'compare') then
				machine:TransitionTo('Compare',command,battle,arg)

			elseif universal_func.findSymbol(command ,'calculate') then
				machine:TransitionTo('Calculate',command,battle,arg)
			else
				machine:TransitionTo('Normal',command,battle,arg)
			end
			
			
		end

	end

	Compare.DoOnEnter=function(self,command,battle,arg,...)
		--print('Compare command',command )
		local num = tonumber(command:match('%d')) and tonumber(command:match('%d')) or table.unpack(arg)
		local symbol = StringDecode.trim_head_tail(command:gsub(num,'')) 
		--local arg = {s,num}--StringDecode.split_by(command,'%s')
		local value = Basic_act['compare'](battle,machine,symbol,num)
		machine:TransitionTo('Wait')
	end

	Calculate.DoOnEnter=function(self,command,battle,arg,...)
		--print('Calculate command',command )
		--local arg = {StringDecode.split_by(command,'%s')}
		local arg=arg
		for k,v in pairs(arg) do
			arg[k]=tonumber(v)
		end
		local value = Basic_act['calculate'](battle,machine,command,table.unpack(arg))
		machine:TransitionTo('Wait')
	end
 
	Normal.DoOnEnter=function(self,command,battle,arg,...)
		--print('normal command',command )
		local key ,arg =command ,arg
		--arg = {StringDecode.split_by(command,'%s')}
		--key = StringDecode.trim_head_tail(TableFunc.Shift(arg)) 

		if key:find('input_target')then
			local num = key:match('%d+')
			TableFunc.Push(arg ,num)
		end
		--print('key',key)
		assert(Basic_act[key],'act['..key..'] is nil')

		local value = Basic_act[key](battle,machine,table.unpack(arg))
		if value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')

	end
	return machine

end
function StringAct.ReadEffect(battle ,machine ,effect ,toUse ,print_log)
	machine.toUse=toUse
	machine.effect=TableFunc.DeepCopy(effect)
	machine.index=0
	while not machine.stop and machine.index < #machine.effect do
		machine:Update(battle)
		if print_log then
			print('command:',machine.effect[machine.index])
			print(TableFunc.Print_one_line(machine.stack),'\n')
		end
	end
end

return StringAct