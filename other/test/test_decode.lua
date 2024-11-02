function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   if str:match("(.*/)") then
   	return str:match("(.*/)")
   else
   	return str:match("(.*[/\\])")
   end
end
path = script_path()
local head,tail =path:find('WordCardBattle')
path=path:sub(1,tail+1)

package.path = package.path..';'..path..'?.lua'

local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Cmd = CurrentOs  == 'Mac' and 'ls ' or 'dir '
slash = CurrentOs  == 'Mac' and '/' or '\\' 

local StringDecode = require('lib.StringDecode')
local Resource = require('resource.Resource')
local TableFunc = require('lib.TableFunc')


local file_path = path..'normal_event'
local file_popen = io.popen(Cmd..file_path)

local data = Resource.GetAssets(file_popen, file_path )
TableFunc.Dump(data)

--[[local card_path = path..'card'
local card_popen = io.popen(Cmd..card_path)
      
local card = Resource.GetAssets(card_popen, card_path )
TableFunc.Dump(card)]]
