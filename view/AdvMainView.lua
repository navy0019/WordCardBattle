local AdvMainView = {}

local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr = require('lib.saveManager')
local TableFunc = require("lib.TableFunc")
local BattlePrint = require('view.battlePrint')
--local LogicScenesMgr = require('LogicScenesMgr')
local BattleRoundMachineView = require('view.battleRoundMachineView')

local LogicScenesMgr = _G.GameMachine.LogicScenesMgr

function AdvMainView.NewViewScene(adv_data)
	local scene = Scene.new('AdvStart')
	scene.pending = {}
	scene.drawCommand = {
		ChangeRoom = function(...)
			--print('AdV View Change Room')
			scene.Machine:TransitionTo('Wait')
		end,
		SceneTransitionTo = function(scene, nextState, ...)
			print('ADVScene TransitionTo', nextState)
			local viewState = ...
			local machine = scene.Machine
			if type(viewState) ~= 'boolean' and machine.current.name == viewState then
				machine:TransitionTo(nextState)
				--return true
			else
				machine:TransitionTo(nextState)
				--return true
			end
			--return false
		end,
	}

	local function MakeBasicEvent()
		scene.Event:Register('AddButton', function() end) -- print('ViewScenes try to add button')
		scene.Event:Register('WaitIoRead', function() end)

		scene.Event:Register('RemoveButton', function(name)
			--print('ViewScenes try to remove '..name)
			scene.ButtonEvent:RemoveRegister(name)
		end)
		--scene.Event:Register('AddButtonEvent',function()end)
	end
	MakeBasicEvent()

	local function MakeRoomButton(adv_data, next)
		local adv_data = LogicScenesMgr.CurrentScene.adv_data
		local map = adv_data.map
		local i, j = adv_data.player_pos[1], adv_data.player_pos[2]
		local current_room = map[i][j]

		if j - 1 > 0 and map[i][j - 1].type == 'room' and TableFunc.Find(current_room.connect, map[i][j - 1]) then
			scene.ButtonEvent:Register('left', function(...) end)
			scene.Event:Emit('AddButton', 'left', 'a', 'switchScene', 0, -1)
		end
		if j + 1 <= #map and map[i][j + 1].type == 'room' and TableFunc.Find(current_room.connect, map[i][j + 1]) then
			scene.ButtonEvent:Register('right', function(...) end)
			scene.Event:Emit('AddButton', 'right', 'd', 'switchScene', 0, 1)
		end
		if i - 1 > 0 and map[i - 1][j].type == 'room' and TableFunc.Find(current_room.connect, map[i - 1][j]) then
			scene.ButtonEvent:Register('up', function(...) end)
			scene.Event:Emit('AddButton', 'up', 'w', 'switchScene', -1, 0)
		end
		if i + 1 <= #map and map[i + 1][j].type == 'room' and TableFunc.Find(current_room.connect, map[i + 1][j]) then
			scene.ButtonEvent:Register('down', function(...) end)
			scene.Event:Emit('AddButton', 'down', 's', 'switchScene', 1, 0)
		end
		scene.ButtonEvent:Register('back', function(...) print('ViewScenes press back') end)
		scene.Event:Emit('AddButton', 'back', 'back', 'switchScene', 'City')
	end
	local function RemoveRoomButton()
		local remove = {}
		for k, v in pairs(scene.ButtonEvent) do
			TableFunc.Push(remove, k)
		end
		for k, v in pairs(remove) do
			scene.Event:Emit('RemoveButton', v)
		end
	end

	function scene.Enter()
		local EmptyRoom = State.new("EmptyRoom")

		local Wait = State.new("Wait")
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

		Wait.DoOnEnter = function()
			local dataScene = LogicScenesMgr.CurrentScene
			assert(dataScene, 'dataScene not exist')
			--print('ADV ViewScene Wait Enter ', dataScene, #dataScene.toView, dataScene.toView)
		end
		Wait.Do = function()
			local dataScene = LogicScenesMgr.CurrentScene
			--assert(dataScene, 'dataScene not exist')
			--print('ADV ViewScene Wait ', dataScene, #dataScene.toView, dataScene.toView)

			local adv_data = LogicScenesMgr.CurrentScene.adv_data
			local map = adv_data.map
			local x, y = adv_data.player_pos[1], adv_data.player_pos[2]

			scene.Current_Room = adv_data.map[x][y]
			--print('view current room',x,y)
			BattlePrint.PrintMap(map, adv_data.player_pos)

			--scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnEnter = function()
			print('EventRoom View')
			MakeRoomButton(LogicScenesMgr.CurrentScene.adv_data)
			scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnLeave = function()
			RemoveRoomButton()
		end
		BattleRoom.DoOnEnter = function()
			--print('BattleRoom View Enter') --, LogicScenesMgr.CurrentScene
			scene.Current_Room.battle = LogicScenesMgr.CurrentScene.Current_Room.battle
			scene.Current_Room.BattleRoundMachineView = BattleRoundMachineView.new(scene.Current_Room.battle, scene)
		end
		BattleRoom.Do = function()
			--print('BattleRoom ViewScenes Update')
			scene.Current_Room.BattleRoundMachineView:Update()
		end
		EmptyRoom.DoOnEnter = function()
			MakeRoomButton(LogicScenesMgr.CurrentScene.adv_data, 'Init')
			local dataScene = LogicScenesMgr.CurrentScene
			assert(dataScene, 'dataScene not exist')
			--print('EmptyRoom View', dataScene, #dataScene.toView, dataScene.toView)
			scene.Event:Emit('WaitIoRead')
		end
		EmptyRoom.DoOnLeave = function()
			RemoveRoomButton()
			local dataScene = LogicScenesMgr.CurrentScene
			assert(dataScene, 'dataScene not exist')
			--print('EmptyRoom View Leave', dataScene, #dataScene.toView, dataScene.toView)
		end

		--[[if LogicScenesMgr.CurrentScene.events.isBattle then
			scene.battle = 	LogicScenesMgr.CurrentScene.battle		
			scene.Machine:TransitionTo('BattleRoom')
		else
			scene.Machine:TransitionTo('Init')
		end]]
		--scene.Machine:TransitionTo('Wait')
	end

	function scene.Exit()
		scene.ButtonEvent:RemoveAll()
		scene.Event:ClearAll()
		MakeBasicEvent()
	end

	function scene.Update(dt)
		local dataScene = LogicScenesMgr.CurrentScene
		assert(dataScene, 'dataScene not exist')
		--print(scene.name .. ' ViewScenes Update', #dataScene.toView, dataScene.toView)

		scene:FromData(dataScene)
		scene:ViewPending()
		scene.Machine:Update()
	end

	return scene
end

return AdvMainView
