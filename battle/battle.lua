local TableFunc = require("lib.TableFunc")
local StringDecode = require('lib.StringDecode')

local CardAssets = require("resource.cardAssets")

local MonsterGenerator = require("battle.monsterGenerator")
local MonsterAI = require('battle.monsterAI')
local BattleRoundMachine = require('battle.battleRoundMachine')
local BattleInput = require('battle.battleInput')

local Battle = {}

function Battle.InitBattleData(battle, scene)
	local adv_data = scene.adv_data
	local seed = scene.events.ranSeed
	--math.randomseed(seed)
	_G.RandomMachine:Set_seed(_G.RandomMachine.seed)

	local skill_card = {}

	battle.characterData.monsterData = MonsterGenerator.RandomMonster(adv_data)
	for k, m in pairs(battle.characterData.monsterData) do
		local holder = 'monster ' .. TableFunc.GetSerial(m)
		TableFunc.Push(skill_card, {})
		local len = #skill_card
		for i, skill in pairs(m.skill) do
			local mon_skill_card = CardAssets.instance(skill, holder)
			TableFunc.Push(skill_card[len], mon_skill_card)
		end
		m.AI = MonsterAI.new(battle, m, skill_card[len], seed)
	end

	battle.characterData.heroData = adv_data.heroData

	for k, hero in pairs(battle.characterData.heroData) do
		hero.data.team_index = k
		for i, name in pairs(hero.skill) do
			local serial = 'hero ' .. TableFunc.GetSerial(hero)
			local card = CardAssets.instance(name, serial) --CardAssets.instance( name,0,0,hero ,battle )
			for j, str in pairs(card.use_condition) do
				--print('str', str)
				local select_type, number, race = StringDecode.Split_by(str, '%s')
				number = tonumber(number) and tonumber(number) or number
				card.use_condition[j] = { select_type, number, race }
			end
			TableFunc.Push(battle.battleData.deck, card)
		end
	end

	TableFunc.Upset(battle.battleData.deck)
	battle.battleData.deckSize = #battle.battleData.deck
end

local function DropCard(self, fromTab, card)
	local Card = require('lib.card')
	if getmetatable(card) == Card.metatable then
		TableFunc.Push(self.battleData.drop, card)
		local p = TableFunc.Find(fromTab, card)
		table.remove(fromTab, p)
		--card.parentTab=self.battleData.drop

		--丟完牌更新手牌位置
		for k, v in pairs(self.battleData.hand) do
			v.handPos = k
		end
	else
		local cards = TableFunc.DeepCopy(card)
		for k, v in pairs(cards) do
			TableFunc.Push(self.battleData.drop, v)
			--v.parentTab=self.battleData.drop
			local p = TableFunc.Find(fromTab, v)
			table.remove(fromTab, p)
		end
	end
end

local function DropItem(self, char)
	if char.race == 'enemy' then
		local ran = _G.rng:random(#char.dropItem)
		TableFunc.Push(self.endingItem, char.dropItem[ran])
	end
end
local function CheckAlive(battle)
	function check(datas)
		if #datas == 0 then
			return true
		end
		return false
	end

	local heros = check(battle.characterData.heroData)
	local monsters = check(battle.characterData.monsterData)

	if heros then
		return 'Lose'
	elseif monsters then
		return 'Victory'
	end

	return false
end

local function Backfill(battle)
	TableFunc.Upset(battle.battleData.drop, battle.rng)
	for i = 1, #battle.battleData.drop do
		local card = TableFunc.Shift(battle.battleData.drop)
		TableFunc.Push(battle.battleData.deck, card)
	end
end
local function Deal(battleData)
	local card = TableFunc.Shift(battleData.deck)
	TableFunc.Push(battleData.hand, card)
end
local function DealProcess(battle, num)
	local compare_num = num or battle.battleData.dealNum
	local dealNum = math.min(#battle.battleData.deck, compare_num)

	for i = 1, dealNum do
		Deal(battle.battleData)
	end
	if dealNum < compare_num then
		Backfill(battle)
		for i = 1, compare_num - dealNum do
			Deal(battle.battleData)
		end
	end
end
local function ClearDeath(battle)
	local heroData = battle.characterData.heroData
	local monsterData = battle.characterData.monsterData
	for i = #heroData, 1, -1 do
		local character = heroData[i]
		if character.data.hp <= 0 then
			table.remove(heroData, i)
		end
	end
	for i = #monsterData, 1, -1 do
		local character = monsterData[i]
		if character.data.hp <= 0 then
			table.remove(monsterData, i)
		end
	end
end
local function Update(self, scene)
	--print('battle update',self , scene)
	self.round_machine:Update(self, scene)
	self.input_machine:Update(self, scene)
end
Battle.default = {
	DealProcess = DealProcess,
	ClearDeath = ClearDeath,
	DropItem = DropItem,
	CheckAlive = CheckAlive,
	Update = Update,
	DropCard = DropCard
}
Battle.metatable = {}

function Battle.new(scene)
	--print('new Battle')
	local o = {
		characterData = { heroData = {}, monsterData = {}, grave = {} },
		battleData = { round = 1, actPoint = 0, dealNum = 5, maxDealNum = 7, deck = {}, hand = {}, drop = {}, disappear = {} },
		endingItem = {}
	}
	o.pending = {}

	o.round_machine = BattleRoundMachine.new(scene.toBattleView)
	o.input_machine = BattleInput.new(scene.toBattleView)

	o.func_tab = {}
	TableFunc.Merge(o.func_tab, o.input_machine.funcTab)

	setmetatable(o, Battle.metatable)
	return o
end

Battle.metatable.__index = function(table, key) return Battle.default[key] end

return Battle
