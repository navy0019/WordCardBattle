local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local monsterAI = {}
function monsterAI.new()
	local Idle = State.new("Idle")
	local Act  = State.new("Act")
	local Death = State.new("Death")

	local mAI=Machine.new({
		initial=Idle,
		states={
			Idle  ,Act ,Death
		},
		events={
			{state=Idle,to='Act'},
			{state=Idle,to='Death'},

			{state=Act,to='Idle'},
			{state=Act,to='Death'},

		}
	})
	Idle.CheckCondition=function(self,mon,battle)
		if mon.data.hp <=0 then
			mAI:TransitionTo('Death')
		else
			mAI:TransitionTo('Act',mon,battle)
		end
	end
	Idle.Do=function(self,mon,battle) self.CheckCondition(self,mon,battle) end


	Act.DoOnEnter=function(self,mon,battle)
		if mon.data.hp <=0 then
			mAI:TransitionTo('Death')
		else
			mon:DoAct(battle)
			mAI:TransitionTo('Idle',mon,battle)
		end
	end

return mAI
end

return monsterAI


