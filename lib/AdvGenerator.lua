local LogicScenesMgr = require('LogicScenesMgr')
local ViewScenesMgr = require('ViewScenesMgr')

local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local Item = require('lib.Item')
local TableFunc = require("lib.TableFunc")

local AdvData = require('scene.AdvScene')
local AdvView = require('view.AdvView')

--local Assets = require('resource.allAssets')
local CharacterAssets = require('resource.characterAssets')

local AdvGenerator ={
	heroData={},
	originHead=nil,
	mapData={stepFromDoor=0,money=0,passedRoom=0,dropItem=1,sceneList={}}
}
function AdvGenerator:ResetHeroData(...)
	for k,v in pairs(self.heroData) do
		v.data=TableFunc.Copy(v.originData)
		v.data.Status={before={}, after={}, always={}}
	end
end

function AdvGenerator:SetAdvData( CurrentSave)
	self.heroData={}
	--TableFunc.Dump(CurrentSave.CurrentTeam)
	for k,v in pairs(CurrentSave.CurrentTeam) do
		--local hero = Assets.Characters.instance(v , 0 ,-24)
		local hero = CharacterAssets.instance(v,k)
		if CurrentSave.CurrentTeamData[k] then
			hero.data=CurrentSave.CurrentTeamData[k]
		else
			CurrentSave.CurrentTeamData[k]=hero.data
		end
		hero.data.teamPos=k
		table.insert(self.heroData,hero)
	end
end
function AdvGenerator:ResetMap(...)
	LogicScenesMgr.Adventure:Clear()
	LogicScenesMgr:AddScene(LogicScenesMgr.Adventure ,self.originHead)--MapData.originHead
	--MapData:ResetMap()
	self.mapData={stepFromDoor=0,money=0,passedRoom=0,dropItem=1,sceneList={}}

end
function AdvGenerator.MoveToDoor()
	AdvGenerator.mapData.stepFromDoor=0
	local scene=LogicScenesMgr.Adventure:MoveTo(LogicScenesMgr.CurrentScene.name)
	LogicScenesMgr.Adventure.head=scene
	local head={name=LogicScenesMgr.Adventure.head.name,events=LogicScenesMgr.Adventure.head.events}
	AdvGenerator.mapData.sceneList={head}
end
function AdvGenerator.GenerateMapEvent()
	local safeEvent = {'blackSmith','campfire','potionTable'}
	local event = {door={},event={},story={},isBattle=false,ranSeed=nil}--,ranState=nil

	--event.ranState = _G.rng:getState()
	local newSeed = os.time()
	math.randomseed(newSeed)
	event.ranSeed = newSeed

	-----1st chance-----exit door
	local ran = math.random(1,10)
	if AdvGenerator.mapData.stepFromDoor > 6 and ran < AdvGenerator.mapData.stepFromDoor then
		table.insert(event.door,'door')
	end
	-----2nd chance-----put random safe event
	ran = math.random(1,10)
	if ran > 5 then
		local safe = safeEvent[math.random(#safeEvent)]
		table.insert(event.event,safe)
	end

	-----3rd chance-----decide story or battle or empty
	ran = math.random(1,10)
	if ran > 0 then	
		local ran2 = math.random(1,10)
		if ran2 > 0 then
			----battle
			event.isBattle=true
		end	
		
	else
		---story
		--table.insert(event.story,'event')				
	end

	return event
end
function AdvGenerator.AddNewScene(name,events)
	local name = name or LogicScenesMgr.Adventure.length
	local event = events or AdvGenerator.GenerateMapEvent()

	local AdvScene = require('scene.AdvScene')
	local dataScene = AdvScene.NewDataScene(name,event,AdvGenerator)

	local AdvView = require('view.AdvView')
	local ViewScene = AdvView.NewViewScene(name,event,AdvGenerator)

	LogicScenesMgr:AddScene(LogicScenesMgr.Adventure ,dataScene)
	ViewScenesMgr:AddScene(ViewScenesMgr.Adventure ,ViewScene)	

	table.insert(AdvGenerator.mapData.sceneList,{name=dataScene.name,events=dataScene.events})

end
function AdvGenerator.Check()
	if LogicScenesMgr.Adventure:Contain(LogicScenesMgr.CurrentScene) and LogicScenesMgr.CurrentScene.next == nil then
		--print('Check and Add')
		AdvGenerator.AddNewScene()
	end
end
function AdvGenerator.Save()
	--print('AdvGenerator.Save',AdvGenerator.heroData,#AdvGenerator.heroData)
	local saveData = SaveMgr.CurrentSave
	saveData.ItemList=Item.List
	saveData.Backpack=Item.Backpack
	saveData.MapData = AdvGenerator.mapData
	saveData.CurrentTeamData={}
	saveData.CurrentTeam={}
	--
	for k,v in pairs(AdvGenerator.heroData) do
		--
		table.insert(saveData.CurrentTeam,v.key)
		--
		table.insert(saveData.CurrentTeamData,v.data)
	end
	saveData.CurrentScene=LogicScenesMgr.CurrentScene.name
	return true
		
end
function AdvGenerator.Load()
	local saveData = SaveMgr.CurrentSave
	AdvGenerator:ResetMap()
	AdvGenerator:SetAdvData(saveData)
	AdvGenerator.mapData=saveData.MapData

	Item.List=saveData.ItemList
	Item.Backpack=saveData.Backpack

	local list = TableFunc.Copy(saveData.MapData.sceneList)
	saveData.MapData.sceneList={}
	AdvGenerator.mapData.sceneList={}
	
	for k,v in pairs(list) do
		if type(v.name)=='number' then
			--print('in load list is number')
			AdvGenerator.AddNewScene(v.name ,v.events )
		elseif v.name=='AdvStart' then
			LogicScenesMgr:AddScene(LogicScenesMgr.Adventure  ,AdvGenerator.originHead)
		end
	end

	local nextScene = LogicScenesMgr.Adventure:MoveTo(saveData.CurrentScene)
	LogicScenesMgr.CurrentScene.switchingScene = nextScene
	if nextScene.events and  #nextScene.events.door >0 then
		LogicScenesMgr.Adventure.head=nextScene
	end
end
return AdvGenerator