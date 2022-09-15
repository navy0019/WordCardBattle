local LogicScenesMgr = require('LogicScenesMgr')
local StringDecode=require('lib.StringDecode')
local TableFunc = require("lib.TableFunc")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local BattlePrint = require('battle.battlePrint')

local BattleViewScenes={}
local function GetTableSerial(t)
	local key = tostring(t)
	local p =key:find(':')
	key=StringDecode.trim_head_tail( key:sub(p+1,#key) )
	return key
end
local function CopyTable(t)
	local key = GetTableSerial(t)
	local tab =TableFunc.Copy(t)
	tab.key=key
	return tab
end
local function UpdateCopyTable(copy , data ,index)
	local p=index or nil
	if p then
		copy[p]=CopyTable(data)
	else
		local key = GetTableSerial(data)
		p =TableFunc.Find(copy ,key ,'key')
		copy[p]=CopyTable(data)
	end
end
local function CompareOriginData(machine, battle)
	--只比較素質 不比較state
	local copy_heroData = machine.copy_data.heroData
	local copy_monsterData = machine.copy_data.monsterData
	local t={}
	for k,hero in pairs(battle.characterData.heroData) do		
		local key = GetTableSerial(hero)
		local p =TableFunc.Find(copy_heroData ,key ,'key')
		if p then
			local originData = copy_heroData[p]
			local hit = (originData.data.shield - hero.data.shield) + (originData.data.hp - hero.data.hp) 
			if hit > 0 then
				UpdateCopyTable(copy_heroData , hero ,p)
				TableFunc.Push(t ,{name=hero.key,hit=hit})
			end
		end
	end
	for k,mon in pairs(battle.characterData.monsterData) do		
		local key = GetTableSerial(mon)
		local p =TableFunc.Find(copy_monsterData ,key ,'key')
		if p then
			local originData = copy_monsterData[p]
			local hit = (originData.data.shield - mon.data.shield) + (originData.data.hp - mon.data.hp) 
			if hit > 0 then
				UpdateCopyTable(copy_monsterData , mon ,p)
				TableFunc.Push(t ,{name=mon.key,hit=hit})
			end
		end
	end
	--print('grave',battle.characterData.grave)
	for k,v in pairs(battle.characterData.grave) do
		local key = GetTableSerial(v)
		local copy_data = v.race=='hero' and copy_heroData or copy_monsterData
		local p = TableFunc.Find(copy_data ,key ,'key')
		if p then
			local originData = copy_data[p]
			local hit = (originData.data.shield - v.data.shield) + (originData.data.hp - v.data.hp) 
			if hit > 0 then
				UpdateCopyTable(copy_data , v ,p)
				TableFunc.Push(t ,{name=v.key,hit=hit})
			end
		end
	end
	return t
end

local drawCommand = {
	TransitionTo=function(scene, nextState ,...)
		local viewState =...
		local machine = scene.BattleMachineView
		if type(viewState)~='boolean' and machine.current.name == viewState then
			machine:TransitionTo(nextState)
			--return true
		else
			machine:TransitionTo(nextState)
			--return true
		end
		--return false
	end,
	UpdateState=function(scene,battle,...)
		--print('view 更新狀態')
		local machine = scene.BattleMachineView
		local copy_heroData = machine.copy_data.heroData
		local copy_monsterData = machine.copy_data.monsterData

		for k,hero in pairs(battle.characterData.heroData) do		
			local key = GetTableSerial(hero)
			local p =TableFunc.Find(copy_heroData ,key ,'key')
			if p then
				UpdateCopyTable(copy_heroData , hero ,p)
			end
		end
		for k,mon in pairs(battle.characterData.monsterData) do		
			local key = GetTableSerial(mon)
			local p =TableFunc.Find(copy_monsterData ,key ,'key')
			if p then
				UpdateCopyTable(copy_monsterData , mon ,p)
			end
		end
	end,
	WaitIoRead=function(scene,...)
		local str = ...
		if str then
			local s=''
			if type(str)=='table' then
				for i=2,#str,2 do
				 	s=s..str[i]
				end
			else
				s=str 
			end
			print('waitIO msg ',s)
		end
		scene.Event:Emit('WaitIoRead')

	end,
	ExtraInput=function(scene,...)
		local machine = scene.BattleMachineView
		assert(machine.current.name=='PlayerAct' ,'not PlayerAct '..machine.current.name)
		machine:TransitionTo('ExtraInput')
		local str = ...
		print(str[2])

	end,
	ViewUseCard=function(scene,toUse,battle,...)
		--print('UseCard!!')
		local machine = scene.BattleMachineView
		machine:TransitionTo('PlayerAct')
		CompareOriginData(machine ,battle)
		--TableFunc.Dump(machine.copy_data)
	end
}
function BattleViewScenes.new(battle , scene)
	local Empty = State.new("Empty")
	local StartRound = State.new("StartRound")
	local Statusbefore = State.new("Statusbefore")
	local PlayerAct = State.new("PlayerAct")
	local ExtraInput = State.new("ExtraInput")

	local MonsterAct = State.new("MonsterAct")
	local Statusafter = State.new("Statusafter")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local machine = Machine.new({
		initial=Empty,
		states={
			Empty ,StartRound  ,Statusbefore ,MonsterAct,PlayerAct,ExtraInput,Statusafter,RoundEnd,WaitEnding,Victory,Lose
		},
		events={
			--[[  WaitEnding(global)
											ExtraInput
												|
			      						/-->PlayerAct --\							
			StartRound--> Statusbefore--                 -->Statusafter--> RoundEnd 
										\-->MonsterAct--/       					 				]]

			{state=Empty,to='StartRound'},
			{state=Empty,to='WaitEnding'},
			{state=StartRound,to='Statusbefore'},

			{state=Statusbefore,to='PlayerAct' },	
			{state=Statusbefore,to='MonsterAct'},

			{state=PlayerAct,to='PlayerAct' },
			{state=PlayerAct,to='MonsterAct' },
			{state=PlayerAct,to='Statusafter' },
			{state=PlayerAct,to='ExtraInput' },
			{state=ExtraInput,to='PlayerAct' },

			{state=MonsterAct,to='Statusafter'},

			{state=Statusafter,to="RoundEnd"},
			{state=RoundEnd,to='StartRound' },

			{state=Statusbefore,to='WaitEnding' },
			{state=Statusafter,to='WaitEnding'},
			{state=PlayerAct,to='WaitEnding' },
			{state=MonsterAct,to='WaitEnding' },

			{state=WaitEnding,to='Victory' },
			{state=WaitEnding,to='Lose' }
		}
	})
	machine.pending={}
	machine.record={}
	machine.copy_data={heroData={},monsterData={}}
	machine.dialogue={}
	machine.drawCommand=drawCommand
	Empty.Do=function(...)
		--copy 英雄 怪物的data
		local heroData =battle.characterData.heroData
		local monsterData  =battle.characterData.monsterData
		for k,v in pairs(heroData) do
			local t = CopyTable(v)
			TableFunc.Push(machine.copy_data.heroData ,t)
			--print(v)
		end
		for k,v in pairs(monsterData) do
			local t = CopyTable(v)
			TableFunc.Push(machine.copy_data.monsterData ,t)
			--print(v)
		end
		--TableFunc.Dump(machine.copy_data)
	end
	StartRound.DoOnEnter=function(...)

		--machine.copy_data.heroData=TableFunc.Copy(heroData)
		--machine.copy_data.monsterData=TableFunc.Copy(monsterData)

		--print('回合開始')
		--machine:TransitionTo('Statusbefore')
	end
	Statusbefore.DoOnEnter=function(...)	
		--machine:TransitionTo('PlayerAct')
		--print('ViewScenes Statusbefore')
	end
	PlayerAct.DoOnEnter=function(...)
		local hand = battle.battleData.hand
		for k,v in pairs(hand) do
			scene.ButtonEvent:Register('c'..k,function(...)end)--print('ViewScenes press c'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton', 'c'..k, 'c'..k ,'AddSomthing','card')
		end

		for k,v in pairs(battle.characterData.heroData) do
			scene.ButtonEvent:Register('h'..k,function(...)end)-- print('ViewScenes press h'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton','h'..k, 'h'..k ,'AddSomthing','target')
		end
		for k,v in pairs(battle.characterData.monsterData) do
			scene.ButtonEvent:Register('m'..k ,function(...)end)--print('ViewScenes press m'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton','m'..k , 'm'..k ,'AddSomthing','target')
		end

		scene.ButtonEvent:Register('CancelChooseButton',function(...) end)
		scene.Event:Emit('AddButton','CancelChooseButton', 2 ,'CancelInput')

		BattlePrint.PrintCharacter(battle)
		BattlePrint.PrintCard(battle)
		print('ViewScenes: PlayerACT 玩家回合')		
		scene.Event:Emit('WaitIoRead')
	end
	PlayerAct.DoOnLeave=function(...)
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			table.insert(remove,k)
		end
		for k,v in pairs(remove) do
			scene.Event:Emit('RemoveButton',v)			
		end
	end
	ExtraInput.DoOnEnter=function(...)
		print('1:確認選取  2:取消  ')
		local choose = LogicScenesMgr.CurrentScene.battle.machine.choose
		local hand = battle.battleData.hand
		for k,v in pairs(hand) do
			if v ~= choose.card then
				scene.ButtonEvent:Register('c'..k ,function(...) end)--print('ViewScenes press c'..k) scene.Event:Emit('WaitIoRead')
				scene.Event:Emit('AddButton', 'c'..k , 'c'..k ,'LoopAdd')
			end
		end
		scene.ButtonEvent:Register('CheckChooseButton',function(...) end)
		scene.Event:Emit('AddButton','CheckChooseButton', 1 ,'CheckInput','enforce',battle)

		scene.ButtonEvent:Register('CancelChooseButton',function(...) end)
		scene.Event:Emit('AddButton','CancelChooseButton', 2 ,'CancelInput')
	end
	ExtraInput.DoOnLeave=function(...)
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			table.insert(remove,k)
		end
		for k,v in pairs(remove) do
			scene.Event:Emit('RemoveButton',v)			
		end
	end
	machine.Update=function(self,...)

		self.current:Do(...)
		--print('view ',self.current.name)
	end
	return machine
end
return BattleViewScenes