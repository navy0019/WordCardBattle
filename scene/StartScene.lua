local Scene = require('lib.scene')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")
local AdvMgr = require('adv.AdvMgr')

local scene = Scene.new('Start')

local function selectSave( num )
	if SaveMgr.SaveData[num] ~='Empty' then
		SaveMgr.CurrentSave = SaveMgr.SaveData[num]
		scene.switchingScene = SaveMgr.CurrentSave.CurrentScene
		if type(scene.switchingScene)=='table' then
			--print('AdvGenerator load')			
			AdvMgr.Load()
			scene.switchingScene = 'AdvStart'
		end
		--print('load savedata '..num , SaveMgr.CurrentSave.CurrentScene)
		--TableFunc.Dump(SaveMgr.CurrentSave)
	else
		local data = SaveMgr.NewSaveFile(num)
		print('NewSaveFile')
		SaveMgr.SaveData[num]=data
		SaveMgr.CurrentSave=data
		SaveMgr.Save(data)
		scene.switchingScene = data.CurrentScene
	end
	return true
end
local function deleteSave( num )--按鍵輸入的數字-2才是真正的存擋位置
	SaveMgr.DeleteSaveFile(num-2)
	SaveMgr.SaveData[num-2]='Empty'
	return true
end

scene.funcTab = {
	selectSave=selectSave,
	deleteSave=deleteSave,
	--errorMsg=errorMsg
}
function scene.Enter()
	SaveMgr.LoadFileList()
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