local LogicScenesMgr = require('LogicScenesMgr')

local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local BattlePrint = require('battle.battlePrint')

local BattleViewScenes={}
local drawCommand = {
	TransitionTo=function(scene, nextState ,...)
		local viewState =...
		--print('viewState,nextState ',viewState,nextState)
		local machine = scene.BattleMachineView
		--print('machine view current ',machine.current.name)
		--assert(machine.current.name == viewState ,'can\'t transition to '..nextState..' , current ~= '..viewState)
		if type(viewState)~='boolean' and machine.current.name == viewState then
			machine:TransitionTo(nextState)
			return true
		else
			machine:TransitionTo(nextState)
			return true
		end
		return false
	end,
	--ErrorMsg=function(scene,machine,viewState,...) print(...) scene.Event:Emit('WaitIoRead') return true end,
	UpdateState=function(scene,...)
		print('view 更新狀態')
		return true
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
		return true
	end,
	ExtraInput=function(scene,...)
		local machine = scene.BattleMachineView
		assert(machine.current.name=='PlayerAct' ,'not PlayerAct '..machine.current.name)
		machine:TransitionTo('ExtraInput')
		local str = ...
		print(str[2])
		return true
	end,
	UseCard=function(scene,...)
		local machine = scene.BattleMachineView
		machine:TransitionTo('PlayerAct')
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
	machine.drawCommand=drawCommand
	Empty.Do=function(...)
		--print('ViewScenes empty',LogicScenesMgr.CurrentScene.battle.machine.current.name)
		--machine:TransitionTo('StartRound')
	end
	StartRound.DoOnEnter=function(...)
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
			--print('cardkey',v.key)
			scene.ButtonEvent:Register('c'..k,function(...)end)--print('ViewScenes press c'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton', 'c'..k, 'c'..k ,'AddSomthing','card')
			--scene.Event:Emit('AddButton','c'..k, 'c'..k ,'CheckChoose')
		end

		for k,v in pairs(battle.characterData.heroData) do
			scene.ButtonEvent:Register('h'..k,function(...)end)-- print('ViewScenes press h'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton','h'..k, 'h'..k ,'AddSomthing','select')
			--scene.Event:Emit('AddButton','h'..k, 'h'..k ,'CheckChoose')
		end
		for k,v in pairs(battle.characterData.monsterData) do
			scene.ButtonEvent:Register('m'..k ,function(...)end)--print('ViewScenes press m'..k) scene.Event:Emit('WaitIoRead')
			scene.Event:Emit('AddButton','m'..k , 'm'..k ,'AddSomthing','select')
			--scene.Event:Emit('AddButton',v.key..'_'..k, 'm'..k ,'CheckChoose')
		end

		scene.ButtonEvent:Register('CancelChooseButton',function(...) end)
		scene.Event:Emit('AddButton','CancelChooseButton', 2 ,'CancelInput')
		--[[scene.ButtonEvent:Register('endRoundButton',function(...) end)
		scene.Event:Emit('AddButton','endRoundButton', 2 ,'endRound')]]
		--[[for k,v in pairs(scene.ButtonEvent) do
			print(k,#v)
		end]]
		BattlePrint.PrintCharacter(battle)
		BattlePrint.PrintCard(battle)
		--print('ViewScenes: 玩家回合')		
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