local Scene = require('lib.scene')
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local CallBack = require("lib.callback")
local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")
local LogicScenesMgr = require('LogicScenesMgr')
local Show = require('show')
local Msg = require('resource.Msg')

local scene = Scene.new('Start')

scene.Event:Register('AddButton',function(name) end) -- print('scene try to add button')
scene.Event:Register('WaitIoRead',function() end)--scene.Machine.waitIoRead=true
scene.Event:Register('RemoveButton',function(name)
		scene.ButtonEvent:RemoveRegister(name)
	end)

function scene.Enter()
	--print('Menu scene Enter ')
	local Empty = State.new("Empty")
	local Wait = State.new("Wait")

	local ChooseSave = State.new("ChooseSave")
	scene.Machine = Machine.new({
		initial=Empty,
		states={
			Empty , Wait, ChooseSave 
		},
		events={
			{state=Empty,to='Wait'},
			{state=Wait,to='ChooseSave'},
			{state=ChooseSave,to='ChooseSave'},
			{state=ChooseSave,to='Empty'}
		}
	})
	scene.Machine.waitIoRead=true
	Wait.DoOnEnter=function()
		print('按任意鍵繼續')
		scene.Event:Emit('AddButton','pressAnyButton','any')
		scene.ButtonEvent:Register('pressAnyButton',function(num) scene.Event:Emit('RemoveButton','pressAnyButton') scene.Machine:TransitionTo('ChooseSave')  end)

		--[[for k,v in pairs(scene.ButtonEvent) do
			print(k,v)
		end]]
		scene.Event:Emit('WaitIoRead')
	end
	Wait.DoOnLeave=function()
		scene.Event:Emit('WaitIoRead')
	end

	ChooseSave.DoOnEnter=function()
		print('選擇存擋')
		ChooseSave.SaveData={}
		for k,v in pairs(SaveMgr.SaveData) do
			ChooseSave.SaveData[k]=v
		end
		Show.PrintSaveData(ChooseSave.SaveData)
		
		
		scene.Event:Emit('AddButton','saveData_1',1 ,'selectSave')
		scene.ButtonEvent:Register('saveData_1',function(...)end)

		scene.Event:Emit('AddButton','saveData_2',2 ,'selectSave')
		scene.ButtonEvent:Register('saveData_2',function(...)  end)
		

		for k,v in pairs(SaveMgr.SaveData) do
			if v~='Empty' then
				scene.ButtonEvent:Register('askButton'..k+2 ,
					function(...)
						scene.Event:Emit('RemoveButton','askButton'..k+2)
						scene.Event:Emit('RemoveButton','saveData_1')
						scene.Event:Emit('RemoveButton','saveData_2')	
						print('確認刪除? '..k+2 ..'確認 '..k+3 ..'取消')

						scene.ButtonEvent:Register('deleteButton'..k+2 ,function(...) scene.Event:Emit('WaitIoRead')  end)
						scene.Event:Emit('AddButton','deleteButton'..k+2 ,k+2 ,'deleteSave',k+2)

						scene.ButtonEvent:Register('cancelButton'..k+3 ,function(...) scene.Machine:TransitionTo('ChooseSave') scene.Event:Emit('WaitIoRead')  end)
						scene.Event:Emit('AddButton','cancelButton'..k+3 ,k+3)
						scene.Event:Emit('WaitIoRead')
					end)
				scene.Event:Emit('AddButton','askButton'..k+2 ,k+2)
				--scene.ButtonEvent:Register('deleteButton'..k+2 ,function(...) scene.Event:Emit('WaitIoRead')  end)
				--scene.Event:Emit('AddButton','deleteButton'..k+2 ,k+2 ,'deleteSave')
			end
		end
		--[[for k,v in pairs(scene.ButtonEvent) do
			print(k,v)
		end]]
		
	end
	ChooseSave.Do=function()
		for k,v in pairs(ChooseSave.SaveData) do
			if v~= SaveMgr.SaveData[k] then
				ChooseSave.SaveData[k]=SaveMgr.SaveData[k]
				--print('diff reload')			
				scene.Machine:TransitionTo('ChooseSave')
				return
			end
		end
		
	end
	ChooseSave.DoOnLeave=function()
		local remove = {}
		for k,v in pairs(scene.ButtonEvent) do
			TableFunc.Push(remove,k)
		end
		for k,v in pairs(remove) do
			--scene.ButtonEvent:RemoveRegister(v)
			scene.Event:Emit('RemoveButton',v)			
		end

	end

	scene.Machine:TransitionTo('Wait')

end

function scene.Exit()
	scene.ButtonEvent:RemoveAll()
	scene.Event:ClearAll()
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