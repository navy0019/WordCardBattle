local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local TableFunc = require("lib.TableFunc")
local LogicScenesMgr = require('LogicScenesMgr')

local Show = require('show')

local scene = Scene.new('City')

local function MakeBasicEvent( )
	scene.Event:Register('AddButton',function() end) -- print('scene try to add button')
	scene.Event:Register('WaitIoRead',function() scene.Machine.waitIoRead=true	end)

	scene.Event:Register('RemoveButton',function(name)
			--print('scene try to remove '..name)
			scene.ButtonEvent:RemoveRegister(name)
	end)
end
MakeBasicEvent()

function scene.Enter()
	--MakeBasicEvent()
	local Empty = State.new("Empty")
	local Wait = State.new("Wait")

	scene.Machine = Machine.new({
		initial=Empty,
		states={
			Empty , Wait
		},
		events={
			{state=Empty,to='Wait'},
			--{state=Wait,to='Empty'}
		}
	})

	Wait.DoOnEnter=function()
		print('1:開始冒險 2: 組隊')

		scene.Event:Emit('AddButton','MakeTeamButton',2 ,'switchScene','Team')
		scene.ButtonEvent:Register('MakeTeamButton',function(...) end)

		scene.ButtonEvent:Register('AdvStartButton',function(...) end)
		scene.Event:Emit('AddButton','AdvStartButton',1 ,'switchScene','AdvStart')		
		scene.Event:Emit('WaitIoRead')
	end

	scene.Machine:TransitionTo('Wait')

end
function scene.Exit()
	scene.ButtonEvent:RemoveAll()
	scene.Event:ClearAll()
	MakeBasicEvent()
end
function scene.Update(dt)
	--print('Main scene Update')
	local dataScene = LogicScenesMgr.CurrentScene
	scene:FromLogic(dataScene)
	scene:ViewPending()
	scene.Machine:Update()

end
function scene.debugDraw()
end
return scene