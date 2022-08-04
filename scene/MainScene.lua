local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local TableFunc = require('lib.TableFunc')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')

local scene = Scene.new('Main')

local function switchScene(...)
	local arg = {...}
	local name = arg[2]
	--print('arg' ,arg[1])
	scene.switchingScene=name
	return true
end
scene.funcTab = {
	switchScene=switchScene
}
function scene.Enter(win_width,win_height)
	--print('main scene')
	local saveData = SaveMgr.CurrentSave
	saveData.CurrentScene = 'Main'
	--TableFunc.Dump(saveData)
	SaveMgr.Save(saveData)
end
function scene.Exit()

end
function scene.Update(dt)
	scene:FromCtrl()
	scene:DataPending()
end
function scene.debugDraw()
end
return scene