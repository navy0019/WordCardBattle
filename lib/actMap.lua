local TableFunc=require('lib.TableFunc')
local StringRead = require('lib.StringRead')
local StringDecode=require('lib.StringDecode')

local compare_map={'>','<','==','>=','<='}
local calculate_map={'sum','minus','multiplie','divided'}
local function FindSymbol(str,t)
	for k,v in pairs(t) do
		if str:find(v) then
			return k
		end
	end
end
local function group_with_condition(data,condition)
	local StringAct=require('lib.StringAct')
	local mini_command =condition:sub(2,#condition-1)
	local act={StringDecode.split_by(mini_command,',')}	
	local m=StringAct.NewMachine(act,toUse ,battle)
	local t={}
	m.stack={data}				
	StringAct.ReadEffect(battle ,m)

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
	if #arg > 1 then
		for k,v in pairs(arg) do
			if tonumber(v) then
				num=tonumber(v)
			else
				condition=v
			end
		end
	else
		local v = TableFunc.Shift(arg)
		if tonumber(v) then
			num=tonumber(v)
		else
			condition=v
		end		
	end
	if condition and not num then
		--print('no number')
		local t=group_with_condition(data,condition)
		TableFunc.Push(stack, t)
	elseif not condition and num then
		if data[num] then
			TableFunc.Push(stack, {data[num]})
		else
			TableFunc.Push(stack, {})
		end
	elseif condition and num then
		local t=group_with_condition(data ,condition)
		if t[num] then
			TableFunc.Push(stack, t[num])
		else
			TableFunc.Push(stack, {})
		end
	else
		TableFunc.Push(stack ,data) 
	end
end
local ActMap={
		get= function(battle,...)
			--print('get')
			local machine,arg=...
			local stack=machine.stack
			local target =TableFunc.Pop(stack)
			
			
			local t={}
			for k,v in pairs(target) do
				local value 
				if type(v.data[arg])=='string' then
					value=StringRead.StrToValue(v.data[arg] ,v ,battle)
				else
					value=v.data[arg]
				end
				TableFunc.Push(t , value) 
			end
			TableFunc.Push(stack ,t)
		end,

		set= function(battle,...)
			--print('set somthing')
			local machine,arg=...
			local stack=machine.stack
			local target =TableFunc.Pop(stack)
			local value  =TableFunc.Pop(stack)
			for k,character in pairs(target) do
				for i,v in pairs(value) do
					character.data[arg]=v
				end				
			end
		end,
		set_target= function(battle,...)
			local arg={...}
			local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local group= TableFunc.Pop(stack)
			--print('set_target',TableFunc.Dump(group))
			machine.toUse.target_table=group
		end,
		card=function(battle,...)
			local machine,arg=...
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,{toUse.card}) 
			--TableFunc.Dump(toUse.card)
		end,
		enemy=function(battle,...)
			local arg={...}
			local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local monsterData=battle.characterData.monsterData
			get_group(monsterData ,stack ,arg)
		end,
		hero=function(battle,...)					
			local arg={...}
			local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local heroData=battle.characterData.heroData
			get_group(heroData ,stack ,arg)
		end,
		target=function(battle,...)
			local arg={...}
			local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			get_group(toUse.target_table ,stack ,arg)
			
		end,

		input_target=function(battle,...)
			local machine,num=...
			local toUse= machine.toUse
			local stack=machine.stack
			if num == nil then num= 1 end
			TableFunc.Push(stack ,toUse['card_target_'..num])  
		end,
		melee=function(battle,...)
			local machine,arg=...
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local atk_value = TableFunc.Pop(stack)
			--print('atk_value',TableFunc.Dump(atk_value))
			local tab={
				atk_value,	
				'target','get team_index',
				'> 2','boolean true[2,divided] ',
				'minus'
			}
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,
		built_in_atk=function(battle,...)
			local arg={...}
			local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local atk_type=TableFunc.Shift(arg)
			local atk_value = TableFunc.Shift(arg)
			local tab
			if tonumber(atk_value) then
				atk_value = tonumber(atk_value)
			else
				atk_value = StringRead.StrToValue(atk_value ,toUse.card ,battle)
			end
			if atk_type=='magic' then
				tab={
					'target','get hp' ,
					atk_value , 'minus' ,
					'target' ,'set hp'
				}
			else
				tab={
				'target','get shield',
				atk_value ,atk_type ,
				'target','set shield',
				'target','get shield',
				'< 0' ,'boolean true[target, get shield, target, get hp,sum ,target ,set hp] '
			}
			end
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,

		boolean=function(battle,...)			
			
			local arg={...}	--arg:{true[xxx] ,false[xxx]}	
			local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)
			if type(bool_tab)~='table'then bool_tab={bool_tab} end
			--print('bool tab',bool_tab)
			for k,bool in pairs(bool_tab) do
				for i,command in pairs(arg) do
					local head, tail =command:find(tostring(bool))
					
					if head then
						command=command:gsub(tostring(bool),'')
						local mini_command =command:sub(2,#command-1)
						local act={StringDecode.split_by(mini_command,',')}

						--StringDecode.MakeTableByComma(mini_command,act)
						for i=#act,1,-1 do
							table.insert(effect, machine.index+1 , act[i])
						end
					end
				end
			end

		end,
		deal=function(battle,...)
			local arg={...}
			local machine = TableFunc.Shift(arg)
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
		stop=function(battle,...)
			return 'stop'
		end,
		calculate=function(battle,...)
			local func = {
				function(a,b)return a+b end,
				function(a,b)return a-b end,
				function(a,b)return a*b end,
				function(a,b)return math.floor(a/b) end
			}
			local machine,key=...
			local toUse= machine.toUse
			local stack=machine.stack
			local v1 = TableFunc.Pop(stack)
			local v2 = TableFunc.Pop(stack)
			local b = tonumber(v1) and tonumber(v1) or v1
			local a = tonumber(v2) and tonumber(v2) or v2

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
		compare=function(battle,...)
			local func={
				function(a,b) return a>b end,
				function(a,b) return a<b end,
				function(a,b) return a==b end,
				function(a,b) return a>=b end,
				function(a,b) return a<=b end
			}
			local arg={...}
			local machine=TableFunc.Shift(arg)
			local toUse= machine.toUse
			local stack=machine.stack
			local key =arg[1]
			local value=TableFunc.Pop(stack)
			local a = tonumber(value) and tonumber(value) or value
			local b = tonumber(arg[2]) and tonumber(arg[2]) or arg[2]
			local index =FindSymbol(key,compare_map)
			local t={}
			--print('a',a ,'b',b)
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
		length=function(battle,...)
			local arg={...}
			local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= TableFunc.Shift(machine.stack)
			TableFunc.Push(machine.stack ,#v)

		end,
		copy=function(battle,...)
			local arg={...}
			local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= machine.stack[#machine.stack]
			TableFunc.Push(machine.stack ,v)

		end,
		random=function(battle,...)
			local arg={...}
			local machine = TableFunc.Shift(arg)
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
				local m=StringAct.NewMachine(effect,toUse ,battle)
				StringAct.ReadEffect(battle ,m)
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
		find_state=function(battle,...)
			local arg={...}

			local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local state_name=TableFunc.Shift(arg)
			local characterData = TableFunc.Shift(machine.stack)
			local result ={}
			local function search_state(state_tab ,state_name) 
				for key, buff in pairs(state_tab) do
					if buff.name== state_name then 
						TableFunc.Push(result ,true)
					else
						TableFunc.Push(result ,false) 
					end
				end
			end
			for k,character in pairs(characterData) do
				search_state(character.data.state.before , state_name)
				search_state(character.data.state.always , state_name)
				search_state(character.data.state.after  , state_name) 
				search_state(character.data.state.is_target, state_name) 
			end
			TableFunc.Push(machine.stack, result)
		end,
		loop=function(battle,...)
			local arg={...}
			local machine = TableFunc.Shift(arg)
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

		end

}

return ActMap