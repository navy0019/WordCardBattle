local CallBack = require("lib.callback")
local SceneMgr = require('lib.sceneManager')
local TableFunc=require('lib.TableFunc')
local LogicScenesMgr = require('LogicScenesMgr')
local GameMachine = require('GameMachine')

local drawCommand = {
	SwitchScene=function(ViewScenesMgr)
		--print('Switch!')
		if type(LogicScenesMgr.CurrentScene.name) == 'string' and LogicScenesMgr.CurrentScene.name~='AdvStart' then
			ViewScenesMgr:Switch(ViewScenesMgr.NormalScene, LogicScenesMgr.CurrentScene.name ,ViewScenesMgr.Event)
		else
			local nextScene = ViewScenesMgr.Adventure:MoveTo(LogicScenesMgr.CurrentScene.name)
			ViewScenesMgr:Switch(ViewScenesMgr.Adventure, nextScene ,ViewScenesMgr.Event)
		end

	end,

}


local ViewScenesMgr=SceneMgr.new()--{Event=CallBack.new(),SceneMap=SceneMap}
ViewScenesMgr.name='ViewScenesMgr'
ViewScenesMgr.pending={}
ViewScenesMgr.Event=CallBack.new()
ViewScenesMgr.Event:Register('Enter',function() end) 
ViewScenesMgr.Event:Register('Exit',function() end) 

function ViewScenesMgr.Init()
	local Start = require('view.StartView')
	local Main = require('view.MainView')
	local Team = require('view.TeamView')
	local AdvStart = require('view.AdvStartView')

	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene ,Start)
	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene ,Main)
	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene ,Team)
	ViewScenesMgr:AddScene(ViewScenesMgr.Adventure ,AdvStart)

	ViewScenesMgr.CurrentScene=Start

	--GameMachine.MakeBasicEvent()
	ViewScenesMgr.Event:Emit('Enter')
	ViewScenesMgr.CurrentScene.Enter()
end


function ViewScenesMgr.Update()

	local LogicScenesMgrToView = LogicScenesMgr.toViewScenesMgr
	if #LogicScenesMgrToView > 0 then
		--print('toViewScenesMgr add')
		for i=#LogicScenesMgrToView ,1 ,-1  do
			local v = LogicScenesMgrToView[i]		
			TableFunc.Unshift(ViewScenesMgr.pending ,v.command)
		end
	end

	for i=#ViewScenesMgr.pending, 1 ,-1 do
		local v = ViewScenesMgr.pending[i]
		assert(v ,'error '..i..'  '..#ViewScenesMgr.pending..'   '..tostring(v))
		local key = v.key
		local arg = v.arg
		local viewState = v.viewState

		local result =drawCommand[key](ViewScenesMgr,table.unpack(arg))	
		TableFunc.Pop(ViewScenesMgr.pending)				
			
	end
	ViewScenesMgr.CurrentScene.Update()
	
end

return ViewScenesMgr