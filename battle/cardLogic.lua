local TableFunc = require("lib.TableFunc")
local Simple_Command_Machine = require("battle.SimpleCommandMachine")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StateHandler = require('battle.StateHandler')
--local universal_func = require('lib.command_act.universal_func')
local StringDecode=require('lib.StringDecode')

local CardLogic={}
local function GetTableSerial(t)
	local key = tostring(t)
	local p =key:find(':')
	key=StringDecode.Trim_head_tail( key:sub(p+1,#key) )
	return key
end
local function CopyTable(t)
	local key = GetTableSerial(t)
	local tab =TableFunc.DeepCopy(t)
	tab.key=key
	return tab
end
local function UpdateCopyTable(copy , data ,index)
	local p=index or nil
	if p then
		copy[p]=CopyTable(data)
	else
		local key = GetTableSerial(data)
		p =TableFunc.Find(copy ,key ,'key')
		copy[p]=CopyTable(data)
	end
end
local function CompareData(machine,battle)
	--只比較data 不比較state
	local copy_heroData = machine.copy_data.heroData
	local copy_monsterData = machine.copy_data.monsterData
	--print('copy_data',#copy_heroData,#copy_monsterData)
	local t={}
	for k,hero in pairs(battle.characterData.heroData) do		
		local key = GetTableSerial(hero)
		local p =TableFunc.Find(copy_heroData ,key ,'key')
		if p then
			local originData = copy_heroData[p]
			local hit = (originData.data.shield - hero.data.shield) + (originData.data.hp - hero.data.hp) 
			if hit > 0 then
				UpdateCopyTable(copy_heroData , hero ,p)
				TableFunc.Push(t ,{name=hero.key,hit=hit})
			end
		end
	end
	for k,mon in pairs(battle.characterData.monsterData) do		
		local key = GetTableSerial(mon)
		local p =TableFunc.Find(copy_monsterData ,key ,'key')
		if p then
			local originData = copy_monsterData[p]
			local hit = (originData.data.shield - mon.data.shield) + (originData.data.hp - mon.data.hp) 
			if hit > 0 then
				UpdateCopyTable(copy_monsterData , mon ,p)
				TableFunc.Push(t ,{name=mon.key,hit=hit})
			end
		end
	end

	return t
end
CardLogic.default={Update=Update}
CardLogic.metatable={}
function CardLogic.new()
	local Wait = State.new("Wait")
	local Classification = State.new("Classification")
	local CheckBuff = State.new("CheckBuff")
	local ReadEffect = State.new("ReadEffect")
	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait  ,Classification,CheckBuff ,ReadEffect
		},
		events={
			--[[ 	Wait(global)					
			 Classification-->CheckBuff--> ReadEffect
     					 				]]
			{state=Wait,global=true,self=true},
			{state=Classification,to='CheckBuff'},							
			{state=CheckBuff,to='ReadEffect'},
		}
	})
	machine.pending={}
	machine.queue={}
	machine.card_pending={}
	machine.state_pending={}
	machine.copy_data={heroData={},monsterData={}}
	machine.act_machine = Simple_Command_Machine.NewMachine()
	Wait.Do=function(self,battle,...)	
		if #machine.pending >0 then
			--print('TransitionTo Classification',#machine.pending)
			--print(#machine.pending)
			local heroData =battle.characterData.heroData
			local monsterData  =battle.characterData.monsterData
			for k,v in pairs(heroData) do
				local t = CopyTable(v)
				TableFunc.Push(machine.copy_data.heroData ,t)
			end
			for k,v in pairs(monsterData) do
				local t = CopyTable(v)
				TableFunc.Push(machine.copy_data.monsterData ,t)
			end
			machine:TransitionTo('Classification',battle)
		end
	end
	Classification.DoOnEnter=function(self,battle,...)
		if #machine.pending >0 then--for i=1,#machine.pending do
			local v = TableFunc.Shift(machine.pending)
			local target_tab = v.card and machine.card_pending or machine.state_pending
			TableFunc.Push(target_tab,v)
		end
		machine:TransitionTo('CheckBuff',battle)
	end
	CheckBuff.DoOnEnter=function(self,battle,...)
		for k=#machine.state_pending , 1, -1 do
			local buff =machine.state_pending[k]
			for i,toUse in pairs(machine.card_pending) do
				local card=toUse.card
				local bool = universal_func.match_type(buff.need_type ,card.type)
				if bool then
					StateHandler.Add_Card_Buff(card , buff)
					--TableFunc.Dump(buff)
					if buff.number <= 0 then
						table.remove(machine.state_pending ,k)
					end
				end	
			end			
		end
		machine:TransitionTo('ReadEffect',battle)
		
	end
	ReadEffect.DoOnEnter=function(self,battle,...)
		--print('ReadEffect!'..#machine.card_pending)
		if #machine.card_pending >0 then--for i=1, #machine.card_pending do
			local v = TableFunc.Shift(machine.card_pending)

			battle.battleData.actPoint = battle.battleData.actPoint - v.card.cost
			local effect=TableFunc.DeepCopy(v.card.effect)
			Simple_Command_Machine.ReadEffect(battle ,machine.act_machine ,v.card.effect ,v )

			battle:DropCard(battle.battleData.hand , v.card)
			local data 	 = CompareData(machine,battle)
			local o ={ toPending={key='AfterUseCard',arg={v ,battle ,data}} }
			TableFunc.Push(machine.queue , o)
		end
	
		machine:TransitionTo('Wait',battle)
	end
	machine.Update=function(self,battle,...)
		if #machine.queue > 0 then

			local o = TableFunc.Shift(machine.queue)			
			return o
		end
		self.current:Do(battle,...)
	end
	return machine
end
CardLogic.metatable.__index=function (table,key) return CardLogic.default[key] end
return CardLogic