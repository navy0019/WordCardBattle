
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local Scene = require('lib.scene')
local SaveMgr=require('lib.saveManager')
local Battle = require('battle.battle')
local Dungeon_Rule = require('adv.Dungeon_Rule')

local AdvMainScene ={}

function AdvMainScene.NewDataScene(adv_data ,save_func)
	local scene = Scene.new('AdvStart')
	scene.adv_data = adv_data
	local function switchScene(...)
		local arg ={...}
		if #arg > 1 then
			local x,y = arg[2],arg[3]
			scene.adv_data.player_pos[1]=scene.adv_data.player_pos[1]+x  
			scene.adv_data.player_pos[2]=scene.adv_data.player_pos[2]+y
			scene.adv_data.map_data.passed_room = scene.adv_data.map_data.passed_room +1
			Dungeon_Rule:Check_Level(adv_data.map_data)
			scene.Machine:TransitionTo('Wait') 
			return {toViewScene={key='ChangeRoom' ,arg={}} }
		else
			scene.switchingScene=name
		end
		--print('have save ',save_func)
		SaveMgr.Save(save_func ,scene)
	end
	scene.funcTab = {
		switchScene=switchScene
	}
	function scene.Enter() 
		--print('Adv DataScene enter')

		local Wait = State.new("Wait")
		local EmptyRoom = State.new("EmptyRoom")
		local EventRoom = State.new("EventRoom")
		local BattleRoom = State.new("BattleRoom")

		scene.Machine = Machine.new(
		{
			initial=Wait,
			states={
				EmptyRoom  ,BattleRoom ,EventRoom ,Wait
			},
			events={
				{state=EmptyRoom, global=true},
				{state=BattleRoom, global=true},
				{state=EventRoom, global=true},
				{state=Wait,global=true}
			}
		}
		
		)

		Wait.Do=function()
			--print('ADV ViewScene enter ')
			
			local adv_data = scene.adv_data
			local map = adv_data.map
			local x,y = adv_data.player_pos[1] , adv_data.player_pos[2]

			scene.Current_Room = adv_data.map[x][y]
			print('data current room',x,y)
					
			if scene.Current_Room.event~='empty' then
				if scene.Current_Room.event =='enter' then
					scene.Machine:TransitionTo('EmptyRoom')

				else
					print('data have event')
					scene.Machine:TransitionTo('EventRoom')

				end
			elseif 	scene.Current_Room.battle then
				--scene.battle = 	scene.Current_Room.battle	
				print('data have battle')
				scene.Machine:TransitionTo('BattleRoom')
			else
				scene.Machine:TransitionTo('EmptyRoom')
			end
			--scene.Event:Emit('WaitIoRead')
		end
		EventRoom.DoOnEnter=function()
			print('EventRoom Data')

		end

		BattleRoom.DoOnEnter=function()
			print('BattleRoom Data')
			scene.Current_Room.battle=Battle.new(scene)
			Battle.InitBattleData(scene.Current_Room.battle ,scene)
		end
		BattleRoom.Do=function()
			scene.Current_Room.battle:Update()

		end
		EmptyRoom.DoOnEnter=function()
			print('EmptyRoom Data')
	
		end

		--[[if scene.Current_Room.type=='battle' then
			scene.Current_Room.battle=Battle.new(scene)
			Battle.InitBattleData(scene.battle ,scene)
		end	]]
		SaveMgr.Save(save_func ,scene)
	end
	function scene.Update(dt)
		--print('DATA')
		scene:FromCtrl()
		scene:DataPending()
		scene.Machine:Update()
	end
	return scene
end


return AdvMainScene