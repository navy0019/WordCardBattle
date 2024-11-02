local Character = require('lib.character')
--local Choose = require("lib.choose")
local TableFunc = require("lib.TableFunc")
--local Motion = require("lib.motion")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local Card={}
--[[local function FindInfoPos( card )
	local pos = {}
	for k,v in pairs(card.updateWord) do
		TableFunc.Push(pos, v[2]+(k-1)*2+1)
	end
	return pos
end 
local function Update(card)
	local p=FindInfoPos(card)
	for k,v in pairs(p) do
		card.info[v]=card.updateWord[k][1].string(card)
	end
end
local function CheckMouseRange( target,mouseX,mouseY)
	if  mouseX >= target.sprite.transform.position.x-target.sprite.transform.offset.x and mouseX <= target.sprite.transform.position.x + target.width -target.sprite.transform.offset.x  and 
		mouseY >= target.sprite.transform.position.y-target.sprite.transform.offset.y and mouseY <= target.sprite.transform.position.y + target.height -target.sprite.transform.offset.y  then
			return true
		else
			return false
		end
end
local function OnClick(self)end

local function OnHold(self,choose)
		choose:AddChoose(self)
end
local function OnRelease(self,choose)end

local function MoveDrawOrder(self,num)
	local p = TableFunc.Find(self.parentTab,self)
	if not p then
		assert(nil,self.numbering..'  '..self.handPos)
	end	
	table.remove(self.parentTab ,p)
	table.insert(self.parentTab ,num,self)
end
local function CheckTargetRace(self,mx,my,characterData)
	local heroData = characterData.heroData
	local monsterData = characterData.monsterData
	local result = {race=false,instance=nil}
	for k,v in pairs(heroData) do
		if self.Check(v,mx,my) and v.state.current.name~='Death' and self.battle.battleData.actPoint >= self.cost then
			if self.targetNum <=1 then 
				result = {race=v.race,instance=v}
			else 
				result = {race=v.race,instance=heroData}  
			end 
		end
	end
	for k,v in pairs(monsterData) do
		if self.Check(v,mx,my) and v.state.current.name~='Death' and self.battle.battleData.actPoint >= self.cost  then 
			if self.targetNum <=1 then 
				result = {race=v.race,instance=v}
			else 
				result = {race=v.race,instance=monsterData} 
			end  
		end
	end
	if result.race == self.effectOn then 
		return result 
	else
		return {race=false,instance=nil}
	end
end]]
local function LockSwitch( self )
	if self.isLock then
		self:Unlock()
	else
		--self.isLock=true
		self:Lock()
	end
end
local function Lock( self)
	self.isLock=true
	self.color={0.5,0.5,0.5,1}
end
local function Unlock( self)
	self.isLock=false
	self.color={1,1,1,1}
end


Card.default={Lock=Lock,Unlock=Unlock,LockSwitch=LockSwitch}--Update=Update,MoveDrawOrder=MoveDrawOrder,CheckMouseRange=CheckMouseRange,OnHold=OnHold,OnRelease=OnRelease,OnClick=OnClick,
Card.metatable={}
function Card.new(o)--effectOn,targetNum,holder,Effect,name,numbering,info,dropTo,cardtype,cost,motionType
	--[[local o = {sprite=nil,color={1,1,1,1},handPos=1,isLock=false,level=1, 
		holder=holder,effectOn=effectOn, targetNum=targetNum,Effect=Effect,
		name=name,numbering=numbering,info=info,dropTo=dropTo,type=cardtype,cost=cost,motionType=motionType,
	}]]
	--,onHold=false 
	--o.motionMachine=cardMotionMachine.new()

	setmetatable(o ,Card.metatable)
	return o
end

Card.metatable.__index=function (table,key) return Card.default[key] end


return Card