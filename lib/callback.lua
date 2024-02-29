local TableFunc = require("lib.TableFunc")

local function Register(tab,funcName , func)
	if not tab[funcName] then
		tab[funcName]={}
	end
	if not TableFunc.Find(tab[funcName],func) then
		TableFunc.Push(tab[funcName],func)
	end
end
local function Emit(tab,funcName,...)
	assert(tab[funcName],funcName..' is nil '..tostring(tab))
	--print(funcName,#tab[funcName])
	for k,func in pairs(tab[funcName]) do
		func(...)
	end
end
local function Attach(self,target,funcName , func)--當target 執行Emit的時候 連帶自己也會執行 如果是要在同個Event下增加func使用Register
	assert(target[funcName],tostring(self)..' can\'t attach to target ,target don\'t have '..funcName..' '..tostring(target))

	self:Register(funcName , func)
	target:Register(funcName,function(...) self:Emit(funcName,...) end)

end
local function Clear(tab,funcName)
	assert(tab[funcName],'can\'t clear '..funcName..' is nil '..tostring(tab))
	tab[funcName]={}
end
local function ClearAll(tab)
	for k,v in pairs(tab) do
		tab:Clear(k)
	end
end
--Clear 保留tab[key] 內容物清空  Remove 移除tab[key]
local function Remove(tab,funcName,func)
	assert(tab[funcName],funcName..' is nil '..tostring(tab))
	local p =TableFunc.Find(tab[funcName],func)
	assert(p,'can\'t fund func in '..funcName)
	table.remove(tab[funcName],p)
end
local function RemoveRegister(tab,funcName)
	tab[funcName]=nil
end
local function RemoveAll(tab)
	for k,v in pairs(tab) do
		tab[k]=nil
	end
end
local function HaveEvent(tab)
	local num = 0
	for k,v in pairs(tab) do
		num = num+1
	end
	return num > 0 and true or false
end
local CallBack={}
CallBack.default={ClearAll=ClearAll,RemoveAll=RemoveAll,HaveEvent=HaveEvent,Register=Register,Emit=Emit,Clear=Clear,Remove=Remove,RemoveRegister=RemoveRegister,Attach=Attach}
CallBack.metatable={}
CallBack.metatable.__index=function (table,key) return CallBack.default[key] end
function CallBack.new()
	local o = {}
	setmetatable(o,CallBack.metatable)
	return o 
end

return CallBack