--local BattleData = require('battle.battleData')
local Choose = require('lib.choose')

local function Update(self, battle, scene)
	self.choose:Update(self, battle, scene)
end
local function AddSomthing(battle, input_machine, input, table_type, ...)
	local map = {
		c = battle.battleData.hand,
		h = battle.characterData.heroData,
		m = battle.characterData.monsterData
	}


	local choose = input_machine.choose
	local key = string.sub(input, 1, 1)
	local num = tonumber(string.sub(input, 2, 2))
	--print('battle Input machine AddSomthing', key, num, table_type)
	assert(map[key][num], 'map can\'t find ' .. key .. num)

	local obj = map[key][num]

	choose:Add(obj, table_type)
end
local function LoopAddCard(battle, input_machine, input)
	local choose = battle.input_logic
	local hand = battle.battleData.hand
	local num = tonumber(string.sub(input, 2, 2))
	local card = hand[num]

	choose:LoopAddCard(card)
end
local function CancelInput(battle, input_machine, ...)
	local choose = input_machine.choose
	choose:Clear()
	return { toBattleView = { key = 'TransitionTo', arg = { 'PlayerAct' } } }
end
local function EndRound(battle, input_machine, ...)
	local machine = battle.machine
	battle:DropCard(battle.battleData.hand, battle.battleData.hand)
	machine:TransitionTo('MonsterAct', battle)
	return { toBattleView = { key = 'TransitionTo', arg = { 'MonsterAct' } } }
end
local function CheckSelectCard(battle, input_machine, ...)
	local choose = input_machine.choose
	choose:TransitionTo('CheckSelectCard', ...)
end
local function ReadyToUse(battle, input_machine, key_dic)
	--local cardLogic = which == 'hero' and battle.machine.hero_cardLogic or battle.machine.monster_cardLogic
	--print('Ready To Use ',which ,key_dic)

	local cardPending = battle.round_machine.card_pending
	TableFunc.Push(cardPending.pending, key_dic)
	--print(#cardLogic.pending )
end
local function AfterUseCard(battle, scene)
	--print('AfterUseCard Data')
	battle:ClearDeath()
	local alive = battle:CheckAlive()
	if alive then
		battle.round_machine:TransitionTo(alive, battle, scene)
	end
	return { toBattleView = { key = 'ViewUseCard', arg = {} } }
end

local BattleInput = {}
BattleInput.default = { Update = Update }
BattleInput.metatable = {}
function BattleInput.new(toView)
	local o = {}
	o.choose = Choose.new(toView)
	o.funcTab = {
		AddSomthing = AddSomthing,
		CheckSelectCard = CheckSelectCard,
		CancelInput = CancelInput,
		ReadyToUse = ReadyToUse,
		--UpdateState=UpdateState,
		--InitPlayerRounde=InitPlayerRounde,
		LoopAddCard = LoopAddCard,
		AfterUseCard = AfterUseCard,
		EndRound = EndRound

	}
	setmetatable(o, BattleInput.metatable)
	return o
end

BattleInput.metatable.__index = function(table, key) return BattleInput.default[key] end
return BattleInput
