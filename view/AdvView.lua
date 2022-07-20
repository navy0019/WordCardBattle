local LogicScenesMgr = require('LogicScenesMgr')
local Show = require('show')

local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")

local BattleMachineView = require('view.BattleMachineView')

local AdvView = {}
function AdvView.NewViewScene( name,dataEvent )
	local scene = Scene.new(name)
	scene.next=nil
	scene.previous=nil
	scene.battle=nil

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

	function scene.Enter()
		local Empty = State.new("Empty")
		local Wait = State.new("Wait")
		local BattleMode = State.new("BattleMode")

		scene.Machine = Machine.new({
			initial=Empty,
			states={
				Empty , Wait ,BattleMode
			},
			events={
				{state=Empty,to='Wait'},
				{state=Empty,to='BattleMode'},
				--{state=Wait,to='BattleMode'},
				{state=BattleMode,to='Wait'},
			}
		})

		Wait.DoOnEnter=function()
			--print('ADV ViewScenes Wait STATE ENTER')
			local event = LogicScenesMgr.CurrentScene.events
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

			Show.PrintEvent(event)

			--[[scene.ButtonEvent:Register('PreButton',function(...) end)
			scene.Event:Emit('AddButton','PreButton',2 ,'switchScene','previous')]]		
			scene.Event:Emit('WaitIoRead')
		end
		BattleMode.DoOnEnter=function()
			--print('BattleMode ViewScenes')
			local battle = LogicScenesMgr.CurrentScene.battle
			scene.BattleMachineView = BattleMachineView.new(battle ,scene)
		end
		BattleMode.Do=function()
			--print('BattleMode ViewScenes Updata')
			scene.BattleMachineView:Update()

		end
		if LogicScenesMgr.CurrentScene.events.isBattle then
			scene.battle = 	LogicScenesMgr.CurrentScene.battle		
			scene.Machine:TransitionTo('BattleMode')
		else
			scene.Machine:TransitionTo('Wait')
		end
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
		scene.Machine:Update()

	end

	return scene
end
return AdvView