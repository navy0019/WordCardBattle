local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local TableFunc = require("lib.TableFunc")

local BattleMachine = {}
function BattleMachine.new()
	--local PreState = State.new("PreState")
	local Empty = State.new("Empty")
	local RoundStart = State.new("RoundStart")
	--local State_RoundStart = State.new("State_RoundStart")
	local PlayerAct = State.new("PlayerAct")
	local MonsterAct = State.new("MonsterAct")
	--local State_RoundEnd = State.new("State_RoundEnd")
	local RoundEnd = State.new("RoundEnd")
	local WaitEnding = State.new("WaitEnding")
	local Victory = State.new("Victory")
	local Lose = State.new("Lose")

	local machine = Machine.new({
		initial = Empty,
		states = {
			Empty, RoundStart, MonsterAct, PlayerAct, RoundEnd, WaitEnding, Victory, Lose
		},
		events = {
			--[[  WaitEnding(global)

			      						/-->PlayerAct --\							
			RoundStart--> State_RoundStart--                 -->State_RoundEnd--> RoundEnd
										\-->MonsterAct--/       					 				]]

			--{state=PreState,to='Empty'},							
			{ state = Empty,      to = 'RoundStart' },
			--{state=RoundStart,to='State_RoundStart'},
			{ state = RoundStart, to = 'PlayerAct' },
			--{state=State_RoundStart,to='PlayerAct' },	


			{ state = PlayerAct,  to = 'MonsterAct' },
			{ state = MonsterAct, to = 'RoundEnd' },
			--{state=MonsterAct,to='State_RoundEnd'},

			--{state=State_RoundEnd,to="RoundEnd"},
			{ state = RoundEnd,   to = 'RoundStart' },

			{ state = Victory,    global = true },
			{ state = Lose,       global = true }

		}
	})

	machine.card_queue = {}
	machine.record = {}

	--[[PreState.Do=function(...)
		print('Pre to Empty')
		machine:TransitionTo('Empty')
		--TableFunc.Dump(battle.characterData)

	end]]
	Empty.Do = function(self, battle, scene, ...)
		--print('BM Empty Data', battle, scene)
		if scene.events.battle_state then
			battle.characterData.monsterData = {}
			battle.endingItem = scene.events.endingItem
			TableFunc.Push(scene.toBattleView, { key = 'TransitionTo', arg = { 'WaitEnding' } })

			machine:TransitionTo('WaitEnding', battle, scene, ...)
		else
			TableFunc.Push(scene.toBattleView, { key = 'TransitionTo', arg = { 'RoundStart' } })
			machine:TransitionTo('RoundStart', battle, scene, ...)
		end
	end
	RoundStart.DoOnEnter = function(self, battle, scene, ...)
		--print('RoundStart Data')
		--table.insert(machine.pending,{key='ClearDeath',arg={battle},actName='ClearDeath'})

		local t = { key = 'AddShield', arg = { { target = {}, value = {} } } }
		for i = 1, 4 do
			local mon = battle.characterData.monsterData[i]
			local hero = battle.characterData.heroData[i]
			local originData, key

			if mon then
				if mon.data.def > 0 then
					local serial = 'monster ' .. TableFunc.GetSerial(mon)
					--print('mon',mon)
					if mon.data.remove_shield then
						mon.data.shield = mon.data.def
					else
						mon.data.shield = mon.data.shield + mon.data.def
					end
					TableFunc.Push(t.arg[1].target, mon.key)
					TableFunc.Push(t.arg[1].value, mon.data.shield)
				end
				mon.AI.machine:TransitionTo('MakeOptions', battle, mon)
				mon.AI:Think(battle, mon)
				--print('monster['..i..'] think:'..mon.AI.machine.decide)
			end
			if hero then
				if hero.data.def > 0 then
					--local serial = 'hero '..TableFunc.GetSerial(hero)	
					--print('hero')
					--TableFunc.Dump(hero)
					--StateHandler.AddBuff(battle,{hero},'shield')
					if hero.data.remove_shield then
						hero.data.shield = hero.data.def
					else
						hero.data.shield = hero.data.shield + hero.data.def
					end
					TableFunc.Push(t.arg[1].target, hero.key)
					TableFunc.Push(t.arg[1].value, hero.data.shield)
				end
			end
		end
		TableFunc.Push(scene.toBattleView, t)

		--print('RoundStart Data toBattleView', scene.toBattleView, #scene.toBattleView)
		--print('RoundStart Data toView', scene.toView, #scene.toView)
	end
	RoundStart.Do = function(self, battle, scene, ...)
		machine:TransitionTo('PlayerAct', battle, scene, ...)
	end
	--[[State_RoundStart.DoOnEnter=function(...)
		print('State_RoundStart Data')
		--{name=funcName,arg={...}
		table.insert(machine.pending,{key='UpdateState',arg={battle,'round_start'},actName='UpdateState'})
	end
	State_RoundStart.Do=function(...)
		--print('State_RoundStart Data Up')
		--local nextState = battle.battleData.round % 2 == 0 and 'MonsterAct' or 'PlayerAct'
		machine:TransitionTo('PlayerAct')
	end]]

	PlayerAct.DoOnEnter = function(self, battle, scene, ...)
		--print('PlayerAct Data')

		battle.battleData.actPoint = 0
		for k, hero in pairs(battle.characterData.heroData) do
			battle.battleData.actPoint = battle.battleData.actPoint + hero.data.act
		end
		battle:DealProcess()
		TableFunc.Push(scene.toBattleView, { key = 'TransitionTo', arg = { 'PlayerAct' } })
		--print('PlayerAct Data DoOnEnter', scene.toBattleView, #scene.toBattleView)
		--TableFunc.Dump(scene.toBattleView)
		print('PlayerAct Data toView', scene.toView, #scene.toView)
		assert(nil)
	end
	MonsterAct.DoOnEnter = function(self, battle, scene, ...)
		for k, mon in pairs(battle.characterData.monsterData) do
			mon.AI.machine:TransitionTo('Act', battle, mon)
			local result = mon.AI.machine:Update(battle)
			if result then
				scene.InsertResult(machine, result)
			end
		end
		local card_queue = machine.card_queue
		--print('MonsterAct Data', #machine.pending)
		--local mon=battle.characterData.monsterData[1]
	end
	MonsterAct.Do = function(self, battle, scene, ...)
		local card_queue = machine.card_queue
		--print('M Act ',#card_logic.card_pending,#card_logic.state_pending,#card_logic.queue)
		if #card_logic.pending <= 0 and #card_logic.card_pending <= 0 and #card_logic.queue <= 0 and #machine.pending <= 0 then
			--print('trans to state_end')
			machine:TransitionTo('RoundEnd', battle)
			table.insert(machine.toSceneBattleView, 1, { key = 'TransitionTo', arg = { 'RoundEnd' } })
		end
		--print(#machine.monster_cardLogic.pending , #machine.monster_cardLogic.card_pending ,#machine.monster_cardLogic.state_pending)

		--print('MonsterAct Data Update')
	end


	--[[State_RoundEnd.Do=function(...)
		table.insert(machine.pending,{key='UpdateState',arg={battle,'round_end'},actName='UpdateState'})
		table.insert(machine.toSceneBattleView,1,{key='TransitionTo' ,arg={'RoundEnd'}}) 	
		machine:TransitionTo('RoundEnd')

	end]]

	RoundEnd.DoOnEnter = function(self, battle, scene, ...)
		local result = battle:CheckAlive()
		if not result then
			battle.battleData.round = battle.battleData.round + 1
			machine:TransitionTo('RoundStart')
			table.insert(machine.toSceneBattleView, 1, { key = 'TransitionTo', arg = { 'RoundStart' } })
		else
		end
	end

	Victory.DoOnEnter = function(self, battle, scene, ...)
		print('Win')
		function save()
			local sceneList = _G.SaveFileMgr.CurrentSave.MapData.sceneList
			local p = TableFunc.Find(sceneList, battle.scene.name, 'name')
			sceneList[p].events.battle_state = 'Victory'
			sceneList[p].events.endingItem = battle.endingItem
			return true
		end

		_G.SaveFileMgr.Save(_G.SaveFileMgr.CurrentSave, save)
		--battle.keyCtrl:TransitionTo('keyVic')
	end
	Lose.DoOnEnter = function(self, battle, scene, ...)
		function save()
			local sceneList = _G.SaveFileMgr.CurrentSave.MapData.sceneList
			local p = TableFunc.Find(sceneList, battle.scene.name, 'name')
			sceneList[p].events.battle_state = 'Lose'
			sceneList[p].events.endingItem = battle.endingItem
			return true
		end

		_G.SaveFileMgr.Save(_G.SaveFileMgr.CurrentSave, save)
		--battle.keyCtrl:TransitionTo('keyLose')
	end

	machine.Update = function(self, battle, scene, ...)
		--print('BattleMachine Update')
		self.current:Do(battle, scene, ...)
		--print('current',self.current.name)
		--[[local hero_logic_result = machine.hero_cardLogic:Update(battle,...)	
		if hero_logic_result then
			scene.InsertResult(machine ,hero_logic_result)
		end

		local monster_logic_result = machine.monster_cardLogic:Update(battle,'m cardLogic update',...)
		if monster_logic_result then
			scene.InsertResult(machine ,monster_logic_result)
		end]]
	end

	return machine
end

return BattleMachine
