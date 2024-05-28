local Room_Event={normal_event = _G.Resource.normal_event ,rare_event =_G.Resource.rare_event}

local function NewEvent(tab_key , name)
	local event 
	if name then
		event =name
	else
		local t ={}
		--print('tab_key',tab_key)
		for key,v in pairs(Room_Event[tab_key]) do
			TableFunc.Push(t,key)
		end
		event = t[_G.RandomMachine:Random(#t)]
	end
	return event
end

local function Connect(self,target)
	TableFunc.Push(self.connect ,target)
	TableFunc.Push(target.connect ,self) 

end
local function Set_Info(self  ,event ,name)
	--self.numbering=num
	if event:find('event') then
		self.event=NewEvent(event ,name)
	else
		self.event=event
	end
	
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