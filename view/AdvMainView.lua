local AdvMainView={}

local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")
local BattlePrint = require('view.battlePrint')
local LogicScenesMgr = require('LogicScenesMgr')
local BattleMachineView = require('view.BattleMachineView')

function AdvMainView.NewViewScene( adv_data)
	local scene = Scene.new('AdvStart')
	scene.drawCommand = {
		ChangeRoom=function(...) scene.Machine:TransitionTo('Wait') end
	}

	local function MakeBasicEvent()
		scene.Event:Register('AddButton',function()  end) -- print('ViewScenes try to add button')
		scene.Event:Register('WaitIoRead',function()end)

		scene.Event:Register('RemoveButton',function(name)
				--print('ViewScenes try to remove '..name)
				scene.ButtonEvent:RemoveRegister(name)
		end)
		--scene.Event:Register('AddButtonEvent',function()end)
	end
	MakeBasicEvent()

	local function MakeRoomButton(adv_data ,next)
		local adv_data =LogicScenesMgr.CurrentScene.adv_data
		local map = adv_data.map
		local i,j = adv_data.player_pos[1] , adv_data.player_pos[2]
		local current_room = map[i][j]

		if j-1 > 0 and map[i][j-1].type=='room' and TableFunc.Find(current_room.connect, map[i][j-1]) then
			scene.ButtonEvent:Register('left',function(...)  end)
			scene.Event:Emit('AddButton','left', 'a' ,'switchScene',0, -1)				
		end
		if j+1 <= #map and map[i][j+1].type=='room'and TableFunc.Find(current_room.connect, map[i][j+1]) then
			scene.ButtonEvent:Register('right',function(...)  end)
			scene.Event:Emit('AddButton','right', 'd' ,'switchScene',0 , 1)	
		end
		if i-1 > 0 and map[i-1][j].type=='room'and TableFunc.Find(current_room.connect, map[i-1][j])then
			scene.ButtonEvent:Register('up',function(...)  end)
			scene.Event:Emit('AddButton','up', 'w' ,'switchScene',-1 , 0)	
		end
		if i+1 <= #map and map[i+1][j].type=='room'and TableFunc.Find(current_room.connect, map[i+1][j])then
			scene.ButtonEvent:Register('down',function(...) end)
			scene.Event:Emit('AddButton','down', 's' ,'switchScene',1 , 0)	
		end	
		scene.ButtonEvent:Register('back',function(...) print('ViewScenes press back') end)
		scene.Event:Emit('AddButton','back', 'back' ,'switchScene','City')	
	end
	local function RemoveRoomButton()
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			TableFunc.Push(remove,k)
		end
		for k,v in pairs(remove) do
			scene.Event:Emit('RemoveButton',v)			
		end
	end

	function scene.Enter()
		local EmptyRoom = State.new("EmptyRoom")

		local Wait = State.new("Wait")
		local EventRoom = State.new("EventRoom")
		local BattleRoom = State.new("BattleRoom")

		scene.Machine = Machine.new(
		{
			initial=Wait,
			states={
				EmptyRoom  ,BattleRoom ,EventRoom ,Wait
			},
			events={
				{state=EmptyRoom, global=true},
				{state=BattleRoom, global=true},
				{state=EventRoom, global=true},
				{state=Wait,global=true}
			}
		}
		
		)

		Wait.Do=function()
			--print('ADV ViewScene enter ')
			
			local adv_data = LogicScenesMgr.CurrentScene.adv_data
			local map = adv_data.map
			local x,y = adv_data.player_pos[1] , adv_data.player_pos[2]

			scene.Current_Room = adv_data.map[x][y]
			print('view current room',x,y)
			BattlePrint.PrintMap(map ,adv_data.player_pos)		
			
			
			if scene.Current_Room.event~='empty' then
				--print('have event ',scene.Current_Room.event)
				if scene.Current_Room.event =='enter' then
					scene.Machine:TransitionTo('EmptyRoom')

				else
					scene.Machine:TransitionTo('EventRoom')

				end
			elseif 	scene.Current_Room.battle then
				--print('have battle')
				scene.battle = 	LogicScenesMgr.CurrentScene.battle	
				scene.Machine:TransitionTo('BattleRoom')
			else
				scene.Machine:TransitionTo('EmptyRoom')
			end
			--scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnEnter=function()
			print('EventRoom View')
			MakeRoomButton(LogicScenesMgr.CurrentScene.adv_data)
			scene.Event:Emit('WaitIoRead')

		end
		EventRoom.DoOnLeave=function()
			RemoveRoomButton()
		end
		BattleRoom.DoOnEnter=function()
			print('BattleRoom View')
			local battle = LogicScenesMgr.CurrentScene.battle
			scene.BattleMachineView = BattleMachineView.new(battle ,scene)
		end
		BattleRoom.Do=function()
			--print('BattleRoom ViewScenes Updata')
			scene.BattleMachineView:Update()

		end
		EmptyRoom.DoOnEnter=function()
			print('EmptyRoom View')
			MakeRoomButton(LogicScenesMgr.CurrentScene.adv_data ,'Init')
	
			scene.Event:Emit('WaitIoRead')
		end
		EmptyRoom.DoOnLeave=function()
			RemoveRoomButton()
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
		--print(scene.name..' ViewScenes Update',scene.switchScene)
		local dataScene = LogicScenesMgr.CurrentScene
		scene:FromLogic(dataScene)
		scene:ViewPending()
		scene.Machine:Update()

	end

	return scene
end

return AdvMainView