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
		end	
		SaveMgr.Save(SaveMgr.CurrentSave  ,scene.AdvGenerator.Save)
		
	end
	scene.Update=function()
		--scene.Machine:Update()
		scene.AdvGenerator.Check()
		scene:FromCtrl()
		if scene.battle then
			scene.battle:Update()
						
		end

		--[[if #scene.pending > 0 then
			for i=1, #scene.pending do
				local v = scene.pending[1]
				if scene.battle then
					local battle = scene.battle
					local machine = scene.battle.machine
					--讓machine 自行安排解讀
					table.insert(machine.pending,{func=machine.funcTab[v.name],arg={battle,table.unpack(v.arg)},actName=v.name})
					table.remove(scene.pending,1)
				else
					funcTab[v.name](scene ,scene.AdvGenerator ,table.unpack(v.arg))
					table.remove(scene.pending,1)
				end
			end
		end

		--有需要ViewScenes抓取的內容 只存在一個update 下個update移除
		if #scene.toViewScene > 0 then
			for k= #scene.toViewScene , 1,-1  do
				local v = scene.toViewScene[k]
				if v.alreadySent then
					table.remove(scene.toViewScene,k)
				else
					v.alreadySent=true
				end
			end
		end]]
	end

	scene.Exit=function()
	end
	return scene

end

return AdvScene