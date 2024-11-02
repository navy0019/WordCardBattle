local CallBack = require("lib.callback")
local SceneMgr = require('lib.sceneManager')
local TableFunc = require('lib.TableFunc')
local LogicScenesMgr = require('LogicScenesMgr')
local GameMachine = require('GameMachine')

local drawCommand = {
	SwitchScene = function(ViewScenesMgr)
		--print('viewSwitch',LogicScenesMgr.CurrentScene.name)
		print('ViewScenesMgr', ViewScenesMgr.Event)
		ViewScenesMgr:Switch(LogicScenesMgr.CurrentScene.name, ViewScenesMgr.Event)
	end,

}


local ViewScenesMgr = SceneMgr.new() --{Event=CallBack.new(),SceneMap=SceneMap}
ViewScenesMgr.name = 'ViewScenesMgr'
ViewScenesMgr.pending = {}
ViewScenesMgr.Event = CallBack.new()
ViewScenesMgr.Event:Register('Enter', function() end)
ViewScenesMgr.Event:Register('Exit', function() end)

function ViewScenesMgr.Init()
	local Start = require('view.StartView')
	local City = require('view.CityView')
	local Team = require('view.TeamView')

	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene, Start)
	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene, City)
	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene, Team)

	ViewScenesMgr.CurrentScene = Start

	--GameMachine.MakeBasicEvent()
	ViewScenesMgr.Event:Emit('Enter')
	ViewScenesMgr.CurrentScene.Enter()
end

function ViewScenesMgr.Update()
	local LogicScenesMgrToView = LogicScenesMgr.toSceneViewsMgr
	if #LogicScenesMgrToView > 0 then
		print('toSceneViewsMgr add')
		for i = #LogicScenesMgrToView, 1, -1 do
			local v = LogicScenesMgrToView[i]
			TableFunc.Unshift(ViewScenesMgr.pending, v.command)
		end
	end

	for i = #ViewScenesMgr.pending, 1, -1 do
		local v = ViewScenesMgr.pending[i]
		assert(v, 'error ' .. i .. '  ' .. #ViewScenesMgr.pending .. '   ' .. tostring(v))
		local key = v.key
		local arg = v.arg
		local viewState = v.viewState

		--if v.scene_name == ViewScenesMgr.CurrentScene.name then
		print('ViewScenesMgr pending', v.scene_name, key)
		local result = drawCommand[key](ViewScenesMgr, table.unpack(arg))
		TableFunc.Pop(ViewScenesMgr.pending)
		--[[else
			print('scene name diff',ViewScenesMgr.CurrentScene.name ,v.scene_name )
		end		]]
	end
	ViewScenesMgr.CurrentScene.Update()
end

return ViewScenesMgr
