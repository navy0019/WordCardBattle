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
		local map = adv_data.map
		local i,j = adv_data.player_pos[1] , adv_data.player_pos[2]
		local current_room = map[i][j]

		if j-1 > 0 and map[i][j-1].type=='room' and TableFunc.Find(current_room.connect, map[i][j-1]) then
			scene.ButtonEvent:Register('left',function(...) scene.Machine:TransitionTo(next) end)
			scene.Event:Emit('AddButton','left', 'a' ,'switchScene',0, -1)				
		end
		if j+1 <= #map and map[i][j+1].type=='room'and TableFunc.Find(current_room.connect, map[i][j+1]) then
			scene.ButtonEvent:Register('right',function(...) scene.Machine:TransitionTo(next) end)
			scene.Event:Emit('AddButton','right', 'd' ,'switchScene',0 , 1)	
		end
		if i-1 > 0 and map[i-1][j].type=='room'and TableFunc.Find(current_room.connect, map[i-1][j])then
			scene.ButtonEvent:Register('up',function(...) scene.Machine:TransitionTo(next) end)
			scene.Event:Emit('AddButton','up', 'w' ,'switchScene',-1 , 0)	
		end
		if i+1 <= #map and map[i+1][j].type=='room'and TableFunc.Find(current_room.connect, map[i+1][j])then
			scene.ButtonEvent:Register('down',function(...) scene.Machine:TransitionTo(next) end)
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
		local Init = State.new("Init")
		local EventRoom = State.new("EventRoom")
		local BattleRoom = State.new("BattleRoom")

		scene.Machine = Machine.new(
		{
			initial=Init,
			states={
				EmptyRoom , Init ,BattleRoom ,EventRoom 
			},
			events={
				{state=Init,to='EmptyRoom'},
				{state=Init,to='BattleRoom'},
				{state=Init,to='EventRoom'},

				{state=EmptyRoom,to='Init'},
				{state=EmptyRoom,to='BattleRoom'},
				{state=EmptyRoom,to='EventRoom'},
				--{state=Wait,to='BattleRoom'},
				{state=BattleRoom,to='EmptyRoom'},
				{state=EventRoom,to='EmptyRoom'},
			}
		}
		
		)

		Init.Do=function()
			--print('ADV ViewScene enter ')
			
			local adv_data = LogicScenesMgr.CurrentScene.adv_data
			local map = adv_data.map
			local x,y = adv_data.player_pos[1] , adv_data.player_pos[2]

			scene.Current_Room = adv_data.map[x][y]
			print('view current room',x,y)
			BattlePrint.PrintMap(map ,adv_data.player_pos)		
			--[[local event = LogicScenesMgr.CurrentScene.events
			print('\n房間: '..scene.name)--,event.doorchance
			
			local keynum = 1
			local door = #event.door >0 and event.door[1] or false
			if door then				
				scene.ButtonEvent:Register('GoHomeButton',function(...) end)
				scene.Event:Emit('AddButton','GoHomeButton', keynum ,'switchScene','previous')
				keynum=keynum + 1
			end
			for k,v in pairs(event.event) do				
				scene.ButtonEvent:Register(v..'Button',function(...) print('ViewScenes press '..v) scene.Event:Emit('WaitIoRead') end)
				scene.Event:Emit('AddButton',v..'Button', keynum , v )
				keynum=keynum + 1
			end

			scene.ButtonEvent:Register('NextButton',function(...) print('ViewScenes Press Next') end)
			scene.Event:Emit('AddButton','NextButton', keynum ,'switchScene','next')

			Show.PrintEvent(event)]]
			
			
			if scene.Current_Room.event~='empty' then
				print('have event ',scene.Current_Room.event)
				if scene.Current_Room.event =='enter' then
					scene.Machine:TransitionTo('EmptyRoom')
				elseif scene.Current_Room.event =='battle' then
					scene.battle = 	LogicScenesMgr.CurrentScene.battle	
					scene.Machine:TransitionTo('BattleRoom')
				else
					scene.Machine:TransitionTo('EventRoom')
				end
			else
				scene.Machine:TransitionTo('EmptyRoom')
			end
			scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnEnter=function()
			print('Event Room')
			MakeRoomButton(LogicScenesMgr.CurrentScene.adv_data ,'EmptyRoom')
			scene.Event:Emit('WaitIoRead')

		end
		BattleRoom.DoOnEnter=function()
			--print('BattleRoom ViewScenes')
			local battle = LogicScenesMgr.CurrentScene.battle
			scene.BattleMachineView = BattleMachineView.new(battle ,scene)
		end
		BattleRoom.Do=function()
			--print('BattleRoom ViewScenes Updata')
			scene.BattleMachineView:Update()

		end
		EmptyRoom.DoOnEnter=function()
			print('Empty Room')
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