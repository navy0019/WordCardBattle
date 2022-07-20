local FSMstate ={}
FSMstate.default={DoOnEnter=function()end,Do=function()end,DoOnLeave=function()end,CheckCondition=function()end}
FSMstate.metatable={}

function FSMstate.new(name)
	local o = {name=name,to={},currentTime=0,waitTime=1}

	setmetatable(o,FSMstate.metatable)
	return o
end
FSMstate.metatable.__index=function (table,key) return FSMstate.default[key] end

return FSMstate