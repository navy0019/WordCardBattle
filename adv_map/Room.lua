local function Connect(self,target)
	TableFunc.Push(self.connect ,target)
	TableFunc.Push(target.connect ,self) 

end
local function Set_Info(self  ,event)
	--self.numbering=num
	self.event=event
end
local function Is_connect(self , room)
	return TableFunc.Find(self.connect ,room)
end
local Room={}
Room.default={Connect=Connect,Set_Info=Set_Info ,Is_connect=Is_connect}
Room.metatable={}
function Room.new(i,j)
	local o={type='room',numbering=0,pos={i,j},connect={},explore=false,event ='empty'}

	setmetatable(o,Room.metatable)

	return o
end

Room.metatable.__index=function (table,key) return Room.default[key] end
return Room