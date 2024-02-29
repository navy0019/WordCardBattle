local LogicScenesMgr = require('LogicScenesMgr')
local StringDecode=require('lib.StringDecode')
local TableFunc = require("lib.TableFunc")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local BattlePrint = require('view.battlePrint')

local BattleViewScenes={}

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
	UpdateState=function(scene,state_name,...)
		print(state_name..' 更新狀態')
	end,
	AddBuff=function(scene,state_name,...)
		print(' 增加狀態: ',state_name)
	end,
	AddShield=function(scene,tabl)
		for k,v in pairs(tabl.target) do
			print(v..' 增加護盾:'..tabl.value[k])
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
	ViewUseCard=function(scene,battle,card,t,...)

		--print('UseCard!!',#t)
		for k,v in pairs(t) do		
			local type , serial = StringDecode.Split_by(card.holder,'%s')
			local tab = type =='hero' and battle.characterData.heroData or battle.characterData.monsterData
			local index = TableFunc.MatchSerial(tab ,serial)
			local holder = tab[index]
			print(holder.key..'使出 '..card.name..' , '..v.name..'受到 '..v.hit..' 傷害')
		end

		local machine = scene.BattleMachineView
		if battle.machine.current.name == 'PlayerAct' then
			machine:TransitionTo('PlayerAct')
		end
		--TableFunc.Dump(machine.copy_data)
	end
}
function BattleViewScenes.new(battle , scene)
	local Empty = State.new("Empty")
	local RoundStart = State.new("RoundStart")
	local State_RoundStart = State.new("State_RoundStart")
	local PlayerAct = State.new("PlayerAct")
	local ExtraInput = State.new("ExtraInput")

	local MonsterAct = State.new("MonsterAct")
	local State_RoundEnd = State.new("State_RoundEnd")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local machine = Machine.new({
		initial=Empty,
		states={
			Empty ,RoundStart  ,State_RoundStart ,MonsterAct,PlayerAct,ExtraInput,State_RoundEnd,RoundEnd,WaitEnding,Victory,Lose
		},
		events={
			--[[  WaitEnding(global)
											ExtraInput
												|
			      						/-->PlayerAct --\							
			RoundStart--> State_RoundStart--                 -->State_RoundEnd--> RoundEnd 
										\-->MonsterAct--/       					 				]]

			{state=Empty,to='RoundStart'},
			{state=Empty,to='WaitEnding'},
			{state=RoundStart,to='State_RoundStart'},

			{state=State_RoundStart,to='PlayerAct' },	
			{state=State_RoundStart,to='MonsterAct'},

			{state=PlayerAct,to='PlayerAct' },
			{state=PlayerAct,to='MonsterAct' },
			{state=PlayerAct,to='ExtraInput' },

			{state=ExtraInput,to='PlayerAct' },

			--{state=MonsterAct,to='MonsterAct'},
			{state=MonsterAct,to='State_RoundEnd'},

			{state=State_RoundEnd,to="RoundEnd"},
			{state=RoundEnd,to='RoundStart' },

			--[[{state=State_RoundStart,to='WaitEnding' },
			{state=State_RoundEnd,to='WaitEnding'},
			{state=PlayerAct,to='WaitEnding' },
			{state=MonsterAct,to='WaitEnding' },

			{state=WaitEnding,to='Victory' },
			{state=WaitEnding,to='Lose' }]]
			{state=WaitEnding,global=true,self=true}
		}
	})
	machine.pending={}
	machine.record={}
	machine.copy_data={heroData={},monsterData={}}
	machine.dialogue={}
	machine.drawCommand=drawCommand

	RoundStart.DoOnEnter=function(...)

		--print('回合開始')
	end
	State_RoundStart.DoOnEnter=function(...)	

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

		scene.ButtonEvent:Register('EndRoundButton',function(...) end)
		scene.Event:Emit('AddButton','EndRoundButton', 3 ,'EndRound')

		BattlePrint.PrintCharacter(battle)
		BattlePrint.PrintCard(battle)
		--print('ViewScenes: PlayerACT 玩家回合')		
		scene.Event:Emit('WaitIoRead')
	end
	PlayerAct.DoOnLeave=function(...)
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			TableFunc.Push(remove,k)
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
			TableFunc.Push(remove,k)
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