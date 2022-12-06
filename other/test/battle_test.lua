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

--AI戰鬥
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')

local testData=require('test_data')
local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData