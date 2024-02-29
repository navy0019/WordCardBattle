local function ClearState(self)
	self.state={round_start={}, round_end={}, condition={}}
end

local Character = {}

Character.default={ClearState=ClearState}
Character.metatable={}
function Character.new(o)

	o.state={round_start={}, round_end={}, condition={}}

	setmetatable(o,Character.metatable)
	return o
end
Character.metatable.__index=function (table,key) return Character.default[key] end

return Character