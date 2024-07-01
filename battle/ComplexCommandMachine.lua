local StringDecode=require('lib.StringDecode')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Basic_act =require('battle.command_act.simple_command')
local Complex_command = require('battle.command_act.complex_command')
local Deck_act = require('battle.command_act.deck_act')

local TableFunc = require('lib.TableFunc')
TableFunc.Merge(Basic_act,Complex_command)
TableFunc.Merge(Basic_act,Deck_act)

local LoopMap = require('battle.LoopMap')
local Complex_Command_Machine={}


local function analysis(str)
	--print('CCM analysis' ,str)
	local complete ,split = StringDecode.Trim_Command(str)
	--TableFunc.Dump(complete)
	local loop_type
	--[[if #complete> 3 then
		loop_type = split[1]
		if loop_type:find('%(') then
			loop_type =loop_type:gsub('%(.%)','')
		end
	end]]
	if LoopMap[split[1]:match('%a+')] then loop_type = split[1]:match('%a+') end


	--[[TableFunc.Dump(complete)
	print('split ')
	TableFunc.Dump(split)
	print('\n\n')]]
	--print('analysis loop_type',loop_type)
	return complete ,loop_type
end
function Complex_Command_Machine.NewMachine()

	local Wait = State.new("Wait")
	local Make_Loop= State.new("Make_Loop")
	local Excute= State.new("Excute")

	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait  ,Make_Loop ,Excute 
		},
		events={

			{state=Wait,global=true,self=true},
			{state=Make_Loop,global=true,self=true},
			{state=Excute,global=true,self=true},						
		},
		
	})
	machine.stack={}
	machine.record={}
	machine.index=0
	machine.result={}

	Wait.Do=function(self,battle,...)
		
		machine.index=machine.index+1
		local command = machine.commands[machine.index]
		local complete , loop_type=analysis(command)
		--print(complete , loop_type ,#complete)
		--TableFunc.Dump(complete)
		local commands={}

		if loop_type then
			--print('make loop')
			machine:TransitionTo('Make_Loop',battle ,complete ,loop_type)

		elseif #complete == 1 then
			--print('complete ==1')
			TableFunc.Push(commands ,{command=StringDecode.Trim_head_tail(complete[1]), arg={}})
		else
			local target = complete[#complete]
			TableFunc.Push(commands ,{command=StringDecode.Trim_head_tail(complete[1]), arg={target}})
			
		end
		machine:TransitionTo('Excute',battle ,commands)
	end

	Make_Loop.DoOnEnter=function(self,battle,complete,loop_type,...)
		key_link=machine.key_link
		--TableFunc.Dump(complete)
		local num = complete[1]:match('%d+')
		--print('Make_Loop ',num ,#complete ,loop_type)
		assert(num ,'don\'t have loop num')
		local commands={}
		for i=1,num do
			if #complete <= 2 then --condition時 jump視為loop
				TableFunc.Push(commands, {command=complete[2] , arg = {} })
			else
				if loop_type=='jump' and i > 1 then
					TableFunc.Push(commands, {command=complete[2] , arg = {LoopMap[loop_type](battle , key_link)} })
					--TableFunc.Push(commands, {command=complete[2] , target = LoopMap[loop_type](battle , key_link) })
				elseif loop_type=='jump' and i == 1 then
					if #key_link.target_table > 1 then
						TableFunc.Push(commands, {command=complete[2], arg = {'random 1 target (hp > 0)'} })
						--TableFunc.Push(commands, {command=complete[2], target = 'random 1 target (hp > 0)' })
					else
						TableFunc.Push(commands, {command=complete[2] , arg = {'target'} })
						--TableFunc.Push(commands, {command=complete[2] , target = 'target' })
					end
				else
					TableFunc.Push(commands, {command=complete[2] , arg = {'target (hp > 0)'} })
					--TableFunc.Push(commands, {command=complete[2] , target = 'target (hp > 0)' })
				end
			end
		end
		machine:TransitionTo('Excute',battle ,commands)
	end
	

	Excute.DoOnEnter=function(self,battle,commands,...)

		for k,v in pairs(commands) do
			--print('command',v.command)
			
			local key ,arg = StringDecode.Split_Command_Arg(v.command)
			--print('arg',arg)
			--TableFunc.Dump(arg)
			key =StringDecode.Trim_head_tail(key)
			print('\n\nExcute: ',key ,v.command )
			--TableFunc.Dump(v.arg)
			--TableFunc.Dump(arg)
			--Complex_command[key](battle , machine ,v.command  ,v.target)
			local result =Complex_command[key](battle , machine ,table.unpack(v.arg) ,table.unpack(arg))
			TableFunc.Push(machine.result ,result)
		end

		machine:TransitionTo('Wait')

	end


	function machine:ReadEffect(battle ,command ,key_link ,print_log)
		local commands = type(command)=='table' and command or {command}
		self.key_link=key_link

		self.commands=TableFunc.DeepCopy(commands)
		--print('commands ',#commands)
		--TableFunc.Dump(commands)
		self.index=0
		while  self.index < #self.commands do
			self:Update(battle)
			if print_log then
				print('Complex_Command_Machine:',self.commands[self.index])
				--print(TableFunc.Print_one_line(self.stack),'\n')
			end
		end
		--TableFunc.Dump(machine.result)
	end
	return machine

end


return Complex_Command_Machine