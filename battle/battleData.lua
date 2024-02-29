local function DropItem(self,char)
	if char.race=='enemy' then
		local ran=_G.rng:random(#char.dropItem)
		TableFunc.Push(self.endingItem ,char.dropItem[ran]) 
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
local function DropCard(self,fromTab,card)
	local Card=require('lib.card')
	if getmetatable(card)==Card.metatable then

		TableFunc.Push(self.battleData.drop ,card)
		local p = TableFunc.Find(fromTab,card)
		table.remove(fromTab,p)
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
			local p=TableFunc.Find(fromTab,v)
			table.remove(fromTab,p)
		end
	end
end 

local BattleData={}
BattleData.default={DealProcess=DealProcess,DropItem=DropItem,Reset=Reset,Update=Update,DropCard=DropCard}
BattleData.metatable={}

function BattleData.new(scene)
	--print('new Battle')
	local o ={
		round=1,actPoint=0,dealNum=5,maxDealNum=7,deck={},hand={},drop={},disappear={},
		endingItem={}
	}

	
	setmetatable(o,BattleData.metatable)
	return o
end


BattleData.metatable.__index=function (table,key) return BattleData.default[key] end
return BattleData