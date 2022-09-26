local CallBack = require("lib.callback")
local SceneMgr = require('lib.sceneManager')
local TableFunc=require('lib.TableFunc')

local LogicScenesMgr=SceneMgr.new()--{SaveFileMgr=SaveFileMgr,SceneMgr=SceneMgr,Event=CallBack.new()}
LogicScenesMgr.name='LogicScenesMgr'
LogicScenesMgr.toViewScenesMgr={}
LogicScenesMgr.Event=CallBack.new()
function LogicScenesMgr.Init()
	local Start = require('scene.StartScene')
	local Main = require('scene.MainScene')
	local Team = require('scene.TeamScene')
	local AdvStart = require('scene.AdvStartScene')

	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,Start)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,Main)
	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene ,Team)
	LogicScenesMgr:AddScene(LogicScenesMgr.Adventure ,AdvStart)

	LogicScenesMgr.CurrentScene=Start
	LogicScenesMgr.CurrentScene.Enter()

end

function LogicScenesMgr.Update()

	if LogicScenesMgr.CurrentScene ~= nil and LogicScenesMgr.CurrentScene.switchingScene ~= nil then
		local switchingScene = LogicScenesMgr.CurrentScene.switchingScene
		LogicScenesMgr.CurrentScene.switchingScene = nil
		if type(switchingScene) == 'string' and switchingScene~='AdvStart' then
			--print('LogicScenesMgr switchingScene '..type(switchingScene))
			LogicScenesMgr:Switch(LogicScenesMgr.NormalScene, switchingScene)
			local command ={alreadySent=false,command={key='SwitchScene' ,arg={}} }
			TableFunc.Push(LogicScenesMgr.toViewScenesMgr ,command)

		elseif LogicScenesMgr.CurrentScene.switchingScene == nil then
			--print('LogicScenesMgr switchingScene ',switchingScene)
			LogicScenesMgr:Switch(LogicScenesMgr.Adventure, switchingScene)
			local command ={alreadySent=false,command={key='SwitchScene' ,arg={}} }
			TableFunc.Push(LogicScenesMgr.toViewScenesMgr ,command)
		end		
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