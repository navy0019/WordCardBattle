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
			TableFunc.Push(stack, {t[num]})
		else
			TableFunc.Push(stack, {})
		end
	else
		TableFunc.Push(stack ,data) 
	end
	--print(stack[#stack] , TableFunc.Dump(stack))
end
local ActMap={
		get= function(battle,machine,...)
			--local machine,arg=...
			local arg  			={...}
			local key 			=TableFunc.Shift(arg)
			local stack ,effect =machine.stack , machine.effect
			local target 		=TableFunc.Pop(stack)			

			--處理參數部分
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
			for k,v in pairs(target) do
				local data = v[key]
				local value 


				if type(data)=='string' and not tonumber(data)  then

					value=StringRead.StrToValue(data ,machine.toUse.self ,battle)
					--print('get str ',data[key]..value)
				--[[elseif type(data) == 'table' and not TableFunc.IsDictionary(data)  then

					value=StringRead.ReadStrTable(data, machine.toUse.self ,battle)
					--print('get table value',value)]]
				else
					--print('Get',data)
					value=data
				end
				TableFunc.Push(result  , value) 
			end

			TableFunc.Push(stack ,result)
		end,

		set= function(battle,machine,...)
			--print('set somthing')
			--local machine,arg=...
			local arg={...}
			local key =TableFunc.Shift(arg)
			local stack=machine.stack
			local target --=TableFunc.Pop(stack)
			local value  =TableFunc.Pop(stack)

			if key:find('%.')then
				local act= {StringDecode.split_by(key,'.')}
				key = TableFunc.Pop(act)
				for i=#act,2,-1 do
					act[i]='get '..act[i]
				end
				local StringAct=require('lib.StringAct')
				local m = StringAct.NewMachine()
				m.stack={target}
				StringAct.ReadEffect(battle ,m ,act ,machine.toUse)
				target = TableFunc.Pop(m.stack)
			end

			for k,obj in pairs(target) do
				for i,v in pairs(value) do
					obj[key]=v
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
			TableFunc.Push(stack ,{toUse.card}) 
			--TableFunc.Dump(toUse.card)
		end,
		self=function(battle,machine,...)
			--local machine,arg=...
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,{toUse.self}) 
		end,
		master=function(battle,machine,...)
			local toUse= machine.toUse
			local stack=machine.stack
			local master
			--print('Master')
		--	TableFunc.Dump(toUse)
			if type(toUse.self.master) =='string' then

				local type , serial = StringDecode.split_by(toUse.self.master ,'%s')
				local tab = type =='hero' and battle.characterData.heroData or battle.characterData.monsterData
				local index = TableFunc.MatchSerial(tab ,serial)
				master = tab[index]
			else
				master = toUse.self.master
			end
			TableFunc.Push(stack ,{master})

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
		melee=function(battle,machine,...)
			--local machine,arg=...
			--print('In melee')
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local atk_value = TableFunc.Pop(stack)

			local tab={
				atk_value,	
				'target','get data ','get team_index',
				'> 2','boolean true[2,divided] ',
				'minus'
			}
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,
		built_in_atk=function(battle,machine,...)
			local arg={...}
			----local machine= TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local atk_type=TableFunc.Shift(arg)
			local atk_value = TableFunc.Shift(arg)
			--print('atk_value',atk_value)
			local tab

			if atk_type=='magic' then
				tab={
					'target','get data.hp' ,
					atk_value , 'minus' ,
					'target.data' ,'set hp'
				}
			else
				tab={
				'target','get data','get shield',
				atk_value ,atk_type ,
				'set target.data.shield',
				'target','get data.shield',
				'< 0' ,'boolean true[target, get data.shield, target, get data.hp,sum ,set target.data.hp] '
			}
			end
			for i=#tab ,1 ,-1 do
				table.insert(effect, machine.index+1 , tab[i])
			end
		end,

		boolean=function(battle,machine,...)			
			
			local arg={...}	--arg:{true[xxx] ,false[xxx]}	
			----local machine = TableFunc.Shift(arg)
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
		compare=function(battle,machine,...)
			local func={
				function(a,b) return a>b end,
				function(a,b) return a<b end,
				function(a,b) return a==b end,
				function(a,b) return a>=b end,
				function(a,b) return a<=b end
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
		length=function(battle,machine,...)
			local arg={...}
			----local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= TableFunc.Shift(machine.stack)
			TableFunc.Push(machine.stack ,#v)

		end,
		copy=function(battle,machine,...)
			local arg={...}
			----local machine = TableFunc.Shift(arg)
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
					if buff.name== state_name then 
						--TableFunc.Push(result ,true)
						TableFunc.Push(result ,buff)
					else
						TableFunc.Push(result ,false) 
					end
				end
			end
			for k,character in pairs(characterData) do
				search_state(character.state.before , state_name)
				search_state(character.state.always , state_name)
				search_state(character.state.after  , state_name) 
				search_state(character.state.is_target, state_name) 
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
		add_buff=function(battle,machine,...)
			local arg ={...}
			--local machine = TableFunc.Shift(arg)
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local key = TableFunc.Shift(arg)
			local parameter = TableFunc.Shift(arg)
			local target = TableFunc.Pop(stack)
			print(key,parameter)
			--StateHandler.AddBuff(battle, target , key ,parameter)
		end

}

return ActMap