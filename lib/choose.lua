local TableFunc = require("lib.TableFunc")
local Card = require('lib.card')
local Msg= require('resource.Msg')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local function MakeDiff( self,current_condition)
	local diff =current_condition.max - #self.input_table  
	if diff > 0 then
		if current_condition.max ~= current_condition.min then
			local min = #self.input_table >=current_condition.min and 0 or current_condition.min
			local num = current_condition.min<diff and min..'~'..diff or diff
			local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('can_need',num)}} }}
			TableFunc.Push(self.queue , o)
		else
			local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('need',diff)}} }}
			TableFunc.Push(self.queue , o)
		end
	else
		local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('can_need',diff)}} }}
		TableFunc.Push(self.queue , o)
	end
end
local function LoopAdd(self,card)
	local isCard = getmetatable(card) == Card.metatable and true or false
	local current_condition = self.input_check[1]
	local diff

	if not isCard then
		local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('error_target')}} }}
		TableFunc.Push(self.queue , o)
		return
	end

	local p = TableFunc.Find(self.input_table , card)
	if p then
		table.remove(self.input_table,p)
		MakeDiff(self, current_condition )
		return
	end

	if #self.input_table+1 > current_condition.max then
		TableFunc.Shift(self.input_table)
		TableFunc.Push(self.input_table,card)
		MakeDiff(self, current_condition)
	else
		TableFunc.Push(self.input_table,card)
		MakeDiff(self, current_condition)
	end

end 

local function Clear( self )
	self.card = nil 
	self.select_table, self.select_check = nil,nil
	self.input_table , self.input_check = nil,nil
	self.toUse ={}
	--self:TransitionTo('Wait')
end

local function Add(self,obj,table_type)
	--print('try add ',self , obj ,table_type)
	if self.card then
		if table_type == 'card' and not TableFunc.Find(self.card.use_condition ,'input') then
			local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('error_target')}} }}
			TableFunc.Push(self.queue , o)
			self:Clear()
			self:TransitionTo('Wait')
		end

		local t = table_type..'_table'
		--print('Add',t)
		if self[t] then
			--print('Add obj sucess',t)
			TableFunc.Push(self[t] , obj)
		end

	elseif not self.card and getmetatable(obj)~= Card.metatable then
		local o = {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('error_target')} } } }
		TableFunc.Push(self.queue , o)
	elseif not self.card then
		self.card = obj
		--print('add card')
		--print('add card',self.card)
	end
end
local function InitUse_condition(self)
	local card=self.card
	local input = TableFunc.Find(card.use_condition,'input') 
	local select = TableFunc.Find(card.use_condition,'select')
	if input then
		--print('init input')
		self.input_table={} 
		self.input_check={} -- 滿足條件會移除 condition
	end
	if select then 
		--print('init select')
		self.select_table={} 
		self.select_check={} 
	end

	for k,v in pairs(card.use_condition) do
		--table.insert(self.target_table, {})
		local choose_type=v[1]
		local num =v[2]
		local race=v[3]
		local max ,min

		local current_table = choose_type == 'input' and self.input_check or self.select_check
		table.insert(current_table,{})
		local len = #current_table

		if type(num)=='string' then
			local p = num:find('~')
			local a = tonumber(num:sub(1,p-1)) 
			local b = tonumber(num:sub(p+1,#num))
			max,min=math.max(a,b) ,math.min(a,b)
			current_table[len]['max']=max
			current_table[len]['min']=min
			current_table[len]['choose_type']=choose_type
			current_table[len]['race']=race
		else
			current_table[len]['max']=num
			current_table[len]['min']=num
			current_table[len]['choose_type']=choose_type
			current_table[len]['race']=race
		end	
	end
end

local Choose={}

function Choose.new(option)

	local Wait = State.new("Wait")
	local CheckCost = State.new("CheckCost")
	local CheckSelect = State.new("CheckSelect")
	local CheckInput = State.new("CheckInput")
	--local InputWait = State.new("InputWait")
	local PrepareToUse = State.new("PrepareToUse")
	local machine = Machine.new({
		initial=Wait,
		states={
			Wait  ,CheckCost ,CheckSelect ,CheckInput  ,PrepareToUse --,InputWait
		},
		events={
			--[[ 	Wait(global)					
			 CheckCost--> CheckSelect --> CheckInput --> PrepareToUse
			 								^ 
			 								|
			 								v
			 							  InputWait
     					 				]]

			{state=Wait,global=true,self=true},							

			{state=CheckCost,to='CheckSelect'},
			{state=CheckCost,to='CheckInput'},

			{state=CheckSelect,to='CheckInput'},
			{state=CheckSelect,to='PrepareToUse'},
			--{state=CheckInput,to='InputWait'},
			{state=CheckInput,to='PrepareToUse'},
			--{state=InputWait,to='CheckInput'},


		}
	})
	machine.condition=option or nil
	machine.card =nil
	machine.LoopAdd=LoopAdd
	machine.Add=Add
	machine.Clear=Clear
	machine.queue={}
	machine.toUse={}
	Wait.Do=function(self,battle,...)
		
		if machine.card then
			print('TransitionTo cost')
			machine:TransitionTo('CheckCost',battle)
		elseif machine.condition then
			machine:TransitionTo('CheckSelect',battle)
		end
	end
	CheckCost.DoOnEnter =function(self,battle,...)
		local card =machine.card
		if card.data.cost > battle.battleData.actPoint then
			machine.card=nil
			local o= {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('actpoint_not_enough')}} }}
			TableFunc.Push(machine.queue , o)
		else
			machine.toUse.card = machine.card
			InitUse_condition(machine)

			if TableFunc.Find(card.use_condition,'input')	and not TableFunc.Find(card.use_condition,'select')	then
				--print('view TransitionTo ExtraInput')
				local o= {toViewScene={command={key='TransitionTo' ,arg={'ExtraInput'}} }}
				TableFunc.Push(machine.queue , o)
				
				local current_condition = machine.input_check[1]
				MakeDiff(machine , current_condition )
			else	
				local o= {toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('need_target')} } } }
				TableFunc.Push(machine.queue , o)
			end
		end
	end
	CheckCost.Do=function(self,battle,...)
		if machine.select_table and #machine.select_table >0 then
			print('TransitionTo Select')
			machine:TransitionTo('CheckSelect',battle)
		end
	end
	CheckSelect.DoOnEnter =function(self,battle,...)

		for i,target in pairs(machine.select_table) do
			--TableFunc.Dump(target)
			for k,t in pairs(machine.select_check) do
				--print('target race ',target.race ,t.race)
				if target.race == t.race then
					if machine.input_table then
						print('Select TransitionTo Input')
						local o= {toViewScene={command={key='TransitionTo' ,arg={'ExtraInput'}} }}
						TableFunc.Push(machine.queue , o)
						machine:TransitionTo('CheckInput',battle)
						return
					else
						machine:TransitionTo('PrepareToUse',battle)
						return 
					end
				end
			end
		end
		machine:Clear()
		local msg = #machine.select_table>0 and 'error_target'  or 'need_target'
		local o={toViewScene={command={key='WaitIoRead' ,arg={Msg.msg(msg)}} }}
		TableFunc.Push(machine.queue , o)
		machine:TransitionTo('Wait')
	end

	CheckInput.DoOnEnter=function(self,...)	
		local input,enforce,battle =...
		print('...',...)
		local diff
		if machine.input_table then
			print('let\'s CheckInput')
			for i=1,#machine.input_check do
				local current_condition = machine.input_check[1]
				--確認種類
				for i,target in pairs(machine.input_table) do
					if getmetatable(target)~= Card.metatable then
						machine:Clear()
						local o={toViewScene={command={key='WaitIoRead' ,arg={Msg.msg('error_target')}} }}
						TableFunc.Push(machine.queue , o)
						machine:TransitionTo('Wait')
						return
					end
				end

				if not enforce then
					print('not enforce',enforce)
					MakeDiff(machine , current_condition )
					machine:TransitionTo('InputWait')
					return
				end
				--確認數量
				if #machine.input_table > current_condition.max or #machine.input_table < current_condition.min then
					--print('still need ',#machine.input_table ,tab.max ,tab.min)
					MakeDiff(machine , current_condition )
					machine:TransitionTo('InputWait')
					return
				else
					local name = 'input_target_'..i
					machine.toUse.name = {}
					for i=#machine.input_table, 1 ,-1 do
						TableFunc.Push(machine.toUse.name , machine.input_table[1] )
						TableFunc.Shift(machine.input_table) 
					end
					TableFunc.Shift(machine.input_check)
					print('complete input',name)  
				end
			end
			machine:TransitionTo('PrepareToUse',battle)
		else
			--print('TransitionTo PrepareToUse')
			machine:TransitionTo('PrepareToUse',battle)
		end
	end
	--[[InputWait.DoOnEnter=function(self,battle,...)
		print('input wait')
		self.current_num = #machine.input_table
	end
	InputWait.Do=function(self,battle,...)
		if #machine.input_table > self.current_num then
			machine:TransitionTo('CheckInput')
		end
	end]]
	PrepareToUse.DoOnEnter=function(self,battle,...)
		local card = machine.card
		local heroData =battle.characterData.heroData
		local monData = battle.characterData.monsterData

		--製作target
		if machine.select_table then
			--print('prepare select_table')	
			local obj = machine.select_table[1]
			local race_table = obj.race =='hero' and heroData or monData
			local index = TableFunc.Find(race_table,obj)	
			assert(index,'can\'t find target in race_table')

			local current_condition
			for k,v in pairs(machine.select_check) do
				if TableFunc.Find(v , obj.race ,'race') then 
					current_condition=v
					break
				end
			end
			assert(current_condition,'can\'t find current_condition')
			local need_num = current_condition.max
			
			if need_num == 4 or need_num >= #race_table then
				machine.toUse.select_table=race_table
			elseif need_num > 1 then
				local diff = need_num-1--(扣掉target_table已經包含的一個)
				local reverse = 0

				if index+diff > #race_table then
					reverse = index+diff - #race_table
					local start_index =index+1
					for i=start_index ,#race_table do
						table.insert(machine.select_table ,race_table[i])
					end
					for i=1,reverse do
						table.insert(machine.select_table ,race_table[index-i])
					end
				else
					for i=1,diff do
						table.insert(machine.select_table ,race_table[index+i])
					end
				end
			end
			print('PrepareToUse select done')
			
		end
		local o ={toPending={command={key='ReadyToUse' ,arg={ machine.toUse }} }}
		print('PrepareToUse done')

	end
	machine.Update=function(self,...)
		if #machine.queue > 0 then
			local o = TableFunc.Shift(machine.queue)			
			return o
		end
		self.current:Do(...)
		--print(self.current.name)
	end
	return machine
end

--Choose.metatable.__index=function (table,key) return Choose.default[key] end

return Choose