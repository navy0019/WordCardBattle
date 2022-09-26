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

function StringAct.NewMachine(effect,toUse ,battle)
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
	machine.record={}

	Wait.Do=function(self,battle,...)
		if not stop then
			machine.index=machine.index+1
			local command = machine.effect[machine.index]
			--print('stringAct wait command',command)
			local arg={}
			if tonumber(command) then
				TableFunc.Push(machine.stack,tonumber(command))

			elseif type(command)=='table' then
				TableFunc.Push(machine.stack,command)

			elseif command:find('%[') then
				machine:TransitionTo('Act',command,battle)

			elseif FindSymbol(command ,compare_map) then
				machine:TransitionTo('Compare',command,battle)

			elseif FindSymbol(command ,calculate_map) then
				machine:TransitionTo('Calculate',command,battle)

			else
				machine:TransitionTo('Normal',command,battle)
			end
			
			
		end

	end
	Act.DoOnEnter=function(self,command,battle,...)
		--print('Act command',command)
		local arg ,copy_scope = StringDecode.Split_Command(command)
		arg={StringDecode.split_by(arg[1],'%s')}
		arg=StringDecode.Replace_copy_scope(arg,copy_scope)

		local key = TableFunc.Shift(arg)
		--print('key',key)
		local value = ActMap[key](battle,machine,table.unpack(arg))
		if value and value =='stop' then
			machine.stop=true
		end
		machine:TransitionTo('Wait')
	end

	Compare.DoOnEnter=function(self,command,battle,...)
		--print('Compare command',command )
		local num =command:match('%d')
		local s = StringDecode.trim_head_tail(command:gsub(num,'')) 
		local arg = {s,num}--StringDecode.split_by(command,'%s')
		local value = ActMap['compare'](battle,machine,table.unpack(arg))
		machine:TransitionTo('Wait')
	end

	Calculate.DoOnEnter=function(self,command,battle,...)
		--print('Calculate command',command )
		local arg = {StringDecode.split_by(command,'%s')}
		local value = ActMap['calculate'](battle,machine,table.unpack(arg))
		machine:TransitionTo('Wait')
	end
 
	Normal.DoOnEnter=function(self,command,battle,...)
		--print('normal command',command )
		local arg ,key
		arg = {StringDecode.split_by(command,'%s')}
		key = StringDecode.trim_head_tail(TableFunc.Shift(arg)) 

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
function StringAct.ReadEffect(battle ,machine)
	while not machine.stop and machine.index < #machine.effect do
		machine:Update(battle)
		--print('command:',machine.effect[machine.index])
		--print(TableFunc.Print_one_line(machine.stack),'\n')
	end
end
function StringAct.UseCard(battle ,toUse)
	local card = toUse.card
	local effect=TableFunc.Copy(card.effect)
	--local record={}
	local machine=StringAct.NewMachine(effect,toUse ,battle)

	StringAct.ReadEffect(battle ,machine)
	--[[for k,v in pairs(toUse.target_table) do
		TableFunc.Dump(v.data)
	end]]
	return machine
end
return StringAct