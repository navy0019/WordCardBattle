local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")
local LogicScenesMgr = require('LogicScenesMgr')
local Show = require('show')

local scene = Scene.new('AdvStart')
scene.next=nil
scene.previous=nil
scene.sprite={
	img={bg='makeTeamBG',},
	buttons={{name='saveData_1',funcName='selectSave',resKey='saveDataButton',pressKey=1},
	{name='saveData_2',funcName='selectSave',resKey='saveDataButton',pressKey=2},
	{name='pressAnyButton',funcName='pressAny',resKey='choose_pop_BG',pressKey='any'}},					
	
}

local function MakeBasicEvent( )
	scene.Event:Register('AddButton',function() end) -- print('ViewScenes try to add button')
	scene.Event:Register('WaitIoRead',function() scene.Machine.waitIoRead=true	end)

	scene.Event:Register('RemoveButton',function(name)
			--print('ViewScenes try to remove '..name)
			scene.ButtonEvent:RemoveRegister(name)
	end)
end
MakeBasicEvent()

function scene.Enter()
	--print('AdvStart ViewScenes Enter')
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
		print('1: 前進   2:後退')

		scene.ButtonEvent:Register('NextButton',function(...) end)
		scene.Event:Emit('AddButton','NextButton',1 ,'switchScene','next')

		scene.ButtonEvent:Register('PreButton',function(...)  end)--print('press 2')
		scene.Event:Emit('AddButton','PreButton',2 ,'switchScene','previous')		
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
	--print('AdvStart ViewScenes Update')
	local dataScene = LogicScenesMgr.CurrentScene
	scene:FromLogic(dataScene)
	scene.Machine:Update()

end
function scene.debugDraw()
end
return scene