local Scene = require('lib.scene')
local SaveMgr=require('lib.saveManager')
local Battle = require('battle.battle')
local AdvData = require('adv_map.AdvData')

local AdvMainScene ={}

function AdvMainScene.NewDataScene(adv_data ,save_func)
	local scene = Scene.new('AdvStart')
	scene.adv_data = adv_data
	local function switchScene(...)
		local arg ={...}
		if #arg > 1 then
			local x,y = arg[2],arg[3]
			print('go to room ',x,y)
			scene.adv_data.player_pos[1]=x  
			scene.adv_data.player_pos[2]=y
			--scene.adv_data.
		else
			scene.switchingScene=name
		end
	end
	scene.funcTab = {
		switchScene=switchScene
	}
	function scene.Enter()
		print('Adv DataScene enter')
		local adv_data = scene.adv_data

		local x,y = adv_data.player_pos[1] , adv_data.player_pos[2]

		scene.Current_Room = adv_data.map[x][y]
		print('data current room',x,y)

		--[[for k,v in pairs(scene.Current_Room) do
			print(k,v)
		end]]
		--scene.Change_Room(current_room)
		if scene.Current_Room.type=='battle' then
			scene.Current_Room.battle=Battle.new(scene)
			Battle.InitBattleData(scene.battle ,scene)
		end	
		SaveMgr.Save(save_func ,scene)
	end
	function scene.Update(dt)

		scene:FromCtrl()
		scene:DataPending()
	end
	return scene
end


return AdvMainScene