local Scene = require('lib.scene')
local SceneMgr = require('lib.sceneManager')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local TableFunc = require("lib.TableFunc")
local TeamData = require('lib.teamData')
local Msg = require('resource.Msg')

local SaveMgr = require('lib.saveManager')

local scene = Scene.new('Team')

local function switchHero(num)
	--已在隊伍內->移除
	local hero = TeamData.AllHeros[num]
	TeamData.Switch(hero)
	return true
end
local function saveTeamToDefault(...)
	local empty = TeamData.CheckEmpty()
	if not empty then
		SaveMgr.Save(SaveMgr.CurrentSave, TeamData.SaveTeam)
	else
		local s = Msg.msg('team_need_save')
		return { toView = { key = 'WaitIoRead', arg = { s } } }
	end
	return true
end
local function resetTeam(...)
	TeamData.ResetTeam()
	return true
end
local function back(...)
	local num = TeamData.CurrentDeafault
	local empty = TeamData.CheckEmpty()
	if not empty then
		SaveMgr.Save(SaveMgr.CurrentSave, TeamData.SaveTeam)
		scene.switchingScene = 'City'
	else
		scene.switchingScene = nil
		local s = Msg.msg('team_need')
		return { toView = { key = 'WaitIoRead', arg = { s } } }
	end
	return true
end
local function switchDefault(key)
	local num = tonumber(string.sub(key, 2))
	TeamData.SwitchDefault(num)
	return true
end
scene.funcTab = {
	--errorMsg=errorMsg,
	switchHero = switchHero,
	saveTeamToDefault = saveTeamToDefault,
	resetTeam = resetTeam,
	back = back,
	switchDefault = switchDefault,
}
function scene.Enter()
	TeamData.init()
end

function scene.Exit()
	scene.Event:RemoveAll()
end

function scene.Update(dt)
	scene:FromCtrl()
	scene:DataPending()
end

function scene.debugDraw()

end

return scene
