local TableFunc		= require('lib.TableFunc')
local StringRead 	= require('lib.StringRead')
local StringDecode	= require('lib.StringDecode')
local universal_func= require('lib.command_act.universal_func')


local Basic_act={
		get= function(battle,machine,...)-- get xxx (會從stack pop 一個物件 從物件取得key)
			
			local arg  			={...}
			local key 			=TableFunc.Shift(arg)
			local stack ,effect =machine.stack , machine.effect
			local target 		=TableFunc.Pop(stack)			

			--處理參數部分-> xx.xx.key 保留最後端的key
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
			if universal_func.identifyType(target) =='array' then
				for k,v in pairs(target) do
					local data = v[key]
					assert(data,'target don\'t have key '..key)
					local value 
					if type(data)=='string' and not tonumber(data)  then

						if data:find('%[') then		
							local left = data:find('%[')
							local right = StringDecode.FindCommandScope( left+1 ,data,'[',']')
							local effect = data:sub(left+1 ,right-1)
							value = universal_func.excute_arg(battle ,effect,toUse)
						else
							value=StringRead.StrToValue(data ,machine.toUse.self ,battle)
						end
					else
						value=data
					end
					TableFunc.Push(result  , value) 
				end

				TableFunc.Push(stack ,result)
			else
				local data = target[key]

				assert(data,'target don\'t have key '..key)                                                                                                                 
				local value 
				if type(data)=='string' and not tonumber(data)  then
					if data:find('%[') then		
						local left = data:find('%[')
						local right = StringDecode.FindCommandScope( left+1 ,data,'[',']')
						local effect = {StringDecode.split_by(data:sub(left+1 ,right-1),',') }
						value = universal_func.excute_arg(battle ,effect,toUse)
					else
						value=StringRead.StrToValue(data ,machine.toUse.self ,battle)
					end
				else
					value=data
				end
				TableFunc.Push(stack ,value)
			end
		end,

		set= function(battle,machine,...)-- set xxx (會從stack pop 2次 (物件 , 數值)  將數值賦予物件)
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
				local StringAct=require('lib.StringAct')
				local m = StringAct.NewMachine()
				StringAct.ReadEffect(battle ,m ,act ,machine.toUse)
				target = TableFunc.Pop(m.stack)
			else
				target= value
				value = TableFunc.Pop(stack)
			end

			if universal_func.identifyType(target) =='array' then
				for k,obj in pairs(target) do
					if universal_func.identifyType(value) =='array' and value[k] then
						obj[key]=value[k]
					else
						obj[key]=value
					end				
				end
			else
				if universal_func.identifyType(value) =='array' then
					target[key]=value[1]
				else
					target[key]=value
				end
			end
		end,
		set_target= function(battle,machine,...)--從 stack pop一個物件 設置成target( target關鍵字 將return 這個物件 )
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local group= TableFunc.Pop(stack)
			machine.toUse.target_table=group
		end,

		card=function(battle,machine,...)
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,toUse.card) 
		end,
		self=function(battle,machine,...)
			local toUse= machine.toUse
			local stack=machine.stack
			TableFunc.Push(stack ,toUse.self) 
		end,
		master=function(battle,machine,...)--取得card 或state 的持有者
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
		--[[
		enemy / enemy 2 / enemy [get hp ,> 0] / enemy 2 [get hp ,> 0]

		enemy -> 取得整個隊伍  enemy 2 -> 取得隊伍中第2位 
		enemy [get hp ,> 0] -> 取得隊伍中符合條件的物件
		enemy 2 [get hp ,> 0] -> 取得隊伍中第2位 存在且符合條件 
		如果物件不存在 或者不符條件 會得到一個空物件 

		enemy , hero ,target 都能用以上幾種方法操作
		]] 
		enemy=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local monsterData=battle.characterData.monsterData
			universal_func.get_group(monsterData ,stack ,arg)
		end,
		hero=function(battle,machine,...)					
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local heroData=battle.characterData.heroData
			universal_func.get_group(heroData ,stack ,arg)
		end,
		target=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			--print('Target',toUse.target_table,#toUse.target_table)
			universal_func.get_group(toUse.target_table ,stack ,arg)
			
		end,

		input_target=function(battle,machine,...)
			local toUse= machine.toUse
			local stack=machine.stack
			if num == nil then num= 1 end
			TableFunc.Push(stack ,toUse['card_target_'..num])  
		end,
		--[[
		從stack pop 並將其轉為對應數字 
		ex: [true , true ,false] , boolean_replace true[2] false[1] -> [2,2,1]
		]]
		boolean_replace=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)

			local t={}
			if universal_func.identifyType(bool_tab)=='array' then
				for k,bool in pairs(bool_tab) do
					local result =bool
					if type(result)=='table' then result =true end
					for i,command in pairs(arg) do

						local head, tail =command:find(tostring(result))				
						if head then
							command=StringDecode.trim_head_tail(command:gsub(tostring(result),''))
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

		--[[
		boolean / boolean_pick 都是根據true false 執行內容
		兩者差異: boolean 只要有一個符合條件 就會執行 boolean_pick 會根據true false 各自執行
		]]
		boolean_pick=function(battle,machine,...) 
			local arg={...}	
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)
			if type(bool_tab)~='table'then bool_tab={bool_tab} end

			for k,bool in pairs(bool_tab) do
				local result =bool
				--print('need bool',result,type(result))
				if type(result)=='table' then 
					result =true 
				end
				for i,command in pairs(arg) do
				--print('bool command',command)		
					if command:find(tostring(result)) then
						--print('find!!!')
						local new_command=StringDecode.trim_head_tail( command:gsub(tostring(result),''))
						local mini_command =new_command:sub(2,#new_command-1)
						local act={StringDecode.split_by(mini_command,',')}
						
						local StringAct =require('lib.StringAct')
						local m=StringAct.NewMachine()
						local new_toUse=TableFunc.ShallowCopy(toUse)
						if toUse.target_table and universal_func.identifyType(toUse.target_table)=='array' then	
							new_toUse.target_table =toUse.target_table[k]
						end
						if #stack > 0 and universal_func.identifyType(stack[#stack])=='array' then
							TableFunc.Push(m.stack, stack[#stack][k]) 
						end	
						StringAct.ReadEffect(battle ,m ,act,new_toUse ,'print')
					end
				end
			end
		end,
		boolean=function(battle,machine,...)				
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

			local scope_start,scope_end
			local bool_tab = TableFunc.Pop(stack)
			if type(bool_tab)~='table'then bool_tab={bool_tab} end

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

		stop=function(battle,machine,...)--終止整串指令的執行
			return 'stop'
		end,
		calculate=function(battle,machine,...)
			local func = {
				function(a,b)return a+b end,
				function(a,b)return a-b end,
				function(a,b)return a*b end,
				function(a,b)return math.ceil(a/b) end
			}
			local arg={...}
			local key =TableFunc.Shift(arg)
			local toUse= machine.toUse
			local stack=machine.stack
			local v1 = TableFunc.Pop(stack)
			local v2 = TableFunc.Pop(stack)
			local b = tonumber(v1) and tonumber(v1) or v1
			local a = tonumber(v2) and tonumber(v2) or v2

			local index =universal_func.findSymbol(key,'calculate')
			local t={}
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
				TableFunc.Push(stack,func[index](a ,b)) 
			elseif (type(a)=='number' and type(b)=='table') or(type(a)=='table' and type(b)=='number') then
				local tab = type(a)=='table' and a or b
				local num = type(a)=='number' and a or b
				for k,v in pairs(tab) do
					local parameter = type(a)=='number' and{num,v} or {v,num}
					local value = func[index](table.unpack(parameter))
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
			local toUse= machine.toUse
			local stack=machine.stack
			local key =arg[1]
			local value=TableFunc.Pop(stack)
			--print('value',value,#value)
			local a = tonumber(value) and tonumber(value) or value
			local b = tonumber(arg[2]) and tonumber(arg[2]) or arg[2]
			local index =universal_func.findSymbol(key,'compare')
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
				--print('compare number & table')
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
		array=function(battle,machine,...)--array [1,2...]
			local arg=...
			arg=StringDecode.trim_head_tail(arg:sub(2,#arg-1))
			arg={StringDecode.split_by( arg,',')}
			--print('m_arg',arg,#arg)

			local function toboolean(s)
				local t = {['true']=true ,['false']=false}
				return t[s]
			end

			for k,v in pairs(arg) do
				if tonumber(v) then 
					arg[k]= tonumber(v)
				elseif toboolean(v) then
					arg[k]= toboolean(v)
				end 
			end

			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			TableFunc.Push(stack,arg)
		end,
		length=function(battle,machine,...)--從stack pop 一個物件 並取得數量  ex: [hero , length] 取得hero 隊伍人數
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local t= TableFunc.Pop(machine.stack)
			if type(t)~='table' then t={t} end
			TableFunc.Push(machine.stack ,#t)

		end,
		copy=function(battle,machine,...)--複製 stack 最末端的(物件 ,數字...皆可)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local v= machine.stack[#machine.stack]
			TableFunc.Push(machine.stack ,v)

		end,
		--[[
		random number / random number obj  
		number 可以是數字 也可以是一個範圍 ex:[random 2~4] 
		obj 是 enemy , hero ,target , input_target  也可以像操作 enemy方法那樣給予條件
		]]
		random=function(battle,machine,...)
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local num =TableFunc.Shift(arg)
			local obj = TableFunc.Shift(arg)
			local obj_arg=TableFunc.Shift(arg)
			if tonumber(num) and not obj then 
				num=tonumber(num)
				num = math.random(num)
				TableFunc.Push(machine.stack ,num) 
			elseif num:find('~') and not obj then
				local a , b = StringDecode.split_by(num,'~')
				local min = a < b and a or b 
				local max = a > b and a or b
				num = math.random(a,b)
				TableFunc.Push(machine.stack ,num)

			elseif tonumber(num) and  obj then
				local effect = obj_arg and {obj..' '..obj_arg} or{obj}				
				local result = universal_func.excute_arg(battle ,effect,toUse)
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

			elseif num:find('~') and  obj then
				local a , b = StringDecode.split_by(num,'~')
				local min = a < b and a or b 
				local max = a > b and a or b
				num = math.random(a,b)

				local effect = obj_arg and {obj..' '..obj_arg} or{obj}				
				local result = universal_func.excute_arg(battle ,effect,toUse)
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

			end
			
		end,
		find_state=function(battle,machine,...)
			local arg={...}

			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local state_name=TableFunc.Shift(arg)
			local characterData = TableFunc.Shift(machine.stack)
			local result ={}
			local function search_state(state_tab ,state_name) 
				for key, buff in pairs(state_tab) do
					if buff.key== state_name then 
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
		loop=function(battle,machine,...)--重複執行 n 次 [ ]內的command
			local arg={...}
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local loop_num =''--= TableFunc.Shift(arg)
			local left ,right ,command 
			for k,v in pairs(arg) do
				if v:find('%[') then
					left =v:find('%[') 
					right = StringDecode.FindCommandScope(left+1, v ,'[' ,']')				
					command = v:sub(left+1 ,right-1)
					loop_num = loop_num..' '..v:sub(1 ,left-1)
				else
					loop_num = loop_num..v
				end
			end

			if not tonumber(loop_num)then
				local effect = { loop_num}
				loop_num =universal_func.excute_arg(battle ,effect,toUse)
			else
				tonumber(loop_num)
			end
	
			local act,copy_scope = StringDecode.Split_Command(command) 					
			act=StringDecode.Replace_copy_scope(act,copy_scope)

			for i=1,loop_num do
				for k=#act,1,-1 do
					table.insert(effect, machine.index+1 , act[k])
				end 
			end

		end,
		push=function(battle,machine,...)--從stack pop 一個物件 push arg到物件裡
			local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
			local arg =...
			local target = TableFunc.Pop(machine.stack)
			local act,parameter
			--print('arg',arg)

			if arg:find('(.+):(.+)')then
				--act = StringDecode.TransToDic({arg})
				parameter = StringDecode.TransToDic({arg})
			elseif arg:find('%.') then
				act= {StringDecode.split_by(arg,'.')}
				for i=#act,2,-1 do
					act[i]='get '..act[i]
				end
				parameter = universal_func.excute_arg(battle ,act ,toUse)
			elseif tonumber(arg) then

				parameter = tonumber(arg)
			end

			if #target > 1 then
				for k,v in pairs(target) do
					TableFunc.Push(v ,parameter)
				end
			else
				TableFunc.Push(target ,parameter)
			end

		end,
		fit_target_length=function(battle,machine,...)--將單個物件(stack pop) 依照target的大小複製  ex: 2 -> {2,2,2}
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
			local target = TableFunc.Pop(stack)
			local StateHandler	= require('battle.StateHandler')
			StateHandler.AddBuff(battle, target , key )
		end


}

return Basic_act