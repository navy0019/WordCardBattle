local TableFunc = require("lib.TableFunc")
local StringAct = require("lib.StringAct")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StateHandler = require('battle.StateHandler')
local universal_func = require('lib.command_act.universal_func')

local CardLogic={}

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
		for i=1, #machine.card_pending do
			local v = TableFunc.Shift(machine.card_pending)

			battle.battleData.actPoint = battle.battleData.actPoint - v.card.cost
			local effect=TableFunc.DeepCopy(v.card.effect)
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