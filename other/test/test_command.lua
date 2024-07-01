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
local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local TableFunc=require('lib.TableFunc')
local StringDecode  = require('lib.StringDecode')

local testData=require('other.test.data.test_data')
local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

RandomMachine = require('lib.RandomMachine').new()

local nc = StringDecode.Trim_To_Simple_Command('enemy.data.hp > 0') 
--TableFunc.Dump(nc)
local command={
	
	--{'1','> 0'},
	--'target',
	'enemy.data.hp',
	--'enemy', 
	--'enemy (hp : max)',
	'enemy(hp >=3).data.team_index',
	--'enemy( hp:max ,hp > 3)'
	--'enemy(state :spell)',
	--'random (10)',
	--'random (5~10) ',
	--'random(1 ,enemy (hp > 2))',
	--'random(1~2 , enemy)',
	--nc

}

local key_link ={}--target_table = monsterData 
local machine=Simple_Command_Machine.NewMachine()
--TableFunc.Dump(machine)

for k,v in pairs(command) do
	local effect = type(v)=='string' and {v} or v
	print('\n\teffect '..k)
	machine:ReadEffect(testData ,effect ,key_link ,'p')
	--print(type(machine.stack[#machine.stack]),'\n')
	--print('Dump')
	TableFunc.Dump(machine.stack)
	machine.stack={}
end
