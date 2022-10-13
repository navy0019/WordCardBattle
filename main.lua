function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   if str:match("(.*/)") then
   	return str:match("(.*/)")
   else
   	return str:match("(.*[/\\])")
   end
end
path = script_path()
--print('path ',path)
package.path = package.path..';'..path..'?.lua'

local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Resource = require('resource.Resource')
GameMachine = require('GameMachine')
local TableFunc=require('lib.TableFunc')

Resource.Init()
GameMachine.Init()

--TableFunc.Dump(Resource.card)
--TableFunc.Dump(Resource.character)
--TableFunc.Dump(Resource.translate)
--local x = 1

--not GameMachine.stop
while not GameMachine.stop do
	GameMachine.Update()
	--x=x+1
	--print(x) 
end
print('end ')