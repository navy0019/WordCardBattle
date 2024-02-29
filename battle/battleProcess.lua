local BattleData = require('battle.battleData')
local BattleMachine = require('battle.battleMachine')
local MonsterGenerator = require("battle.monsterGenerator")
local MonsterAI=require('battle.monsterAI')
local Choose = require('lib.choose')

local function Update( self,scene,dt  )
	self.machine:Update(self,scene,dt)
end 
local function AddSomthing(battle ,input ,table_type, ...)
	local map = { 
				c = battle.battleData.hand,
				h = battle.characterData.heroData,
				m = battle.characterData.monsterData}

	local choose = battle.input_logic
	local key = string.sub(input,1,1)
	local num = tonumber(string.sub(input,2,2))
	--print('data addSomthing',table_type)
	assert(map[key][num],'map can\'t find '..key..num)

	local obj = map[key][num]

	choose:Add(obj,table_type)
end
local function LoopAdd(battle ,input)
	local choose = battle.input_logic
	local hand= battle.battleData.hand
	local num = tonumber(string.sub(input,2,2))
	local card = hand[num]

	choose:LoopAdd(card)
end
local function CancelInput(battle,...)
	local choose = battle.input_logic
	choose:Clear()
	return {toViewScene={key='TransitionTo' ,arg={'PlayerAct'}} }
end
local function EndRound(battle,...)
	local machine = battle.machine
	battle:DropCard(battle.battleData.hand ,battle.battleData.hand )
	machine:TransitionTo('MonsterAct',battle)
	return {toViewScene={key='TransitionTo' ,arg={'MonsterAct'}} }
end
local function CheckInput(battle, ...)
	local choose = battle.input_logic
	choose:TransitionTo('CheckInput',...)
end
local function ReadyToUse(key_link, battle ,which)
	local cardLogic = which=='hero' and battle.machine.hero_cardLogic or battle.machine.monster_cardLogic
	--print('Ready To Use ',which ,key_link)
	TableFunc.Push(cardLogic.pending  ,key_link)
	--print(#cardLogic.pending )
end

local function ClearDeath(battle)
	print('ClearDeath!')
end
local BattleProcess={}
BattleProcess.default={ClearDeath=ClearDeath,CheckAlive=CheckAlive,Update=Update}
BattleProcess.metatable={}
function BattleProcess.new()
	local o={characterData={heroData={},monsterData={},grave={}},
			battleData = BattleData.new(),

	 }
	o.input_logic = Choose.new()
	o.machine=BattleMachine.new(o)
	o.funcTab={
		AddSomthing=AddSomthing,
		CheckInput=CheckInput,
		CancelInput=CancelInput,
		ReadyToUse=ReadyToUse,
		ClearDeath=ClearDeath,
		UpdateState=UpdateState,
		InitPlayerRounde=InitPlayerRounde,
		LoopAdd=LoopAdd,
		AfterUseCard=AfterUseCard,
		EndRound=EndRound

	}
	setmetatable(o,BattleProcess.metatable)
	return o	
end

BattleProcess.metatable.__index=function (table,key) return BattleProcess.default[key] end
return BattleProcess