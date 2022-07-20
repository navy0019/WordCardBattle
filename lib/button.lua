local Button={}

local function Check( Button,mouseX,mouseY)
	if  mouseX >= Button.sprite.transform.position.x-Button.sprite.transform.offset.x and mouseX <= Button.sprite.transform.position.x + Button.width -Button.sprite.transform.offset.x  and 
		mouseY >= Button.sprite.transform.position.y-Button.sprite.transform.offset.y and mouseY <= Button.sprite.transform.position.y + Button.height -Button.sprite.transform.offset.y  then
			return true
		else
			return false
		end
end
local function LockSwitch( self)
	if self.isLock then
		self.isLock=false
	else
		self.isLock=true
	end
end
local function OnClick()	
end
local function OnHold()	
end
local function OnRelease()	
end
--,width=0,height=0,color={1,1,1,1},normal={},press={},lock={}
Button.default={isLock=false,Check=Check,OnClick=OnClick,OnHold=OnHold,OnRelease=OnRelease,LockSwitch=LockSwitch}
Button.metatable={}
function Button.new(o)
	o.sprite=nil
	setmetatable(o,Button.metatable)

	return o
end
Button.metatable.__index=function (table,key) return Button.default[key] end

return Button