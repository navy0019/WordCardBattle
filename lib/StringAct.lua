local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local ActMap =require('lib.actMap')

local StringAct={}
local compare_map={'>','<','==','>=','<='}
local calculate_map={'sum','minus','multiplie','divided'}
local type_tab={atk={'melee','range','magic','atk'}}

function StringAct.Match_type(except ,card_type)
	for i ,card_key in pairs(card_type) do
		for k ,tab_value in pairs(type_tab) do
			if card_key == except then return true end
			if type(tab_value)=='table' and TableFunc.Find(tab_value ,except) and TableFunc.Find(tab_value ,card_key) then
				return true
			end
		end
	end
	return false
end
local function FindSymbol(str,t)
	for k,v in pairs(t) do
		if str:find(v) then
			return k
		end
	end
end
local function analysis(str,machine,battle)

	local stack ,effect = machine.stack ,machine.effect
	
	local arg ,copy_scope
	local command = str
	if not tonumber(str) and type(str)~='table' then
		arg ,copy_scope = StringDecode.Split_Command(str)
		arg={StringDecode.split_by(arg[1],'%s')}
		arg=StringDecode.Replace_copy_scope(arg,copy_scope)
	end

	if tonumber(str) then
		command =tonumber(str)
	elseif arg then
		command = TableFunc.Shift(arg)
	end
	--print('command',command)
	return command ,arg
end
function StringAct.NewMachine()
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
	machine.stack={}
	machine.record={}

	Wait.Do=function(self,battle,...)
		if not stop then
			machine.index=machine.index+1
			local command = machine.effect[machine.index]
			local arg

			command,arg=analysis(command , machine ,battle)
			--print('command ',command)
			--TableFunc.Dump(arg)
			
			--print('stringAct wait command',command)
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
			elseif command:find('%[') then
				machine:TransitionTo('Act',command,battle,arg)

			elseif FindSymbol(command ,compare_map) then
				machine:TransitionTo('Compare',command,battle,arg)

			elseif FindSymbol(command ,calculate_map) then
				machine:TransitionTo('Calculate',command,battle,arg)
			else
				machine:TransitionTo('Normal',command,battle,arg)
			end
			
			
		end

	end
	Act.DoOnEnter=function(self,command,battle,arg,...)
		--print('Act command',command)

		--local key = TableFunc.Shift(arg)
		local key=command
		--print('key',key)
		local value = ActMap[key](battle,machine,table.unpack(arg))
		if value and value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')
	end

	Compare.DoOnEnter=function(self,command,battle,arg,...)
		--print('Compare command',command )
		local num = tonumber(command:match('%d')) and tonumber(command:match('%d')) or table.unpack(arg)
		local symbol = StringDecode.trim_head_tail(command:gsub(num,'')) 
		--local arg = {s,num}--StringDecode.split_by(command,'%s')
		local value = ActMap['compare'](battle,machine,symbol,num)
		machine:TransitionTo('Wait')
	end

	Calculate.DoOnEnter=function(self,command,battle,arg,...)
		--print('Calculate command',command )
		--local arg = {StringDecode.split_by(command,'%s')}
		local arg=arg
		for k,v in pairs(arg) do
			arg[k]=tonumber(v)
		end
		local value = ActMap['calculate'](battle,machine,command,table.unpack(arg))
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
		assert(ActMap[key],'act['..key..'] is nil')

		local value = ActMap[key](battle,machine,table.unpack(arg))
		if value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')

	end
	return machine

end
function StringAct.ReadEffect(battle ,machine ,effect ,toUse ,print_log)
	machine.toUse=toUse
	machine.effect=TableFunc.Copy(effect)
	machine.index=0
	while not machine.stop and machine.index < #machine.effect do
		machine:Update(battle)
		if print_log then
			print('command:',machine.effect[machine.index])
			print(TableFunc.Print_one_line(machine.stack),'\n')
		end
	end
end
--[[function StringAct.UseCard(battle ,toUse)
	local card = toUse.card
	local effect=TableFunc.Copy(card.effect)
	--local record={}
	--TableFunc.Dump(card)
	local machine=StringAct.NewMachine()

	StringAct.ReadEffect(battle ,machine ,effect,toUse)
	return machine
end]]
return StringAct