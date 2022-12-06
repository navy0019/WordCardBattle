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

--[[
測試用 (hp atk..等素質)按照位置全部都是 2 ,3, 4..... 可到test_data裡更改
]]
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')
local GetOs=require('lib.get_os_name')
CurrentOs= GetOs.get_os_name()

Resource = require('resource.Resource')
Resource.Init_Test()


local Battle = require('battle.battle')
local battle = Battle.new()

local testData=require('test_data')
battle.characterData = testData.characterData

local monsterAI=require('battle.monsterAI')
local StateHandler = require('battle.StateHandler')
local CardAssets=require('resource.cardAssets')

local originData =TableFunc.DeepCopy(testData)
local heroData = testData.characterData.heroData
local monsterData =testData.characterData.monsterData

local function MakeToUse()
	local toUse={}
	for k,v in pairs(Resource.card) do
		local master = 'hero '..TableFunc.GetSerial(heroData[1])
		local card=CardAssets.instance(k,master)
		toUse.card =card
		break
	end	
	return toUse
end
local function Init_hand(toUse)
	for i=1,1 do
		local new_card = TableFunc.DeepCopy(toUse.card)
		--new_card.data.atk=i
		TableFunc.Push(battle.battleData.hand ,new_card)
	end
end
local toUse=MakeToUse()
Init_hand(toUse)

local function print_hand_card_state()
	for k,v in pairs(battle.battleData.hand) do
	print('card name: '..v.name..k)
	print('card state:')
	TableFunc.Dump(v.state)
	TableFunc.Dump(v.data)
	print()
end
end
local function Update()
	for k,card in pairs(battle.battleData.hand) do
		for i=#card.state ,1 ,-1 do
			local state = card.state[i]
			StateHandler.Card_State_Update(card ,state)
		end		
	end
	
end
local function TestNext()
	print('next')
	TableFunc.Dump(battle.machine.cardLogic.state_pending)
end

local function Test()
	local effect={'card','add_card_buff hand change_data [times:this_battle ,atk:*2]'}
	--[[
		{'card','add_card_buff current change_data [times:this_battle ,atk:2]'}
		{'card','add_card_buff hand change_data [times:this_battle ,atk:2]'}
		{'add_card_buff next 1 atk_type change_data[times:1 ,atk:*2]'}
	]]
	local machine=StringAct.NewMachine()
	StringAct.ReadEffect(battle ,machine ,effect ,toUse )

	effect = {'card','add_card_buff next 1 melee_type change_data [times:2 ,atk:3]'}
	StringAct.ReadEffect(battle ,machine ,effect ,toUse )

	--effect = {'card','add_card_buff hand change_data [times:1 ,atk:-3]'}
	--StringAct.ReadEffect(battle ,machine ,effect ,toUse )	
	--effect = {'card','add_card_buff hand change_data [times:3 ,atk:5]'}
	--StringAct.ReadEffect(battle ,machine ,effect ,toUse )	
end

print('Add Card State')
Test()
print_hand_card_state()

--[[
print('update 1 ')
Update()
print_hand_card_state()
print()


print('update 2 ')
Update()
print_hand_card_state()
print()

print('update 3 ')
Update()
print_hand_card_state()
print()
]]

--測試next部分
local Card=require('lib.card')
local new_card = battle.battleData.hand[1]
setmetatable(new_card ,Card.metatable)
new_card.effect={}
local new_toUse = {card = new_card}
print('add hand card to pending ',#battle.machine.cardLogic.state_pending)
TableFunc.Push(battle.machine.cardLogic.pending  ,new_toUse)

battle.machine:Update(battle)
TableFunc.Dump(new_card.state)
TableFunc.Dump(new_card.data)
print('state_pending length ',#battle.machine.cardLogic.state_pending)