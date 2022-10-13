
local CallBack = require("lib.callback")
--[[local Motion = require("lib.motion")
local Word = require("lib.word")]]

local SceneMgr = require('lib.sceneManager')
local TableFunc = require('lib.TableFunc')

local Math= require('lib.math')


--[[local function HitWordMotion(char,value)
	local currentStack = SceneMgr.CurrentScene.UIMachine.current.stack
	local p = TableFunc.Find(currentStack,'tempprint','name')
	local x , y = char.sprite.transform.position.x +char.width/2 , char.sprite.transform.position.y+100
	local hitWord = Word.new( _G.engPixelFont, math.abs(value), x, y, 0 ,2 ,2 )
	hitWord.t ,hitWord.life =0 ,1.3 
	if value > 0 then 
		hitWord.color = {0,1,0,1}	
		Motion.NewTable(char.motion , Motion.new({0, hitWord.color[1] ,1,0.9},'inCirc' ,function(self,dt)hitWord.color[1] = Motion.Lerp(self,dt) hitWord.color[3]=hitWord.color[1] end ) ) 
	elseif value < 0  then 
		hitWord.color = {1,0,0,1}
		Motion.NewTable(char.motion , Motion.new({0, hitWord.color[2] ,1,0.9},'inCirc' ,function(self,dt)hitWord.color[2] = Motion.Lerp(self,dt) hitWord.color[3]=hitWord.color[2] end ) )
	end
	local wx,wy = hitWord.transform.position.x ,hitWord.transform.position.y
	--TableFunc.Push(SceneMgr.CurrentScene.TempPrint, hitWord)
	TableFunc.Push(currentStack[p].label.Drawable, hitWord)
	TableFunc.Push(currentStack[p].label.Motion, hitWord)
	Motion.NewTable(hitWord.motion , Motion.new({0,wy+28,wy-20,0.8},'outCirc' ,function(self,dt)hitWord.transform.position.y = Motion.Lerp(self,dt)end) )
	Motion.NewTable(hitWord.motion , Motion.new({0,3,1,0.9},'outInCirc' ,function(self,dt)hitWord.transform.scale.x = Motion.Lerp(self,dt) hitWord.transform.scale.y=hitWord.transform.scale.x end ) ) 

end]]
--[[local function HP( char , value,battle)	
	--local battle = SceneMgr.CurrentScene.battle
	--char.hp =  Math.clamp(char.hp + value ,0 , char.originData.hp)

	return true
	local v 
	if value < 0 then
		v= math.min(value+char.shield,0)
	else
		if value+char.hp <= char.originData.hp then
			v= value
		else
			v=math.abs(char.originData.hp-char.hp)
		end
	end

	if ignoreDef then
		--SceneMgr.CurrentScene.dialog:Enqueue(char.name..' 的生命 '..v)	
		char.hp =  clamp(char.hp + value ,0 , char.originData.hp)
	else
		char.shield = math.max(char.shield+value ,0)
		char.hp = clamp(char.hp + v ,0, char.originData.hp)
	end 
	--word motion
	--HitWordMotion(char,v)

	if char.hp <=0 then
		SceneMgr.CurrentScene.dialog:Enqueue(char.name..'死亡')	
		char.state:TransitionTo('Death')
		 _G.Event:Emit('Death',char,battle)
		char:ClearStatus()
		--Motion.NewTable(char.motion , Motion.new({0, 1, -1, 0.8},'linear' ,function(motion,dt) char.color[4] = Motion.Lerp(motion,dt)end) )
	end
	if battle then
		battle:CheckLife()
	end
	-- get hit motion
	if hasMotion then
		local cx =char.sprite.transform.position.x
		Motion.NewTable(char.motion , Motion.new({0 ,cx ,cx-30*char.xDir ,0.3},'outCubic' ,function(motion,dt) char.sprite.transform.position.x  = Motion.Mirror(motion,dt)end))
	end
	
end]]

--[[local function DoAct(self,battle)
	--_G.rng:setState(battle.scene.events.ranState)
	--_G.rng:setSeed(battle.scene.events.ranSeed)
	self:DecideAct(battle.characterData.heroData,battle)
	if self.act then
		local m ,target ,key = self, self.act.target ,self.act.key
		MonsterSkill[key].func(self,target,battle)

		--local cx =self.sprite.transform.position.x
		--Motion.NewTable(self.motion , Motion.new({0 ,cx ,cx+40*self.xDir ,0.4},'outCubic' ,function(motion,dt) m.sprite.transform.position.x  = Motion.Mirror(motion,dt)end))

	local currentStack = SceneMgr.CurrentScene.UIMachine.current.stack
		local p = TableFunc.Find(currentStack,'tempprint','name')
		local x , y = m.sprite.transform.position.x +m.width/2 , m.sprite.transform.position.y+100
		local hitWord = Word.new( _G.engPixelFont, self.act.key, x, y, 0 ,1 ,1 )
		hitWord.t ,hitWord.life =0 ,1.3 
		local wx,wy = hitWord.transform.position.x ,hitWord.transform.position.y
		
		TableFunc.Push(currentStack[p].label.Drawable ,hitWord)
		TableFunc.Push(currentStack[p].label.Motion   ,hitWord)
		Motion.NewTable(hitWord.motion , Motion.new({0,wy+28,wy-20,0.8},'outCirc' ,function(self,dt)hitWord.transform.position.y = Motion.Lerp(self,dt)end) )


	end
end 
local function DecideAct( self ,charData,battle)
	local ran = battle.rng:random(#self.skill)
	local index = 1
	while charData[index].state.current.name == 'Death' do
		if index+1 <= #charData then
			index=index+1
		else
			self.act=false
		end
	end
	local t = charData[index]
	self.act = {self=self,key=self.skill[ran],target=t}
end]]
local function ClearStatus(self)
	self.state={before={}, after={}, always={} ,is_target={}}
end

local Character = {}

Character.default={ClearStatus=ClearStatus}--,GrowByRoomNum=GrowByRoomNum
Character.metatable={}
function Character.new(o)--,skill,advancedSkill,equipment,race,name
	--local o = {equipment=equipment,skill=skill,advancedSkill=advancedSkill,act={},motion={},race=race,data=data,state=MonsterAI.new(),name=name}

	o.state={before={}, after={}, always={} ,is_target={}}

	setmetatable(o,Character.metatable)
	return o
end
Character.metatable.__index=function (table,key) return Character.default[key] end

return Character