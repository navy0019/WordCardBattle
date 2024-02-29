local CallBack = require("lib.callback")
local SceneMgr = require('lib.sceneManager')
local TableFunc=require('lib.TableFunc')

local LogicScenesMgr=SceneMgr.new()--{SaveFileMgr=SaveFileMgr,SceneMgr=SceneMgr,Event=CallBack.new()}
LogicScenesMgr.name='LogicScenesMgr'
LogicScenesMgr.toViewScenesMgr={}
LogicScenesMgr.Event=CallBack.new()
function LogicScenesMgr.Init()
	local Start = require('scene.StartScene')
	local City = require('scene.CityScene')
	local Team = require('scene.TeamScene')

	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,Start)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,City)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,Team)

	LogicScenesMgr.CurrentScene=Start
	LogicScenesMgr.CurrentScene.Enter()

end

function LogicScenesMgr.Update()

	if LogicScenesMgr.CurrentScene ~= nil and LogicScenesMgr.CurrentScene.switchingScene ~= nil then
		print('data switch')
		local switchingScene = LogicScenesMgr.CurrentScene.switchingScene
		LogicScenesMgr.CurrentScene.switchingScene = nil
		LogicScenesMgr:Switch( switchingScene)
		local command ={alreadySent=false,command={key='SwitchScene' ,arg={}} }
		TableFunc.Push(LogicScenesMgr.toViewScenesMgr ,command)

	end
	
	if #LogicScenesMgr.toViewScenesMgr > 0 then
		for k= #LogicScenesMgr.toViewScenesMgr , 1, -1 do
			local v = LogicScenesMgr.toViewScenesMgr[k]		
			if v.alreadySent then
				TableFunc.Pop(LogicScenesMgr.toViewScenesMgr)
			else
				v.alreadySent=true
			end			
		end
	end
	LogicScenesMgr.CurrentScene.Update()
end
return LogicScenesMgr