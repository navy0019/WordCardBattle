local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")

local TableFunc = require("lib.TableFunc")
local Choose = require('lib.choose')

local CardAssets = require("resource.cardAssets")

local MonsterGenerator = require("battle.monsterGenerator")
local BattleMachine = require('battle.battleMachine')

local Battle={}

function Battle.InitBattleData(battle,scene)
	local AdvGenerator=scene.AdvGenerator
	local seed =scene.events.ranSeed
	math.randomseed(seed)

	local roomNum = AdvGenerator.mapData.passedRoom
	battle.characterData.monsterData=MonsterGenerator.RandomMonster(roomNum)
	
	battle.characterData.heroData=AdvGenerator.heroData

	for k,hero in pairs(battle.characterData.heroData) do
		hero.data.team_index=k
	 	for i,name in pairs(hero.skill) do
	 		local serial = 'hero '..TableFunc.GetSerial(hero)
	 		local card = CardAssets.instance( name,serial )--CardAssets.instance( name,0,0,hero ,battle )
	 		TableFunc.Push(battle.battleData.deck,card)
	 	end
	end

	TableFunc.Upset(battle.battleData.deck)
	battle.battleData.deckSize= #battle.battleData.deck

end
local function CardWordUpdate(self)--InfoUpdate
	for k,v in pairs(self.battleData.deck) do
		v:Update()
	end
	for k,v in pairs(self.battleData.hand) do
		v:Update()
	end
	for k,v in pairs(self.battleData.drop) do
		v:Update()
	end
	for k,v in pairs(self.battleData.disappear) do
		v:Update()
	end
end
local function DropCard(self,originTab,card)
	local Card=require('lib.card')
	if getmetatable(card)==Card.metatable then

		TableFunc.Push(self.battleData.drop ,card)
		local p = TableFunc.Find(originTab,card)
		table.remove(originTab,p)
		--card.parentTab=self.battleData.drop

		--丟完牌更新手牌位置
		for k,v in pairs(self.battleData.hand) do
			v.handPos=k
		end		
		
	else
		local cards = TableFunc.DeepCopy(card)
		for k,v in pairs(cards) do
			TableFunc.Push(self.battleData.drop ,v)
			--v.parentTab=self.battleData.drop
			local p=TableFunc.Find(originTab,v)
			table.remove(originTab,p)
		end
	end
end 

local function DropItem(self,char)
	if char.race=='enemy' then
		local ran=_G.rng:random(#char.dropItem)
		TableFunc.Push(self.endingItem ,char.dropItem[ran]) 
	end
end
local function CheckLife(battle)
	function check(datas)
		for k,v in pairs(datas) do
			if v.state.current.name ~= 'Death' then
				return false
			end
		end
		return true
	end
	local heros = check(battle.characterData.heroData)
	local monsters = check(battle.characterData.monsterData)

	if heros then
		battle.machine:TransitionTo('WaitEnding',battle,'Lose')	
	elseif monsters then
		battle.machine:TransitionTo('WaitEnding',battle,'Victory')

	end
end
local function ClearDeath(battle)
	local heroData=battle.characterData.heroData
	local monsterData=battle.characterData.monsterData
	for i=#heroData,1,-1 do
		--[[if battle.characterData.heroData[i].state.current.name =='Death' then
			table.remove(battle.characterData.heroData,i)
			table.remove(SaveMgr.CurrentSave.CurrentTeam,i)
		end]]
		if heroData[i].data.hp <= 0 then
			table.remove(heroData,i)
		end
	end
	for i=#monsterData,1,-1 do
		--[[if battle.characterData.monsterData[i].state.current.name =='Death' then
			table.remove(battle.characterData.monsterData,i)
		end]]
		if monsterData[i].data.hp <= 0 then
			print('remove')
			table.remove(monsterData,i)
		end
	end
	return true
end
local function RemoveDeathCard(battle,char)
	if char.race=='hero' then
		for k,skill in pairs(char.skill) do
			if TableFunc.Find(battle.battleData.deck ,char,'master') then
				local p = TableFunc.Find(battle.battleData.deck ,char,'master')
				battle.battleData.deckSize=battle.battleData.deckSize-1
				table.remove(battle.battleData.deck , p)

			elseif TableFunc.Find(battle.battleData.hand ,char,'master') then
				local p = TableFunc.Find(battle.battleData.hand ,char,'master')

				table.remove(battle.battleData.hand , p)

			elseif TableFunc.Find(battle.battleData.drop ,char,'master') then
				local p = TableFunc.Find(battle.battleData.drop ,char,'master')
				battle.battleData.dropSize=battle.battleData.dropSize-1
				table.remove(battle.battleData.drop , p)
			end
		end
	end
end
local function Backfill(battle)
	TableFunc.Upset(battle.battleData.drop , battle.rng)
	for i=1,#battle.battleData.drop do
		local card = TableFunc.Shift(battle.battleData.drop )
		TableFunc.Push(battle.battleData.deck , card)	
	end	
end
local function Deal(battleData)
	local card = TableFunc.Shift(battleData.deck )
	TableFunc.Push(battleData.hand, card)
end
local function DealProcess(battle , num)
	local compare_num = num or battle.battleData.dealNum
	local dealNum = math.min(#battle.battleData.deck , compare_num)

	for i=1,dealNum do
		Deal(battle.battleData)	
	end
	if dealNum < compare_num then
		Backfill(battle)
		for i=1,compare_num-dealNum do
			Deal(battle.battleData)	
		end
	end
end
local function Update( self,scene,dt  )
	self.machine:Update(self,scene,dt)
end 
Battle.default={DealProcess=DealProcess,ClearDeath=ClearDeath,DropItem=DropItem,RemoveDeathCard=RemoveDeathCard,CheckLife=CheckLife,Reset=Reset,Update=Update,DropCard=DropCard ,CardWordUpdate=CardWordUpdate}
Battle.metatable={}

function Battle.new(scene)
	--print('new Battle')
	local o ={characterData={heroData={},monsterData={},grave={}},
		battleData={round=1,actPoint=0,dealNum=5,maxDealNum=7,deck={},hand={},drop={},disappear={}},
		endingItem={},choose={Choose.new()}
	}

	--o.label=label or nil
	--Battle.InitBattleData(o ,scene)
	o.machine=BattleMachine.new(o,scene)
	
	--o.keyCtrl = scene.keyCtrl

	--[[o.signal=CallBack.new()		
	o.signal:Register('Act',function(char,card)
		o.battleMachine.statusMachine:addUpdate(o,'heroData' ,'always',card)
		o.battleMachine.statusMachine:addUpdate(o,'monsterData' ,'always',card)
	end)]]
	setmetatable(o,Battle.metatable)
	return o
end

function Battle.CountAlive(datas)
	local num
	local deadCount = 0
	for k,m in pairs(datas) do
		if m.state.current.name =='Death' then
			deadCount=deadCount+1			
		end
		num=k-deadCount
	end
	return num
end
function Battle.CountBuff(datas,key)
	local num=0
	for k,v in pairs(datas) do
		for j,s in pairs(v.state[key]) do
			num=num+1
		end	
	end
	return num
end

function Battle.MonsterAct(self)
	local num=0
	local deadCount = 0
	for k,m in pairs(self.characterData.monsterData) do
		if m.state.current.name =='Death' then
			deadCount=deadCount+1			
		end
		num=k-deadCount
		m.state:Update( m ,self ,num)
	end
end

Battle.metatable.__index=function (table,key) return Battle.default[key] end

return Battle