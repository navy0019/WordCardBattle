local TableFunc		= require('lib.TableFunc')
local StringRead 	= require('lib.StringRead')
local StringDecode	= require('lib.StringDecode')

local compare_map	={'>=','<=','==','>','<'}
local calculate_map	={'sum','minus','multiplie','divided'}
local function FindSymbol(str,t)
	for k,v in pairs(t) do
		if str:find(v) then
			return k
		end
	end
end
function identifyType(o)
	if type(o)~='table' then return type(o) end
	if TableFunc.IsDictionary(o) then 
		return 'dictionary'
	else
		return 'array'
	end

end
local function group_with_condition(data,condition)
	local StringAct=require('lib.StringAct')
	local mini_command =condition:sub(2,#condition-1)
	local act={StringDecode.split_by(mini_command,',')}	
	local m=StringAct.NewMachine()
	local t={}
	m.stack={data}				
	StringAct.ReadEffect(battle ,m ,act )

	local result =TableFunc.Shift(m.stack)
	for k,v in pairs(result) do
		if v then
			TableFunc.Push(t ,data[k])
		end
	end
	return t
end
local function get_group(data,stack,arg)
	local condition , num
	for k,v in pairs(arg) do
		if tonumber(v) then
			num=tonumber(v)
		else
			condition=v
		end
	end

	local t
	if condition and not num then
		--print('no number')
		t=group_with_condition(data,condition)
		if #t >1 or #t==0 then
			TableFunc.Push(stack, t)
		else
			TableFunc.Push(stack, t[1])
		end
	elseif not condition and num then
		if data[num] then
			TableFunc.Push(stack, data[num])
		else
			TableFunc.Push(stack, {})
		end
	elseif condition and num then
		t=group_with_condition(data ,condition)

		if t[num] then
			TableFunc.Push(stack, t[num])
		else
			TableFunc.Push(stack, {})
		end
	else
		TableFunc.Push(stack ,data) 
	end
	--print(stack[#stack] , TableFunc.Dump(stack))
end
local function group_act(a,b,func)
end
local ActMap={
		get= function(battle,machine,...)
			--local machine,arg=...
			local arg  			={...}
			local key 			=TableFunc.Shift(arg)
			local stack ,effect =machine.stack , machine.effect
			local target 		=TableFunc.Pop(stack)			

			--處理參數部分 保留最後端的key
			if key:find('%.')then
				local act= {StringDecode.split_by(key,'.')}
				key = TableFunc.Shift(act)
				for i=#act,1,-1 do
					act[i]='get '..act[i]
					table.insert(effect, machine.index+1 , act[i])
				end
			end

			--輸出數值
			local result={}
			if identifyType(target) =='array' then
				for k,v in pairs(target) do
					local data = v[key]
					local value 
					if type(data)=='string' and not tonumber(data)  then
						value=StringRead.StrToValue(data ,machine.toUse.self ,battle)
					else
						value=data
					end
					TableFunc.Push(result  , value) 
				end

				TableFunc.Push(stack ,result)
			else
				local data = target[key]
				local value 
				if type(data)=='string' and not tonumber(data)  then
					value=StringRead.StrToValue(data ,machine.toUse.self ,battle)
				else
					value=data
				end
				TableFunc.Push(stack ,value)
			end
		end,

		set= function(battle,machine,...)
			--print('set somthing')
			local arg={...}
			local key =TableFunc.Shift(arg)
			local stack=machine.stack
			local target 
			local value  =TableFunc.Pop(stack)
			assert(value ,'can\'t set value ,value is nil')


			if key:find('%.')then
				local act= {StringDecode.split_by(key,'.')}
				key = TableFunc.Pop(act)
				for i=#act,2,-1 do
					act[i]='get '..act[i]
				end
				--TableFunc.Dump(act)
				local StringAct=require('lib.StringAct')
				local m = StringAct.NewMachine()
				StringAct.ReadEffect(battle ,m ,act ,machine.toUse)
				target = TableFunc.Pop(m.stack)
			end

			if identifyType(target) =='array' then
				--print('set target array')
				for k,obj in pairs(target) do
					if identifyType(value) =='array' and value[k] then
						--print('set value array')
						obj[key]=value[k]

					else
						obj[key]=value
					end				
				end
			else
				if identifyType(value) =='array' then
					target[key]=value[1]
				else
					target[key]=value
				end
			end
		end,
		set_target= function(battle,machine,...)
			local arg={...}
			--local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local group= TableFunc.Pop(stack)
			--print('set_target',TableFunc.Dump(group))
			machine.toUse.target_table=group
		end,
		card=function(battle,machine,...)
			--local machine,arg=...
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,toUse.card) 
			--TableFunc.Dump(toUse.card)
		end,
		self=function(battle,machine,...)
			--local machine,arg=...
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,toUse.self) 
		end,
		master=function(battle,machine,...)
			local toUse= machine.toUse
			local stack=machine.stack
			local master

			if type(toUse.self.master) =='string' then

				local type , serial = StringDecode.split_by(toUse.self.master ,'%s')
				local tab = type =='hero' and battle.characterData.heroData or battle.characterData.monsterData
				local index = TableFunc.MatchSerial(tab ,serial)
				master = tab[index]
			else
				master = toUse.self.master
			end
			TableFunc.Push(stack ,master)

		end,
		enemy=function(battle,machine,...)
			local arg={...}
			--local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local monsterData=battle.characterData.monsterData
			get_group(monsterData ,stack ,arg)
		end,
		hero=function(battle,machine,...)					
			local arg={...}
			--local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local heroData=battle.characterData.heroData
			get_group(heroData ,stack ,arg)
		end,
		target=function(battle,machine,...)

			local arg={...}
			--local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			--print('Target',toUse.target_table,#toUse.target_table)
			get_group(toUse.target_table ,stack ,arg)
			
		end,

		input_target=function(battle,machine,...)
			--local machine,num=...
			local toUse= machine.toUse
			local stack=machine.stack
			if num == nil then num= 1 end
			TableFunc.Push(stack ,toUse['card_target_'..num])  
		end,
		boolean_replace=function(battle,machine,...)--將true false轉為數字
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)

			local t={}
			if identifyType(bool_tab)=='array' then
				for k,bool in pairs(bool_tab) do
					local result =bool
					if type(result)=='table' then result =true end
					for i,command in pairs(arg) do

						local head, tail =command:find(tostring(result))				
						if head then
							command=StringDecode.trim_head_tail(command:gsub(tostring(result),''))
							--print('replace' ,command)
							local num =StringDecode.trim_head_tail(command:sub(2,#command-1)) 
							TableFunc.Push(t,num)
						end
					end
				end

			else
				local result = bool_tab==false and false or true
				for i,command in pairs(arg) do
					local head, tail =command:find(tostring(result))				
					if head then
						command=command:gsub(tostring(result),'')
						local num =StringDecode.trim_head_tail(command:sub(2,#command-1)) 
						TableFunc.Push(t,num)
					end
				end

			end
			TableFunc.Push(stack,t)
		end,
		boolean_pick=function(battle,machine,...)
			local arg={...}	-- arg內容{true[xxx] ,false[xxx]}	
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)
			if type(bool_tab)~='table'then bool_tab={bool_tab} end --bool_tab內容 由上個指令得到 {obj 或boolean}

			for k,bool in pairs(bool_tab) do
				local result =bool
				if type(result)=='table' or result==true then 
					result =true 
				end
				for i,command in pairs(arg) do		
					if command:find(tostring(result)) then
						local new_command=StringDecode.trim_head_tail( command:gsub(tostring(result),''))
						local mini_command =new_command:sub(2,#new_command-1)
						local act={StringDecode.split_by(mini_command,',')}
						
						local StringAct =require('lib.StringAct')
						local m=StringAct.NewMachine()
						local new_toUse=TableFunc.ShallowCopy(toUse)
						if toUse.target_table and identifyType(toUse.target_table)=='array' then	
							new_toUse.target_table =toUse.target_table[k]
						end
						if #stack > 0 and identifyType(stack[#stack])=='array' then
							TableFunc.Push(m.stack, stack[#stack][k]) 
						end	
						StringAct.ReadEffect(battle ,m ,act,new_toUse ,'print_log')
					end
				end
			end
		end,
		boolean=function(battle,machine,...)				
			local arg={...}	-- arg內容{true[xxx] ,false[xxx]}	
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)
			if type(bool_tab)~='table'then bool_tab={bool_tab} end --bool_tab內容 由上個指令得到 {obj 或boolean}

			for k,bool in pairs(bool_tab) do
				local result =bool
				if type(result)=='table' then result =true end
				for i,command in pairs(arg) do					
					if command:find(tostring(result)) then
						local new_command=StringDecode.trim_head_tail(command:gsub(tostring(result),''))
						local mini_command =new_command:sub(2,#new_command-1)
						local act={StringDecode.split_by(mini_command,',')}
						for i=#act,1,-1 do
							table.insert(effect, machine.index+1 , act[i])
						end
					end
				end
			end

		end,
		deal=function(battle,machine,...)
			local arg={...}
			----local machine = TableFunc.Shift(arg)
			local toUse= machine.toUse
			local stack=machine.stack
			local num =arg[1]
			local t ={}
			for i=1,num do
				TableFunc.Push(t ,battle.battleData.deck[i])
			end
			TableFunc.Push(machine.record ,{act_name='deal',arg={table.unpack(t)}})
			battle:DealProcess(num)
		end,
		stop=function(battle,machine,...)
			return 'stop'
		end,
		calculate=function(battle,machine,...)
			local func = {
				function(a,b)return a+b end,
				function(a,b)return a-b end,
				function(a,b)return a*b end,
				function(a,b)return math.floor(a/b) end
			}
			--local machine,key=...
			local arg={...}
			local key =TableFunc.Shift(arg)
			local toUse= machine.toUse
			local stack=machine.stack
			local v1 = TableFunc.Pop(stack)
			local v2 = TableFunc.Pop(stack)
			local b = tonumber(v1) and tonumber(v1) or v1
			local a = tonumber(v2) and tonumber(v2) or v2

			--print('calculate key',key,a,b)
			local index =FindSymbol(key,calculate_map)
			local t={}
			--print('calculate',type(a),type(b))
			if type(a)=='table' and type(b)=='table' then
				local max = #a > #b and a or b
				local other = #a < (#b) and a or b
				for k,v in pairs(max) do
					if other[k] then
						local value=func[index](a[k] ,b[k]) 
						TableFunc.Push(t,value)
					end
				end
				TableFunc.Push(stack, t)
			elseif type(a)=='number' and type(b)=='number' then
				TableFunc.Push(stack,func[index](a ,b) )
			elseif (type(a)=='number' and type(b)=='table') or(type(a)=='table' and type(b)=='number') then
				local tab = type(a)=='table' and a or b
				local num = type(a)=='number' and a or b
				for k,v in pairs(tab) do
					local parameter = type(a)=='number' and{num,v} or {v,num}
					local value=func[index](table.unpack(parameter)) 
					TableFunc.Push(t,value)
				end
				TableFunc.Push(stack, t)
			end
		end,
		compare=function(battle,machine,...)
			local func={
				function(a,b) return a>=b end,
				function(a,b) return a<=b end,
				function(a,b) return a==b end,
				function(a,b) return a>b end,
				function(a,b) return a<b end
			}
			local arg={...}
			--local machine=TableFunc.Shift(arg)
			local toUse= machine.toUse
			local stack=machine.stack
			local key =arg[1]
			local value=TableFunc.Pop(stack)
			local a = tonumber(value) and tonumber(value) or value
			local b = tonumber(arg[2]) and tonumber(arg[2]) or arg[2]
			local index =FindSymbol(key,compare_map)
			local t={}
			--print('a',a ,'b',b)
			if type(a)=='table' and type(b)=='table' then
				local max = #a > #b and a or b
				local other = #a < (#b) and a or b
				for k,v in pairs(max) do
					if other[k] then
						local value=func[index](a[k] ,b[k]) 
						TableFunc.Push(t,value)
					end
				end
				TableFunc.Push(stack, t)
			elseif type(a)=='number' and type(b)=='number' then
				TableFunc.Push(stack,func[index](a ,b) )
			elseif (type(a)=='number' and type(b)=='table') or(type(a)=='table' and type(b)=='number') then
				local tab = type(a)=='table' and a or b
				local num = type(a)=='number' and a or b
				for k,v in pairs(tab) do
					local parameter = type(a)=='number' and{num,v} or {v,num}
					local value=func[index](table.unpack(parameter)) 
					TableFunc.Push(t,value)
				end
				TableFunc.Push(stack, t)
			end		
		end,
		array=function(battle,machine,...)
			local arg=...
			--print('Arg',arg)
			arg=StringDecode.trim_head_tail(arg:sub(2,#arg-1))
			arg={StringDecode.split_by( arg,',')}
			--[[for k,v in pairs(arg) do
				print('array[ '..k..' ]',v)
			end]]
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			TableFunc.Push(stack,arg)
		end,
		length=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= TableFunc.Pop(machine.stack)
			TableFunc.Push(machine.stack ,#v)

		end,
		copy=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= machine.stack[#machine.stack]
			TableFunc.Push(machine.stack ,v)

		end,
		random=function(battle,machine,...)
			local arg={...}
			--local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local num =TableFunc.Shift(arg)
			local group = TableFunc.Shift(arg)
			local grop_arg=TableFunc.Shift(arg)
			--print('group',group ,grop_arg)
			if tonumber(num) then 
				num=tonumber(num)
			else 
			end
			if group then
				local StringAct=require('lib.StringAct')
				local effect =grop_arg and {group..' '..grop_arg} or{group}
				local m=StringAct.NewMachine()
				StringAct.ReadEffect(battle ,m ,effect,toUse)
				local result =TableFunc.Shift(m.stack)
				local t={}
				if #result>0 then
					for i=1,num do
						local ran = math.random(#result)
						TableFunc.Push(t ,result[ran])
					end
					TableFunc.Push(machine.stack ,t)
				else
					TableFunc.Push(machine.stack ,t)
				end
				--print('vv',v,#v)
				--table.insert(effect, machine.index+1 , key)
			end
			
		end,
		find_state=function(battle,machine,...)
			local arg={...}

			--local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local state_name=TableFunc.Shift(arg)
			local characterData = TableFunc.Shift(machine.stack)
			local result ={}
			local function search_state(state_tab ,state_name) 
				for key, buff in pairs(state_tab) do
					if buff.key== state_name then 
						--TableFunc.Push(result ,true)
						TableFunc.Push(result ,buff)
						return true
					end
				end
			end
			for k,character in pairs(characterData) do
				local bool_1 =search_state(character.state.round_start 	, state_name)
				local bool_2 =search_state(character.state.round_end 	, state_name)
				local bool_3 =search_state(character.state.every_card  	, state_name) 
				local bool_4 =search_state(character.state.is_target	, state_name)
				if not(bool_1 or bool_2 or bool_3 or bool_4) then
					TableFunc.Push(result ,false)
				end 
			end
			TableFunc.Push(machine.stack, result)
		end,
		loop=function(battle,machine,...)
			local arg={...}
			--local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local loop_num= TableFunc.Shift(arg)
			local command = StringDecode.trim_head_tail(TableFunc.Shift(arg))
			command=command:sub(2,#command-1)			
			local act,copy_scope = StringDecode.Split_Command(command) 					
			act=StringDecode.Replace_copy_scope(act,copy_scope)
			--TableFunc.Dump(act)
			for i=1,loop_num do
				for k=#act,1,-1 do
					table.insert(effect, machine.index+1 , act[k])
				end 
			end

		end,
		push=function(battle,machine,...)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local arg =...
			local target = TableFunc.Pop(machine.stack)
			local act= {StringDecode.split_by(arg,'.')}
			for i=#act,2,-1 do
				act[i]='get '..act[i]
			end
			local StringAct=require('lib.StringAct')
			local m = StringAct.NewMachine()
			StringAct.ReadEffect(battle ,m ,act ,machine.toUse)

			local parameter = TableFunc.Pop(m.stack)

			--print('target')
			--TableFunc.Dump(target)
			if #target > 1 then
				for k,v in pairs(target) do
					TableFunc.Push(v ,parameter)
				end
			else
				TableFunc.Push(target ,parameter)
			end

		end,
		fit_target=function(battle,machine,...)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local len = #toUse.target_table
			local num = TableFunc.Pop(stack)
			local t ={}
			for i=1,len do
				TableFunc.Push(t,num)
			end
			TableFunc.Push(stack,t)
		end,
		add_buff=function(battle,machine,...)
			local arg ={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local key = TableFunc.Shift(arg)
			--local parameter = TableFunc.Shift(arg)
			local parameter
			if key:find('%[') then
				local left = key:find('%[')
				local right = StringDecode.FindCommandScope(left+1 ,key ,'[',']')
				parameter = key:sub(left,right)
				key=StringDecode.trim_head_tail( key:gsub('%'..parameter ,'') ) 
			end
			local target = TableFunc.Pop(stack)
			--print(key,parameter)
			local StateHandler	= require('battle.StateHandler')
			StateHandler.AddBuff(battle, target , key ,parameter)
		end,
		add_card_buff=function(battle,machine,...)
		end

}

return ActMap