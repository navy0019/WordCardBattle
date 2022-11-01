local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local TableFunc = require("lib.TableFunc")
local TeamData = require('lib.teamData')
local LogicScenesMgr = require('LogicScenesMgr')
local Show = require('show')

local scene = Scene.new('Team')

scene.drawCommand={
	WaitIoRead=function(scene,...)
		local str = ...
		if str then
			local s=''
			if type(str)=='table' then
				for i=2,#str,2 do
				 	s=s..str[i]
				end
			else
				s=str 
			end
			print('waitIO msg ',s)
		end
		scene.Event:Emit('WaitIoRead')
		return true
	end
}
local function PrintTeamData(TeamData)

	w ='\n當前隊伍:'

	for i=1,4 do
		local hero = TeamData.CurrentTeam[i]
		if hero then
			w=w..hero..', '
		else
			w=w..'empty, '
		end
	end
	w=w..'\n\n'

	w=w..'預設隊伍: '..TeamData.CurrentDeafault..'\n'
	for i=1,3 do
		w=w..'預設 '..i..' : '
		for j=1,4 do
			local hero = TeamData.DefaultTeam[i][j]
			if hero then
				w=w..hero..' , '
			end
		end
		w=w..'  '
	end
	w=w..'\n\n'
	for i=1,6 do
		local hero = TeamData.AllHeros[i]
		w=w..hero.name
		if hero.selected then
			w=w..'(已選擇), '
		else
			w=w..' , '
		end
	end
	w=w..'\n\n\n'
	print(w)
end
local function MakeBasicEvent( )
	scene.Event:Register('AddButton',function() end) -- print('scene try to add button')
	scene.Event:Register('WaitIoRead',function() scene.Machine.waitIoRead=true	end)

	scene.Event:Register('RemoveButton',function(name)
			--print('scene try to remove '..name)
			scene.ButtonEvent:RemoveRegister(name)
	end)
end
MakeBasicEvent()

function scene.Enter()
	--print('Scenes team')
	local Empty = State.new("Empty")
	local MakeTeam = State.new("MakeTeam")

	scene.Machine = Machine.new({
		initial=Empty,
		states={
			Empty  ,MakeTeam
		},
		events={
			{state=Empty,to='MakeTeam'},
			{state=MakeTeam,to='Empty'},
			{state=MakeTeam,to='MakeTeam'}
		}
	})

	MakeTeam.DoOnEnter=function()
	print('DoOnEnter')
		local LogicScenesMgr= LogicScenesMgr.CurrentScene
		MakeTeam.CurrentTeam=TableFunc.DeepCopy(TeamData.CurrentTeam)

		local num = TeamData.CurrentDeafault
		MakeTeam.DefaultTeam=TableFunc.DeepCopy(TeamData.DefaultTeam[num])
		print('1~6:切換角色 d1~3:切換預設隊伍  s:儲存預設隊伍 r:切回預設隊伍 b:返回主頁面')

		PrintTeamData(TeamData)
		for i=1,6 do
			scene.ButtonEvent:Register('hero'..i ,function(...) scene.Event:Emit('WaitIoRead') end)-- print('switch '..i)
			scene.Event:Emit('AddButton','hero'..i ,i ,'switchHero')
		end
		for i=1,3 do
			scene.ButtonEvent:Register('default'..i ,function(...)  scene.Event:Emit('WaitIoRead') end)--print('default '..i)
			scene.Event:Emit('AddButton','default'..i ,'d'..i ,'switchDefault')
		end
		scene.ButtonEvent:Register('saveButton' ,function(...) print('儲存隊伍') scene.Event:Emit('WaitIoRead') end)
		scene.Event:Emit('AddButton','saveButton' ,'s' ,'saveTeamToDefault')

		scene.ButtonEvent:Register('resetButton' ,function(...) scene.Event:Emit('WaitIoRead') end)
		scene.Event:Emit('AddButton','resetButton' ,'r' ,'resetTeam')

		scene.ButtonEvent:Register('backButton' ,function(...)   end)
		scene.Event:Emit('AddButton','backButton' ,'b' ,'back')

		scene.Event:Emit('WaitIoRead')
	end

	MakeTeam.Do=function()
		--print('Do')
		local num = TeamData.CurrentDeafault
		for i=1,4 do
			local copy = MakeTeam.CurrentTeam[i]
			local hero = TeamData.CurrentTeam[i]

			local copyDeafault = MakeTeam.DefaultTeam[i]
			local currentDeafault = TeamData.DefaultTeam[num][i]
			if copy ~= hero or copyDeafault ~= currentDeafault then
				--print('diff ',copy,hero)
				--print(copyDeafault,currentDeafault)
				MakeTeam.CurrentTeam[i] = TeamData.CurrentTeam[i]
				MakeTeam.DefaultTeam[i] = TeamData.DefaultTeam[num][i]
				PrintTeamData(TeamData)
				--scene.Machine:TransitionTo('MakeTeam')
				return
			end
		end

	end
	MakeTeam.DoOnLeave=function()
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			TableFunc.Push(remove,k)
		end
		for k,v in pairs(remove) do
			scene.Event:Emit('RemoveButton',v)			
		end
	end
	scene.Machine:TransitionTo('MakeTeam')

end

function scene.Exit()
	scene.ButtonEvent:RemoveAll()
	scene.Event:ClearAll()
	MakeBasicEvent()
end
function scene.Update(dt)
	local dataScene = LogicScenesMgr.CurrentScene
	scene:FromLogic(dataScene)
	scene:ViewPending()
	scene.Machine:Update()

end
function scene.debugDraw()
end
return scene