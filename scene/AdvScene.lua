local LogicScenesMgr = require('LogicScenesMgr')

local Scene = require('lib.scene')
local TableFunc = require("lib.TableFunc")
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Item = require('lib.Item')
local SaveMgr=require('lib.saveManager')
--local MapData = require('lib.MapData')
local CallBack = require("lib.callback")

local Battle = require('battle.battle')

local AdvScene = {}


function AdvScene.NewDataScene(name,events,AdvGenerator)
	local scene = Scene.new(name)
	scene.next=nil
	scene.previous=nil
	scene.battle=nil
	scene.events = events
	scene.AdvGenerator=AdvGenerator

	local function switchScene(...)

		--print('Data SwitchScene ',presskey ,name ,scene ,AdvGenerator ,#{...})
		local pressKey , name = ...
		if name == 'previous' then
			scene.AdvGenerator:ResetMap() 
			scene.switchingScene = 'Main'
		else
			scene.switchingScene=scene[name]
			scene.AdvGenerator.mapData.stepFromDoor=scene.AdvGenerator.mapData.stepFromDoor+1
		end
		return true
	end
	scene.funcTab = {
		blackSmith=function() print('Data press blackSmith') return true end,
		campfire=function() print('Data press campfire') return true end,
		potionTable=function() print('Data press potionTable') return true end,
		switchScene=switchScene
	}

	scene.Enter=function()
    	--逃生門出現後 重新調整
		if #scene.events.door >0 and LogicScenesMgr.Adventure.head~=scene then
			scene.AdvGenerator.MoveToDoor()
		end
		--print('Adv Data '..scene.name..' Enter')

		if scene.events.isBattle then
			scene.battle=Battle.new(scene)
			Battle.InitBattleData(battle ,scene)
		end	
		SaveMgr.Save(SaveMgr.CurrentSave  ,scene.AdvGenerator.Save)
		
	end
	scene.Update=function()
		--scene.Machine:Update()
		scene.AdvGenerator.Check()
		scene:FromCtrl() 
		scene:DataPending()

	end

	scene.Exit=function()
	end
	return scene

end

return AdvScene