local CallBack = require("lib.callback")
local SceneMgr = require('lib.sceneManager')
local TableFunc = require('lib.TableFunc')

local LogicScenesMgr = SceneMgr.new() --{SaveFileMgr=SaveFileMgr,SceneMgr=SceneMgr,Event=CallBack.new()}
LogicScenesMgr.name = 'LogicScenesMgr'
LogicScenesMgr.toSceneViewsMgr = {}
LogicScenesMgr.Event = CallBack.new()
function LogicScenesMgr.Init()
	local Start = require('scene.StartScene')
	local City = require('scene.CityScene')
	local Team = require('scene.TeamScene')

	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene, Start)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene, City)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene, Team)

	LogicScenesMgr.CurrentScene = Start
	LogicScenesMgr.CurrentScene.Enter()
end

function LogicScenesMgr.Update()
	if LogicScenesMgr.CurrentScene ~= nil and LogicScenesMgr.CurrentScene.switchingScene ~= nil then
		print('data switch')
		local switchingScene = LogicScenesMgr.CurrentScene.switchingScene
		local command = { alreadySent = false, command = { scene_name = LogicScenesMgr.CurrentScene.name, key = 'SwitchScene', arg = {} } }
		local scene_name = LogicScenesMgr.CurrentScene.name
		LogicScenesMgr.CurrentScene.switchingScene = nil
		LogicScenesMgr:Switch(switchingScene)
		local command = { alreadySent = false, command = { scene_name = scene_name, key = 'SwitchScene', arg = {} } }
		TableFunc.Push(LogicScenesMgr.toSceneViewsMgr, command)
	end

	if #LogicScenesMgr.toSceneViewsMgr > 0 then
		for k = #LogicScenesMgr.toSceneViewsMgr, 1, -1 do
			local v = LogicScenesMgr.toSceneViewsMgr[k]
			if v.alreadySent then
				--print('send toSceneViewsMgr')
				--print(v.scene_name ,v.key)
				--TableFunc.Dump(v)
				TableFunc.Pop(LogicScenesMgr.toSceneViewsMgr)
			else
				v.alreadySent = true
			end
		end
	end
	LogicScenesMgr.CurrentScene.Update()
end

return LogicScenesMgr
