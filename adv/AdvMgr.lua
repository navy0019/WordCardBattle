local LogicScenesMgr = require('LogicScenesMgr')
local ViewScenesMgr = require('ViewScenesMgr')

local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr = require('lib.saveManager')
local Item = require('adv.Item')
local AdvData = require('adv.AdvData')

local CharacterAssets = require('resource.characterAssets')

local AdvMgr = {}

function AdvMgr:ResetHeroData(...)
	for k, v in pairs(AdvData.heroData) do
		local key = v.key
		v.data = {}
		local originData = TableFunc.DeepCopy(_G.Resource.character[key])
		v.data = TableFunc.DeepCopy(originData)
		v.state = { round_start = {}, round_end = {}, every_card = {} }
	end
end

function AdvMgr.Save(scene)
	local advData            = scene.adv_data
	local saveData           = SaveMgr.CurrentSave

	saveData.map_data        = advData.map_data
	saveData.map_setting     = advData.map_setting

	saveData.CurrentTeamData = {}
	saveData.CurrentTeam     = {}
	for k, v in pairs(advData.heroData) do
		TableFunc.Push(saveData.CurrentTeam, v.key)
		TableFunc.Push(saveData.CurrentTeamData, {})
		local current = saveData.CurrentTeamData[k]
		TableFunc.Push(current, v.data)
	end

	saveData.rooms = {}
	print('Save room', #advData.rooms)
	for k, room in pairs(advData.rooms) do
		TableFunc.Push(saveData.rooms, { event = room.event, explore = room.explore, battle = room.battle })
	end

	saveData.CurrentScene = advData.player_pos
end

function AdvMgr.Load(...)
	local saveData = SaveMgr.CurrentSave

	local setting = saveData.map_setting
	local seed = setting.map_seed
	--adv_data=AdvData.Generate_Dungeon(setting ,seed)

	AdvMgr.NewScene(setting, seed)
	local adv_data = LogicScenesMgr.NormalScene['AdvStart'].adv_data
	adv_data.map_data = saveData.map_data

	local save_rooms = saveData.rooms
	--print('Load room',#save_rooms ,#adv_data.rooms)
	for k, room in pairs(adv_data.rooms) do
		room.event = save_rooms[k].event
		room.battle = save_rooms[k].battle
		room.explore = save_rooms[k].explore
	end
	adv_data.player_pos = saveData.CurrentScene
end

function AdvMgr.NewScene(setting, seed)
	--print('AdvMgr NewScene',seed)
	local adv_data = AdvData.Generate_Dungeon(setting, seed)

	local AdvScene = require('scene.AdvMainScene')
	local DataScene = AdvScene.NewDataScene(adv_data, AdvMgr.Save)

	local AdvView = require('view.AdvMainView')
	local ViewScene = AdvView.NewViewScene(adv_data)

	LogicScenesMgr:AddScene(LogicScenesMgr.NormalScene, DataScene)
	ViewScenesMgr:AddScene(ViewScenesMgr.NormalScene, ViewScene)

	--TableFunc.Push(AdvMgr.mapData.sceneList,{name=dataScene.name,events=dataScene.events})
end

return AdvMgr
