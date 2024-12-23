local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Scene = require('lib.scene')
local SaveMgr = require('lib.saveManager')
local Battle = require('battle.battle')
local Dungeon_Rule = require('adv.Dungeon_Rule')

local AdvMainScene = {}

function AdvMainScene.NewDataScene(adv_data, save_func)
	local scene = Scene.new('AdvStart')
	scene.adv_data = adv_data
	scene.toBattleView = {}

	local function switchScene(...)
		local arg = { ... }
		if #arg > 1 then
			local x, y = arg[2], arg[3]
			scene.adv_data.player_pos[1] = scene.adv_data.player_pos[1] + x
			scene.adv_data.player_pos[2] = scene.adv_data.player_pos[2] + y
			scene.adv_data.map_data.passed_room = scene.adv_data.map_data.passed_room + 1
			Dungeon_Rule:Check_Level(adv_data.map_data)
			scene.Machine:TransitionTo('Wait')
			return { toView = { key = 'ChangeRoom', arg = {} } }
		else
			scene.switchingScene = name
		end
		--print('have save ',save_func)
		SaveMgr.Save(save_func, scene)
	end
	local function switchMachineState(nextState)
		--print('D to V TransitionTo', nextState)
		return { toView = { key = 'SceneTransitionTo', arg = { nextState } } }
	end
	scene.funcTab = {
		switchScene = switchScene,
		switchMachineState = switchMachineState
	}
	function scene.Enter()
		--print('Adv DataScene enter')

		local Wait = State.new("Wait")
		local EmptyRoom = State.new("EmptyRoom")
		local EventRoom = State.new("EventRoom")
		local BattleRoom = State.new("BattleRoom")

		scene.Machine = Machine.new(
			{
				initial = Wait,
				states = {
					EmptyRoom, BattleRoom, EventRoom, Wait
				},
				events = {
					{ state = EmptyRoom,  global = true },
					{ state = BattleRoom, global = true },
					{ state = EventRoom,  global = true },
					{ state = Wait,       global = true }
				}
			}

		)

		Wait.Do = function()
			--print('ADV ViewScene enter ')

			local adv_data = scene.adv_data
			local map = adv_data.map
			local x, y = adv_data.player_pos[1], adv_data.player_pos[2]

			scene.Current_Room = adv_data.map[x][y]
			--print('data current room',x,y)

			if scene.Current_Room.event ~= 'empty' then
				if scene.Current_Room.event == 'enter' then
					scene.Machine:TransitionTo('EmptyRoom')
					--print('data TransitionTo empty')
					TableFunc.Push(scene.pending, { key = 'switchMachineState', arg = { 'EmptyRoom' } })
				else
					--print('data have event')
					scene.Machine:TransitionTo('EventRoom')
					TableFunc.Push(scene.pending, { key = 'switchMachineState', arg = { 'EventRoom' } })
				end
			elseif scene.Current_Room.battle then
				--scene.battle = 	scene.Current_Room.battle	
				--print('data have battle')
				scene.Machine:TransitionTo('BattleRoom')
				TableFunc.Push(scene.pending, { key = 'switchMachineState', arg = { 'BattleRoom' } })
				--TableFunc.Dump(scene.pending)
			else
				scene.Machine:TransitionTo('EmptyRoom')
				TableFunc.Push(scene.pending, { key = 'switchMachineState', arg = { 'EmptyRoom' } })
			end
			--scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnEnter = function()
			--print('EventRoom Data')
		end

		BattleRoom.DoOnEnter = function()
			scene.Current_Room.battle = Battle.new(scene)
			Battle.InitBattleData(scene.Current_Room.battle, scene)
			--print('BattleRoom Data Init', scene.Current_Room.battle)
		end
		BattleRoom.Do = function()
			--print('BattleRoom Data Update')
			scene.Current_Room.battle:Update(scene)
		end
		EmptyRoom.DoOnEnter = function()
			--print('EmptyRoom Data')
		end

		--[[if scene.Current_Room.type=='battle' then
			scene.Current_Room.battle=Battle.new(scene)
			Battle.InitBattleData(scene.battle ,scene)
		end	]]
		SaveMgr.Save(save_func, scene)
	end

	function scene.Update(dt)
		--print('DATA')

		scene:FromCtrl()
		scene:DataPending()

		scene.Machine:Update()
		--print(scene.name .. ' DataScenes Update', #scene.toView, scene.toView)
	end

	return scene
end

return AdvMainScene
