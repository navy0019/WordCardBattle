local TableFunc = require("lib.TableFunc")
local StringAct = require("lib.StringAct")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local CardLogic={}

local function AddBuff(card,buff)--{buff={atk=1,round=1},times=2}
	for k,str in pairs(card.type) do
		for key,value in pairs(buff.buff) do
			if str:find(key) then
				return
			end
		end
	end
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
	machine.act_maching = StringAct.NewMachine()
	Wait.Do=function(self,battle,...)	
		if #machine.pending >0 then
			--print('TransitionTo Classification')
			machine:TransitionTo('Classification',battle)
		end
	end
	Classification.DoOnEnter=function(self,battle,...)
		for i=1,#machine.pending do
			local v = TableFunc.Shift(machine.pending)
			local target_tab = v.card and machine.card_pending or machine.state_pending
			TableFunc.Push(target_tab,v)
		end
		machine:TransitionTo('CheckBuff',battle)
	end
	CheckBuff.DoOnEnter=function(self,battle,...)
		if #machine.state_pending ==0 then
			machine:TransitionTo('ReadEffect',battle)
		else	
			for k,buff in pairs(machine.state_pending) do
				for i,card in pairs(machine.card_pending) do
					AddBuff(card ,buff)
				end			
			end
		end
		
	end
	ReadEffect.DoOnEnter=function(self,battle,...)
		--print('ReadEffect!'..#machine.card_pending)
		for i=1, #machine.card_pending do
			local v = TableFunc.Shift(machine.card_pending)
			--TableFunc.Dump(v)
			battle.battleData.actPoint = battle.battleData.actPoint - v.card.cost
			--StringAct.UseCard(battle,v)
			local effect=TableFunc.Copy(v.card.effect)
			StringAct.ReadEffect(battle ,machine.act_maching,v.card.effect ,v)
			battle:DropCard(battle.battleData.hand , v.card)
			local o ={ toPending={key='AfterUseCard',arg={v ,battle }} }
			TableFunc.Push(machine.queue , o)
		end
	
		machine:TransitionTo('Wait',battle)
	end
	machine.Update=function(self,battle,...)
		if #machine.queue > 0 then
			--print('cardLogic queue shift')
			local o = TableFunc.Shift(machine.queue)			
			return o
		end
		self.current:Do(battle,...)
	end
	return machine
end
CardLogic.metatable.__index=function (table,key) return CardLogic.default[key] end
return CardLogic