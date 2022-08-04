local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')

--local MapData = require('lib.MapData')
local AdvGenerator = require('lib.AdvGenerator')

local scene = Scene.new('AdvStart')
scene.next=nil
scene.previous=nil
AdvGenerator.originHead = scene

local function switchScene(...)
	--print('AdvStart switch to '..name)
	local arg = {...}
	local name = arg[2]
	if name == 'previous' then
		AdvGenerator:ResetMap()
		scene.switchingScene = 'Main'
		AdvGenerator.Save()
	else
		--print('Adv switch scene ',name,scene[name])
		scene.switchingScene=scene[name]
		AdvGenerator.mapData.stepFromDoor=AdvGenerator.mapData.stepFromDoor+1
	end
	return true
end
scene.funcTab = {
	switchScene=switchScene
}
function scene.Enter()
	AdvGenerator:SetAdvData( SaveMgr.CurrentSave)
	SaveMgr.Save(SaveMgr.CurrentSave  ,AdvGenerator.Save)
	print('Adv Start Logic Scene')
end
function scene.Exit()
	--scene.Clear(scene)
end
function scene.Update(dt)
	--print('AdvStart Data Update')
	AdvGenerator.Check()
	scene:FromCtrl()
	scene:DataPending()
end
function scene.debugDraw()

end
return scene