local StringDecode=require('lib.StringDecode')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Basic_act =require('battle.command_act.simple_command')
local Complex_command = require('battle.command_act.complex_command')
local Deck_act = require('battle.command_act.deck_act')
local CC_T=require('battle.command_act.cc_t')

local TableFunc = require('lib.TableFunc')
TableFunc.Merge(Basic_act,Complex_command)
TableFunc.Merge(Basic_act,Deck_act)

local loop_map={
	jump=function(battle , key_link)
		--print('key_link',key_link.self)
		--TableFunc.Dump(key_link.self)
		local card = key_link.self
		local basic_number ,race
		for k,v in pairs(card.use_condition) do
			if not v[3]:find('card') then
				basic_number = v[2]
				race =v[3]
				break
			end

		end
		--TableFunc.Dump(card.use_condition)
		
		local data = race =='enemy' and battle.characterData.monsterData or battle.characterData.heroData 
		--print( race ,#data)
		local command ='random ('..basic_number..' ,'..race ..'(hp > 0))'
		--print('jump ',command)
		return command

	end,
	loop=function(battle , key_link)
		return 'target (hp > 0)'
	end
}

local Complex_Command_Machine={}

local function analysis(str,machine)
	--print('CCM analysis' ,str)
	local complete ,split = StringDecode.Trim_Command(str)
	--TableFunc.Dump(complete)
	--TableFunc.Dump(machine.stack)
	local loop_type
	--[[if #complete> 3 then
		loop_type = split[1]
		if loop_type:find('%(') then
			loop_type =loop_type:gsub('%(.%)','')
		end
	end]]
	if loop_map[split[1]:match('%a+')] then loop_type = split[1]:match('%a+') end
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
		local complete , loop_type=analysis(command ,machine)
		--print(complete , loop_type ,#complete)
		--TableFunc.Dump(complete)
		local target_string = complete[#complete]
		local key ,nextkey
		if loop_type then
			key =complete[2]
		else
			key =complete[1]
		end
		if machine.index+1 <= #machine.commands then
			nextkey = machine.commands[machine.index+1]
		end

		--[[if (target_string:find('%.') and not key:find('set_value')) or (nextkey and not nextkey:find('set_value'))  then
			
			--complete[#complete]= target_string:sub(1 , target_string:find('%.')-1)
			print('insert set_value')
			table.insert(machine.commands ,machine.index+1 ,'set_value(value) to '..target_string )
		end]]

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
		local key_link=machine.key_link
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
					print('jump > 1')
					TableFunc.Push(commands, {command=complete[2] , arg = {loop_map[loop_type](battle , key_link)} })
					--TableFunc.Push(commands, {command=complete[2] , target = LoopMap[loop_type](battle , key_link) })
				elseif loop_type=='jump' and i == 1 then
					if #key_link.target_table > 1 then
						local card = key_link.self
						local basic_number ,race
						for k,v in pairs(card.use_condition) do
							if not v[3]:find('card') then
								basic_number = v[2]
								race =v[3]
								break
							end
				
						end
						print('jump == 1 & #key_link.target_table > 1')
						TableFunc.Push(commands, {command=complete[2], arg = {'random('..basic_number..',target (hp > 0))'} })
						--TableFunc.Push(commands, {command=complete[2], target = 'random 1 target (hp > 0)' })
					else
						print('jump == 1')
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
			--TableFunc.Dump(machine.stack)
			--TableFunc.Dump(v.arg)
			--TableFunc.Dump(arg)
			--Complex_command[key](battle , machine ,v.command  ,v.target)
			--local result =Complex_command[key](battle , machine ,table.unpack(v.arg) ,table.unpack(arg))
			local result 
			--[[if key:find('condition') then
				result =Complex_command[key](battle , machine ,table.unpack(v.arg) ,table.unpack(arg))
			else]]
				result=Complex_command.preview(battle , machine ,key ,table.unpack(v.arg) ,table.unpack(arg))
			--end
			--print('result',result)
			--TableFunc.Dump(result)
			TableFunc.Push(machine.result ,result)
		end

		machine:TransitionTo('Wait')

	end


	function machine:ReadEffect(battle ,command ,key_link ,print_log)
		--print('card.effect' , card.effect)
		local commands = type(command)=='table' and command or {command}
		self.key_link=key_link
		self.result={}
		--print('key_link!!' ,key_link)
		self.commands=TableFunc.DeepCopy(commands)
		--print('commands ',#self.commands)
		--TableFunc.Dump(self.commands)
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