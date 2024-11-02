--Mouse = _G.Mouse
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local TableFunc = require('lib.TableFunc')
local CallBack = require("lib.callback")

local function Enter(...)
end
local function Update(...)
end
local function Exit(...)
end

--[[local MouseAct = {}
function MouseAct.new()
	local WithDrag = State.new("WithDrag")
	local SelectTo = State.new("SelectTo")
	local machine= Machine.new({
		initial=WithDrag,
		states={WithDrag ,SelectTo},
		events={
			{state=WithDrag,to='SelectTo'},
			{state=SelectTo,to='WithDrag'}
		}
	})
	WithDrag.Do = function(self,scene,choose,...)
		local mx , my = Mouse.mx , Mouse.my
		local len = #choose
		local currentChoose = choose[len]

		if #scene.CheckRange>0 then
			for k,v in pairs(scene.CheckRange[#scene.CheckRange]) do
				if Mouse.current.name == 'OnClick' then
					if v:Check(mx,my) and v.isLock==false  then
						v:OnClick(currentChoose,...)
					end

				elseif Mouse.current.name == 'OnHold' then
					if v:Check(mx,my) and v.isLock==false    then
						v:OnHold(currentChoose,...)
					end
					if len >0 and #currentChoose.choose >0 then
						currentChoose:OnHold(mx,my,...)
					end

				elseif Mouse.current.name == 'OnRelease' then
					if v:Check(mx,my) and v.isLock==false  then
						v:OnRelease(currentChoose,...)
					end
					if len >0 and #currentChoose.choose >0 then
						currentChoose:OnRelease(...)
					end
				end
			end
		end
	end
	SelectTo.Do = function(self,scene,choose,...)
		local mx , my = Mouse.mx , Mouse.my
		local len = #choose
		local currentChoose = choose[len]

		if #scene.CheckRange>0 then
			for k,v in pairs(scene.CheckRange[#scene.CheckRange]) do
				if Mouse.current.name == 'OnClick' then
					if v:Check(mx,my) and v.isLock==false  then
						v:OnClick(currentChoose,...)
					end

				elseif Mouse.current.name == 'OnHold' then
					if v:Check(mx,my) and v.isLock==false    then
						v:OnHold(currentChoose,...)
					end

				elseif Mouse.current.name == 'OnRelease' then
					if v:Check(mx,my) and v.isLock==false  then
						v:OnRelease(currentChoose,...)
					end
				end
			end
		end
	end
	return machine
end

local function PlayAltas( self,dt )
	for k,label in pairs(self.Altas) do --animation
		for i,v in pairs(label) do
			v.sprite:Play(dt)
			v.sprite.quad:setViewScenesport(
				v.sprite.animations[ v.sprite.currentAnim ].x ,
				v.sprite.animations[ v.sprite.currentAnim ].y ,
				v.sprite.animations[ v.sprite.currentAnim ].w ,
				v.sprite.animations[ v.sprite.currentAnim ].h )
		end
	end
end
local function Clear(scene)
	scene.Drawable={}
	scene.AllLabels={}
	scene.CheckRange={}
	scene.Altas={}
end

]]

local function InsertResult(scene, result)
	--TableFunc.Dump(result)
	if type(result) ~= 'boolean' and result.toView then
		TableFunc.Push(scene.toView, result.toView)
		print('InsertResult', scene, #scene.toView, scene.toView, result.toView.key)
		--TableFunc.Dump(scene.toView)
	end
	if type(result) ~= 'boolean' and result.toBattleView then
		--TableFunc.Dump(result.toSceneBattleView)
		TableFunc.Push(scene.toSceneBattleView, result.toBattleView)
		print('InsertResult toBattleView', result.toBattleView.key)
	end
	if type(result) ~= 'boolean' and result.toPending then
		--print('Push toPending')
		TableFunc.Push(scene.pending, result.toPending)
	end
end
local function DataPending(scene)
	if #scene.pending > 0 then
		--print('data pending > 0')
		for i = #scene.pending, 1, -1 do
			local command = TableFunc.Shift(scene.pending)

			local result = scene.funcTab[command.key](table.unpack(command.arg))

			if result then
				--print('data pending ', command.key)
				InsertResult(scene, result)
			end
		end
	end
	if #scene.pending == 0 and scene.Current_Room and scene.Current_Room.battle then
		for i = #scene.Current_Room.battle.pending, 1, -1 do
			local command = TableFunc.Shift(scene.Current_Room.battle.pending)
			--print('data battle pending ',command.key)	
			assert(scene.Current_Room.battle.func_tab[command.key], "Data Pending " .. command.key .. " not exist")
			local result = scene.Current_Room.battle.func_tab[command.key](table.unpack(command.arg))

			if result then
				InsertResult(scene, result)
			end
		end
	end
	--print('Data Pending', scene.toView, #scene.toView)
	--[[if scene.battle then
		scene.battle:Update(scene)						
	end]]
end
local function FromCtrl(scene) --執行button
	--轉交至battle內處理的判定
	for i = #scene.pending, 1, -1 do
		local command = scene.pending[i]
		if not scene.funcTab[command.key] then
			--print('transfer ctrl cmd')
			--TableFunc.Dump(command)
			--battle, input_machine做為參數傳入
			TableFunc.Unshift(command.arg, scene.Current_Room.battle.input_machine)
			TableFunc.Unshift(command.arg, scene.Current_Room.battle)

			TableFunc.Unshift(scene.Current_Room.battle.pending, command)
			table.remove(scene.pending, i)
		end
	end
	--print('FromCtrl', scene.toView, #scene.toView)
end

local function ViewPending(scene)
	if #scene.pending > 0 then
		--print('View Scene Pending')
		--TableFunc.Dump(scene.pending)
		for i = #scene.pending, 1, -1 do
			local v = TableFunc.Pop(scene.pending) --scene.pending[i]
			local key = v.key
			local arg = v.arg
			print('view scene pending', key)
			--TableFunc.Dump(arg)
			local result = scene.drawCommand[key](scene, table.unpack(arg)) --注意drawCommand 是否有return
		end
	elseif #scene.pending == 0 and scene.Current_Room and scene.Current_Room.BattleRoundMachineView then
		local pending = scene.Current_Room.BattleRoundMachineView.pending
		--print('View Battle Pending')
		--TableFunc.Dump(pending)
		for i = #pending, 1, -1 do
			local v = TableFunc.Pop(pending) --scene.pending[i]
			local key = v.key
			local arg = v.arg
			--print('view scene pending', key)
			--TableFunc.Dump(arg)
			local result = scene.Current_Room.BattleRoundMachineView.drawCommand[key](scene, table.unpack(arg))
		end
	end
end
local function FromData(scene, dataScene) --view scene使用
	print('FromData', dataScene, #dataScene.toView, dataScene.toView)
	--TableFunc.Dump(dataScene.toView)

	for i = 1, #dataScene.toView do
		--print(#dataScene.toView)
		local v = TableFunc.Shift(dataScene.toView)
		--print('get from data ')
		--TableFunc.Dump(v)

		TableFunc.Push(scene.pending, v)
	end

	--[[if scene.Current_Room and scene.Current_Room.BattleRoundMachineView then
		for i = 1, #dataScene.toBattleView do
			--print(#dataScene.toView)
			local v = TableFunc.Shift(dataScene.toBattleView)
			--print('get from data ')
			--TableFunc.Dump(v)
			local pending = scene.Current_Room.BattleRoundMachineView.pending
			TableFunc.Push(pending, v)
		end
	end]]
	--[[if scene.Current_Room and scene.Current_Room.BattleRoundMachineView then
		if #dataScene.toSceneBattleView > 0 then print('have data to view', #dataScene.toSceneBattleView) end
		for i = 1, #dataScene.toSceneBattleView do
			print('get from data battle', #dataScene.toSceneBattleView)
			local v = TableFunc.Pop(dataScene.toSceneBattleView)
			TableFunc.Dump(v)
			TableFunc.Unshift(scene.Current_Room.BattleRoundMachineView.pending, v)
		end
	end]]
end


local Scene = {}
Scene.default = {
	events = { door = {}, eventImg = {}, eventButton = {}, isBattle = false, ranState = nil, ranSeed = nil },
	ViewPending = ViewPending,
	DataPending = DataPending,
	FromData = FromData,
	FromCtrl = FromCtrl,
	InsertResult = InsertResult,
	Enter = Enter,
	Update = Update,
	Exit = Exit
} --,MouseAct=MouseAct.new()



Scene.metatable = {}
function Scene.new(name)
	local o = {
		battle = nil,
		pending = {},
		toView = {},
		Event = CallBack.new(),
		ButtonEvent = CallBack.new(),
		name =
			name
	}
	setmetatable(o, Scene.metatable)
	return o
end

Scene.metatable.__index = function(table, key) return Scene.default[key] end

return Scene
