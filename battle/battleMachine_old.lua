local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local Choose = require('lib.choose')
local Msg= require('resource.Msg')
local TableFunc = require("lib.TableFunc")

local StateHandler =require("battle.StateHandler")

local BattleMachine={}
--[[
	machine.choose :卡牌&目標放入此內 做初次判定(行動點數是否足夠 目標是否正確)後放入cardEffect	
	machine.pending :所有要執行的事(每個state的事,鍵盤傳來的事件,使用卡牌)(執行失敗會assert) 會return 東西給ViewScenes & pending & cardEffect
]]
local function AddSomthing(battle ,input ,table_type, ...)
	local map = { 
				c = battle.battleData.hand,
				h = battle.characterData.heroData,
				m = battle.characterData.monsterData}

	local machine = battle.machine
	local choose = machine.choose
	local key = string.sub(input,1,1)
	local num = tonumber(string.sub(input,2,2))
	--print('data addSomthing',table_type)
	assert(map[key][num],'map can\'t find '..key..num)

	local obj = map[key][num]

	--print('AddSomthing',machine.choose)
	machine.choose:Add(obj,table_type)
end
local function LoopAdd(battle ,input)
	local machine = battle.machine
	local hand= battle.battleData.hand
	local num = tonumber(string.sub(input,2,2))
	local card = hand[num]

	machine.choose:LoopAdd(card)
end
local function CancelInput(battle,...)
	local choose = battle.machine.choose
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
	local choose = battle.machine.choose
	choose:TransitionTo('CheckInput',...)
end
local function ReadyToUse(key_link, battle ,which)
	local cardLogic = which=='hero' and battle.machine.hero_cardLogic or battle.machine.monster_cardLogic
	--print('Ready To Use ',which ,key_link)
	TableFunc.Push(cardLogic.pending  ,key_link)
	--print(#cardLogic.pending )
end

local function ClearDeath(battle)
	battle.ClearDeath(battle)
end
local function UpdateState(battle,which)
	for i=1,4 do
		local mon = battle.characterData.monsterData[i]
		local hero = battle.characterData.heroData[i]

		if mon then
			local stateTable = mon.state[which]
			for k,state in pairs(stateTable) do
				StateHandler.Update(battle , mon , state ,stateTable)
			end
		end
		
		if hero then
			local stateTable = hero.state[which]
			for k,state in pairs(stateTable) do
				StateHandler.Update(battle , hero , state ,stateTable)
			end
		end
	end

	return {toViewScene={key='UpdateState',arg={which}}}
end
local function InitPlayerRounde(battle)
	--print("InitPlayerRounde")
	battle.battleData.actPoint =0
	for k,hero in pairs(battle.characterData.heroData) do
		battle.battleData.actPoint = battle.battleData.actPoint+hero.data.act
	end
	--battle.choose.tempActPoint = battle.battleData.actPoint
	battle:DealProcess()
	--table.insert(machine.toViewScene,1,{alreadySent=false,command={key='TransitionTo' ,arg={'PlayerAct'}, viewState='State_RoundStart'}})
	return {toViewScene={key='TransitionTo' ,arg={'PlayerAct'},} }
end
local function Final_Value( target )
	for k,quest in pairs(target.value_request) do
		for i,v in pairs(target.state.condition) do
			print(k,v)
		end
	end
end
local function AfterUseCard(key_link, battle ,data)
	local monsterData = battle.characterData.monsterData
	local heroData    = battle.characterData.heroData

	for i=#monsterData,1 ,-1 do
		local m =monsterData[i]
		m.data.shield = math.max(m.data.shield , 0)
		if m.data.hp <=0 then
			--print('is dead')
			m.data.hp=0
			TableFunc.Push(battle.characterData.grave ,m)
			table.remove(monsterData,i)
		else
			m.AI:Think( battle, mon)
		end
	end
	for i=#heroData,1 ,-1 do
		local h =heroData[i]
		h.data.shield = math.max(h.data.shield , 0)
		if h.data.hp <=0 then
			h.data.hp=0
			TableFunc.Push(battle.characterData.grave ,h)
			table.remove(heroData,i)
		else
			if h.AI then h.AI:Think( battle, h) end
		end
	end

	local result=battle:CheckAlive()
	if result then
		battle.machine:TransitionTo(result)
	end
	--print('AfterUseCard')
	return {toViewScene={key='ViewUseCard' ,arg={battle, key_link.card ,data} }}
end
local function save(battle,result)
	local sceneList=SaveFileMgr.CurrentSave.MapData.sceneList
	local p = TableFunc.Find(sceneList  ,battle.scene.name  ,'name')
	sceneList[p].events.battle_state=result
	sceneList[p].events.endingItem=battle.endingItem
	return true		
end	
function BattleMachine.new(battle )
	local PreState = State.new("PreState")
	local Empty = State.new("Empty")
	local RoundStart = State.new("RoundStart")
	local State_RoundStart = State.new("State_RoundStart")
	local PlayerAct = State.new("PlayerAct")
	local MonsterAct = State.new("MonsterAct")
	local State_RoundEnd = State.new("State_RoundEnd")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local machine = Machine.new({
		initial=PreState,
		states={
			PreState,Empty ,RoundStart  ,State_RoundStart ,MonsterAct,PlayerAct,State_RoundEnd,RoundEnd,WaitEnding,Victory,Lose
		},
		events={
			--[[  WaitEnding(global)

			      						/-->PlayerAct --\							
			RoundStart--> State_RoundStart--                 -->State_RoundEnd--> RoundEnd 
										\-->MonsterAct--/       					 				]]

			{state=PreState,to='Empty'},							
			{state=Empty,to='RoundStart'},
			{state=RoundStart,to='State_RoundStart'},

			{state=State_RoundStart,to='PlayerAct' },	

			{state=PlayerAct,to='MonsterAct' },
			{state=MonsterAct,to='State_RoundEnd'},

			{state=State_RoundEnd,to="RoundEnd"},
			{state=RoundEnd,to='RoundStart' },

			{state=Victory,global=true},
			{state=Lose,global=true}

		}
	})
	machine.toViewScene={}
	machine.choose=Choose.new()
	machine.card_queue={}
	machine.pending={}	
	machine.funcTab={
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
	machine.record={}
	PreState.Do=function(...)
		machine:TransitionTo('Empty')
		--TableFunc.Dump(battle.characterData)

	end
	Empty.Do=function(...)
		--print('Empty Data Up')
		if scene.events.battle_state then
			battle.characterData.monsterData={}
			battle.endingItem	= scene.events.endingItem

			machine:TransitionTo('WaitEnding')
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'WaitEnding'}, viewState='Empty'}) 
		else 
			machine:TransitionTo('RoundStart')
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'RoundStart'}, viewState='Empty'}) 
		end
	end
	RoundStart.DoOnEnter=function(...)
		print('RoundStart Data')		
		--table.insert(machine.pending,{key='ClearDeath',arg={battle},actName='ClearDeath'})

		local t={key='AddShield',arg={ {target={},value={}} }}
		for i=1,4 do
			local mon = battle.characterData.monsterData[i]
			local hero = battle.characterData.heroData[i]
			local originData ,key
			
			if mon then
				if  mon.data.def > 0 then 
					local serial = 'monster '..TableFunc.GetSerial(mon)	
					--print('mon',mon)
					StateHandler.AddBuff(battle,{mon},'shield')
					TableFunc.Push(t.arg[1].target , mon.key) 
					TableFunc.Push(t.arg[1].value ,  mon.data.shield) 
				end 
				mon.AI:Think( battle, mon)
			end
			if hero then
				if  hero.data.def > 0 then
					local serial = 'monster '..TableFunc.GetSerial(hero)	 
					--print('hero')
					--TableFunc.Dump(hero)
					StateHandler.AddBuff(battle,{hero},'shield')
					TableFunc.Push(t.arg[1].target , hero.key) 
					TableFunc.Push(t.arg[1].value ,  hero.data.shield) 
				end 
			end
		end
		table.insert(machine.toViewScene,t)

	end
	RoundStart.Do=function(...)
		--print('RoundStart Data')
		machine:TransitionTo('State_RoundStart')
		table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'State_RoundStart'}}) 		
	end
	State_RoundStart.DoOnEnter=function(...)   
		print('State_RoundStart Data')
		--{name=funcName,arg={...}
		table.insert(machine.pending,{key='UpdateState',arg={battle,'round_start'},actName='UpdateState'})
	end
	State_RoundStart.Do=function(...)
		--print('State_RoundStart Data Up')
		--local nextState = battle.battleData.round % 2 == 0 and 'MonsterAct' or 'PlayerAct'
		machine:TransitionTo('PlayerAct')
	end

	PlayerAct.DoOnEnter=function(...)
		print('PlayerAct Data')
		table.insert(machine.pending,{key='InitPlayerRounde',arg={battle},actName='InitPlayerRounde'})

	end
	MonsterAct.DoOnEnter=function(self,battle,...)
		
		for k,mon in pairs(battle.characterData.monsterData) do
			mon.AI.machine:TransitionTo('Act',battle,mon)
			local result = mon.AI.machine:Update(battle)
			if result then
				scene.InsertResult(machine ,result)
			end
		end
		local card_logic=machine.monster_cardLogic
		--print('MonsterAct Data', #machine.pending)
		--local mon=battle.characterData.monsterData[1]

		
	end
	MonsterAct.Do=function(self,battle,scene,...)
		local card_logic=machine.monster_cardLogic
		--print('M Act ',#card_logic.card_pending,#card_logic.state_pending,#card_logic.queue)
		if #card_logic.pending <=0 and #card_logic.card_pending <=0 and #card_logic.queue<=0 and #machine.pending <=0 then
			--print('trans to state_end')
			machine:TransitionTo('State_RoundEnd',battle)
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'State_RoundEnd'}}) 		
		end
			--print(#machine.monster_cardLogic.pending , #machine.monster_cardLogic.card_pending ,#machine.monster_cardLogic.state_pending)
			
		--print('MonsterAct Data Update')
	end


	State_RoundEnd.Do=function(...)
		table.insert(machine.pending,{key='UpdateState',arg={battle,'round_end'},actName='UpdateState'})
		table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'RoundEnd'}}) 	
		machine:TransitionTo('RoundEnd')

	end

	RoundEnd.DoOnEnter=function(...)
		
		local result=battle:CheckAlive()
		if not result then
			battle.battleData.round = battle.battleData.round+1
			machine:TransitionTo('RoundStart')
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'RoundStart'}}) 	
		else
		end
	end

	Victory.DoOnEnter=function(self,battle)
		print('Win')
		function save()
			local sceneList=SaveFileMgr.CurrentSave.MapData.sceneList
			local p = TableFunc.Find(sceneList  ,battle.scene.name  ,'name')
			sceneList[p].events.battle_state='Victory'
			sceneList[p].events.endingItem=battle.endingItem
			return true		
		end
		SaveFileMgr.Save(SaveFileMgr.CurrentSave,save)
		--battle.keyCtrl:TransitionTo('keyVic')
	end
	Lose.DoOnEnter=function(self,battle)
		function save()
			local sceneList=SaveFileMgr.CurrentSave.MapData.sceneList
			local p = TableFunc.Find(sceneList  ,battle.scene.name  ,'name')
			sceneList[p].events.battle_state='Lose'
			sceneList[p].events.endingItem=battle.endingItem
			return true		
		end
		SaveFileMgr.Save(SaveFileMgr.CurrentSave,save)
		--battle.keyCtrl:TransitionTo('keyLose')
	end

	machine.Update=function(self,battle,scene,...)
		--print('BattleMachine Update')
		self.current:Do(battle,scene,...)
		--print('current',self.current.name)
		local hero_logic_result = machine.hero_cardLogic:Update(battle,...)	
		if hero_logic_result then
			scene.InsertResult(machine ,hero_logic_result)
		end

		local monster_logic_result = machine.monster_cardLogic:Update(battle,'m cardLogic update',...)
		if monster_logic_result then
			scene.InsertResult(machine ,monster_logic_result)
		end

		local choose_result=machine.choose:Update(battle,...)
		if choose_result then
			scene.InsertResult(machine ,choose_result)
		end

	end

	return machine
end
return BattleMachine