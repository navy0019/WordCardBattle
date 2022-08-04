local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local Card = require('lib.card')
local Choose = require('lib.choose')
local Msg= require('resource.Msg')
local TableFunc = require("lib.TableFunc")
local StatusHandle = require('battle.status')
local cardLogic = require('battle.cardLogic')

local BattleMachine={}
--[[
	machine.choose :卡牌&目標放入此內 做初次判定(行動點數是否足夠 目標是否正確)後放入cardEffect
	machine.cardLogic :卡片效果各種組合 每個update會確認裡面的東西有沒有需要額外組合 組合完成(或沒有組合單純執行)會return 給pending
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
	--print('data addSomthing',key,num)
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
	return {toViewScene={key='TransitionTo' ,arg={'PlayerAct'}, viewState='ExtraInput'} }
end
local function CheckInput(battle, ...)
	local choose = battle.machine.choose
	choose:TransitionTo('CheckInput',...)
end
local function ReadyToUse(choose, battle)
	--print('Ready To Use')
	local choose = battle.machine.choose
	local cardLogic = battle.machine.cardLogic
	table.insert(cardLogic.pending  ,choose.toUse)
end
local function ReDraw( battle,choose )
	return {toViewScene={key='TransitionTo' ,arg={'PlayerAct'}, viewState='PlayerAct'} }
end
--[[local function InsertResult(machine , result)
	if type(result)~='boolean' and result.toViewScene then
		TableFunc.Unshift(machine.toViewScene , result.toViewScene)
	end
	if type(result)~='boolean' and result.toPending then
		TableFunc.Push(machine.pending , result.toPending)
	end

	--table.insert(machine.record , 'pending '..command.actName)
	TableFunc.Shift(machine.pending)
end]]
local function ClearDeath(battle)
	battle.ClearDeath(battle)
end
local function UpdateState(battle)
	for i=1,4 do
		local mon = battle.characterData.monsterData[i]
		local hero = battle.characterData.heroData[i]
		if mon then
			StatusHandle.Update(mon , mon.data.state.before ,battle)
			--print('mon ',mon.data.state)				 
			if  mon.data.def > 0 then 
				StatusHandle.Add(mon,'shield',mon.originData.def)
			end 
		end
		if hero then
			--print('hero ',hero.data.state)
			StatusHandle.Update(hero , hero.data.state.before ,battle)
			if  hero.data.def > 0 then 
				StatusHandle.Add(hero,'shield',hero.originData.def)
			end 
		end
	end
	--print('!!update Team!!')
	return {toViewScene={key='UpdateState',arg={}, viewState='Statusbefore'}}
end
function InitPlayerRounde(battle)
	--print("InitPlayerRounde")
	battle.battleData.actPoint =0
	for k,hero in pairs(battle.characterData.heroData) do
		battle.battleData.actPoint = battle.battleData.actPoint+hero.data.act
	end
	--battle.choose.tempActPoint = battle.battleData.actPoint
	battle:DealProcess()
	--table.insert(machine.toViewScene,1,{alreadySent=false,command={key='TransitionTo' ,arg={'PlayerAct'}, viewState='Statusbefore'}})
	return {toViewScene={key='TransitionTo' ,arg={'PlayerAct'}, viewState='Statusbefore'} }
end	
function BattleMachine.new(battle , scene)
	local PreState = State.new("PreState")
	local Empty = State.new("Empty")
	local StartRound = State.new("StartRound")
	local Statusbefore = State.new("Statusbefore")
	local PlayerAct = State.new("PlayerAct")
	local MonsterAct = State.new("MonsterAct")
	local Statusafter = State.new("Statusafter")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local machine = Machine.new({
		initial=PreState,
		states={
			PreState,Empty ,StartRound  ,Statusbefore ,MonsterAct,PlayerAct,Statusafter,RoundEnd,WaitEnding,Victory,Lose
		},
		events={
			--[[  WaitEnding(global)

			      						/-->PlayerAct --\							
			StartRound--> Statusbefore--                 -->Statusafter--> RoundEnd 
										\-->MonsterAct--/       					 				]]

			{state=PreState,to='Empty'},							
			{state=Empty,to='StartRound'},
			--{state=Empty,to='WaitEnding'},
			{state=StartRound,to='Statusbefore'},

			{state=Statusbefore,to='PlayerAct' },	
			{state=Statusbefore,to='MonsterAct'},

			{state=PlayerAct,to='Statusafter' },
			{state=MonsterAct,to='Statusafter'},

			{state=Statusafter,to="RoundEnd"},
			{state=RoundEnd,to='StartRound' },

			--[[{state=Statusbefore,to='WaitEnding' },
			{state=Statusafter,to='WaitEnding'},
			{state=PlayerAct,to='WaitEnding' },
			{state=MonsterAct,to='WaitEnding' },

			{state=WaitEnding,to='Victory' },
			{state=WaitEnding,to='Lose' }]]
		}
	})
	machine.toViewScene={}
	machine.choose=Choose.new()
	machine.cardLogic=cardLogic.new()-- print('machine logic',machine.cardLogic)
	machine.pending={}	
	machine.funcTab={
		AddSomthing=AddSomthing,
		CheckInput=CheckInput,
		CancelInput=CancelInput,
		ReadyToUse=ReadyToUse,
		ReDraw = ReDraw,
		ClearDeath=ClearDeath,
		UpdateState=UpdateState,
		InitPlayerRounde=InitPlayerRounde,
		LoopAdd=LoopAdd,

	}
	machine.record={}--debug用 記錄所有步驟
	machine.preLength=0

	PreState.Do=function(...)
		machine:TransitionTo('Empty')
	end
	Empty.Do=function(...)
		--print('Empty Data Up')
		if scene.events.BattleIsEnd then
			battle.characterData.monsterData={}
			battle.endingItem	= scene.events.endingItem

			machine:TransitionTo('WaitEnding')
			--viewState: 要將這指令發給battleViewScenes的哪個狀態
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'WaitEnding'}, viewState='Empty'}) 
		else 
			machine:TransitionTo('StartRound')
			--print('data insert ')
			table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'StartRound'}, viewState='Empty'}) 
		end
	end
	StartRound.DoOnEnter=function(...)
		--print('StartRound Data')		
		table.insert(machine.pending,{key='ClearDeath',arg={battle},actName='updateTeam'})
	end
	StartRound.Do=function(...)
		--print('StartRound Data Up')
		machine:TransitionTo('Statusbefore')
		table.insert(machine.toViewScene,1,{key='TransitionTo' ,arg={'Statusbefore'}, viewState='StartRound'}) 		
	end
	Statusbefore.DoOnEnter=function(...)   
		--print('Statusbefore Data')
		--{name=funcName,arg={...}
		table.insert(machine.pending,{key='UpdateState',arg={battle},actName='UpdateState'})
	end
	Statusbefore.Do=function(...)
		--print('Statusbefore Data Up')
		local nextState = battle.battleData.round % 2 == 0 and 'MonsterAct' or 'PlayerAct'
		machine:TransitionTo(nextState)
	end

	PlayerAct.DoOnEnter=function(...)
		--print('PlayerAct Data')
	
		table.insert(machine.pending,{key='InitPlayerRounde',arg={battle},actName='InitPlayerRounde'})


	end
	MonsterAct.DoOnEnter=function(self,battle)
		--[[local Empty = State.new("Empty")
		Empty.waitTime=0.5
		local Act = State.new("Act")
		Act.index=1

		local mAct=Machine.new({
			initial=Empty,
			states={Empty ,Act  },
			events={
				{state=Empty,to='Act'},
				{state=Act,to='Empty'},	
			}			
		})
		Empty.Do=function(self,dt,battle)
			self.currentTime = self.currentTime+dt
			if self.currentTime >= self.waitTime then
				self.currentTime=0
				if Act.index <= #battle.characterData.monsterData then					
					mAct:TransitionTo('Act',dt,battle)
				end
			end
		end

		Act.Do=function(self,dt,battle)
			local m = battle.characterData.monsterData[Act.index]
			if m.state.current.name ~= "Death" then
				m.state:Update( m ,battle)
				Empty.waitTime=0.7
				mAct:TransitionTo('Empty',dt,battle)
			else
				Empty.waitTime=0				
			end
			MonsterAct.waitTime=MonsterAct.waitTime+Empty.waitTime
			Act.index=Act.index+1
		end
		self.Act=mAct]]
	end
	MonsterAct.Do=function(self,battle)
		self.currentTime = self.currentTime+dt
		self.Act:Update(dt,battle)
		if self.Act.states.Act.index > #battle.characterData.monsterData and self.currentTime >= self.waitTime then
			self.currentTime=0
			--battleMachine.UIMachine:TransitionTo('Statusafter',dt,battle)
			machine:TransitionTo('Statusafter',dt,battle)
		end
	end
	MonsterAct.DoOnLeave=function(self,battle)
		self.Act.states.Act.index=1
		self.Act.states.Empty.waitTime=0.5
		self.waitTime=0
	end
	Statusafter.DoOnEnter=function(self,battle)
		local time
		if battle.battleData.round % 2 == 0 then
			--machine.statusMachine:addUpdate(battle,'monsterData' ,'after',battle)
			local buffNum = Battle.CountBuff(battle.characterData.monsterData ,'after')
			if buffNum >0 then
				time=0.2*buffNum+Battle.CountAlive(battle.characterData.monsterData)*0.2
			else
				time=0
			end
			
		else
			battleMachine.statusMachine:addUpdate(battle,'heroData' ,'after',battle)
			local buffNum = Battle.CountBuff(battle.characterData.heroData ,'after')
			if buffNum >0 then
				time=0.2*Battle.CountBuff(battle.characterData.heroData ,'after')+Battle.CountAlive(battle.characterData.heroData)*0.2
			else
				time=0
			end
			time=math.max(time ,0.4 ) 
		end

		self.waitTime=time
	end

	RoundEnd.DoOnEnter=function(self,battle)
		self.waitTime =0
		battle.battleData.round = battle.battleData.round+1

	end
	RoundEnd.Do=function(self,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			--battleMachine.UIMachine:TransitionTo('StartRound',dt,battle)
			machine:TransitionTo('StartRound',dt,battle)
		end
	end
	WaitEnding.DoOnEnter=function(self)
		self.nextState=scene.events.BattleState 
		if nextState=='Victory'  then
			for k,v in pairs(battle.battleData.hand) do
				v:Lock()
			end
			function itemMerge (tab)
				local newTab = {}
				for k,v in pairs(tab) do
					local  p = TableFunc.find(newTab,v.key,'key')
					if p then
						newTab[p].value = newTab[p].value+v.value
					elseif v.key ~='empty' then
						table.insert(newTab,v)
					end
				end
				return newTab
			end
			battle.endingItem = itemMerge(battle.endingItem)
		end

		for k,char in pairs(battle.characterData.heroData) do
			char:ClearStatus(battle)
		end
		--local itemNum = #items
	end
	WaitEnding.Do=function(self,battle)
		self.currentTime = self.currentTime+dt
		if self.currentTime >= self.waitTime then
			self.currentTime=0
			machine:TransitionTo(self.nextState,dt,battle)
		end
	end
	Victory.DoOnEnter=function(self,battle)
		function save()
			local sceneList=SaveFileMgr.CurrentSave.MapData.sceneList
			local p = TableFunc.find(sceneList  ,battle.scene.name  ,'name')
			sceneList[p].events.BattleIsEnd='Victory'
			sceneList[p].events.endingItem=battle.endingItem
			return true		
		end
		SaveFileMgr.Save(SaveFileMgr.CurrentSave,save)
		battle.keyCtrl:TransitionTo('keyVic')
	end
	Lose.DoOnEnter=function(self,battle)
		battle.keyCtrl:TransitionTo('keyLose')
	end

	machine.Update=function(self,battle,...)
		self.current:Do(...)

		if #machine.cardLogic.pending > 0 then
			print('cardLogic update')
			local logic_retsult = machine.cardLogic:Update(battle)
		end

		local choose_result=machine.choose:Update(battle,...)
		if choose_result then
			--print('choose update',choose_result)
			--print('o ',choose_result.toViewScene.command.key)
			battle.scene.InsertResult(machine ,choose_result)
		end

	end

	return machine
end
return BattleMachine