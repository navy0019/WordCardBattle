local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local LoopMachine = {}
function LoopMachine.new()
	local Empty = State.new("Empty")
	local InitData = State.new("InitData")
	InitData.loopNum=0
	local Wait = State.new("Wait")
	local Dofunc = State.new("Dofunc")
	local loopMachine = Machine.new({
		initial=Empty,
		states={Empty,InitData,Dofunc,Wait},
		events={
			{state=Empty,to='InitData'},
			{state=InitData,to='Dofunc'},
			{state=Dofunc,to='Empty'},
			{state=Dofunc,to='Wait'},
			{state=Wait,to='Dofunc'}
		}
	})

	InitData.DoOnEnter=function(self,waitTime,loopNum,func,...)
		self.argTab={...}
		self.func=func
		self.loopNum=loopNum
		self.count = 0
		Wait.waitTime=waitTime
	end
	InitData.Do=function(self,dt)
		loopMachine:TransitionTo('Dofunc')
	end
	Dofunc.Do=function (self,dt)
		if InitData.count< InitData.loopNum then
			InitData.func(InitData.count,table.unpack(InitData.argTab) )
			InitData.count=InitData.count+1
			loopMachine:TransitionTo('Wait')
		else
			loopMachine:TransitionTo('Empty')
		end
	end
	Wait.Do=function(self,dt)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			loopMachine:TransitionTo('Dofunc')
		end
	end
	return loopMachine
end
return LoopMachine