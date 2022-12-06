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

--測試部分指令
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')

local testData=require('test_data')
local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

local command={
	
	--[[{'1','> 0'},
	{'2','1','sum'},
	'enemy',
	'enemy 2',
	'enemy [get data.hp ,> 2]',
	{'enemy','copy'},
	{'enemy' ,'length'},
	'array []',
	'array [a,b,c]',
	'array [2,23 ,55]',
	'array [true,false,false]',
	{'array []','copy','copy','push 2','push 5'},
	'random 10',
	'random 5~10',
	'random 2 enemy',
	'random 1~2 enemy',
	'random 2~5 enemy[get data.hp , >2]',
	'random 1~2 array[2,3,4,10]',
	'loop 2 [random 5 , array[10,20] ]',]]
	'loop random 1~3 [array[1,2,3]]',
	
}

local toUse ={target_table = monsterData }
local machine=StringAct.NewMachine()

for k,v in pairs(command) do
	local effect = type(v)=='string' and {v} or v
	print('\n\teffect '..k)
	StringAct.ReadEffect(testData ,machine ,effect ,toUse ,'print_log')
	--print(type(machine.stack[#machine.stack]),'\n')
	machine.stack={}
end
