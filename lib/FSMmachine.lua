local TableFunc = require("lib.TableFunc")

local function AddTransition(self,event)
	local name = event.state.name
	if event.to then
		self.states[name].to = self.states[name].to or {}
		if not TableFunc.Find(self.states[name].to , event.to) then
			TableFunc.Push(self.states[name].to  ,event.to)
		end
	elseif event.global then 
		self.states[name].to = {}
		for k,v in pairs(self.states) do
			if v~= event.state then
				if not TableFunc.Find(self.states[name].to, v.name) then
					TableFunc.Push(self.states[name].to ,v.name)
				end
				if not TableFunc.Find(v.to, name) then
					TableFunc.Push(v.to , name)
				end		
			end
			if event.self and not TableFunc.Find(self.states[name].to, name) then -- self:是否包含自己 
				TableFunc.Push(self.states[name].to ,name)
			end	
		end
	else
		assert(nil,' none events ')
	end
end
local function DelTransition(self,state,ToName)
	local name = state.name
	local p = TableFunc.Find(self.states[name].to,ToName)
	if p then
		table.remove(self.states[name].to ,p)
	end

end
local function TransitionTo(self,ToName,...)
	local name = self.current.name

	assert(self.states[name].to ,name.." doesn't have table ")
	assert(TableFunc.Find(self.states[name].to,ToName) ,name.." can't trans to "..ToName)
	self.current:DoOnLeave(...)
	self.pre=self.current
	self.current=self.states[ToName]
	--print(self.current.name)
	self.current:DoOnEnter(...)
end

local function Update(self,...)
	self.current:Do(...)
end
local FSMmachine={Update=Update,AddTransition=AddTransition,DelTransition=DelTransition,TransitionTo=TransitionTo}
FSMmachine.__index=FSMmachine

function FSMmachine.new(options)
	local fsm = {}
	setmetatable(fsm, FSMmachine)
	fsm.current = options.initial or 'Nothing'
	fsm.pre=nil 
	fsm.states={}
	fsm.events={}
	for k, state in pairs(options.states) do
		local name = state.name
		fsm.states[name]=state
		fsm[name]=fsm.states[name]
	end
	for k, event in pairs(options.events) do
		fsm:AddTransition(event)
	end
	return fsm
end


return FSMmachine
