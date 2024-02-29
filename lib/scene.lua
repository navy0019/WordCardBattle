--Mouse = _G.Mouse
local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local TableFunc = require('lib.TableFunc')
local CallBack = require("lib.callback")

local function Enter( ... )
end
local function Update( ... )
end
local function Exit( ... )
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

local function InsertResult(s , result )
	--TableFunc.Dump(result)
	if type(result)~='boolean' and result.toViewScene then
		--TableFunc.Dump(result.toViewScene)
		--print('Unshift')
		TableFunc.Unshift(s.toViewScene , result.toViewScene)
	end
	if type(result)~='boolean' and result.toPending then
		--print('Push toPending')
		TableFunc.Push(s.pending , result.toPending)
	end
	return true
end
local function DataPending(scene)
	local funcTab = scene.battle and scene.battle.machine.funcTab or scene.funcTab
	local self_pending = scene.battle and scene.battle.machine.pending or scene.pending

	if #self_pending > 0 then
		local command = TableFunc.Shift(self_pending)
		--print('data pending ',command.key)	
		local result = funcTab[command.key](table.unpack(command.arg))

		if result then
			local s = scene.battle and scene.battle.machine or scene
			InsertResult(s , result)
		end
	end
	if scene.battle then
		scene.battle:Update(scene)						
	end
end
local function FromCtrl(scene)--執行button
	local self_pending = not scene.battle and  scene.pending or scene.battle.pending --scene.battle.machine.pending 

	--有battle的話 轉交至battle內處理
	if #scene.pending >0 and scene.battle then
		for i=#scene.pending,1,-1 do
			local command = TableFunc.Shift(scene.pending)
			TableFunc.Unshift(command.arg,scene.battle)
			TableFunc.Push(self_pending,command) 
		end
	end


end

local function ViewPending(scene)
	local funcTab = scene.battle and scene.BattleMachineView.drawCommand or scene.drawCommand
	local self_pending = scene.battle and scene.BattleMachineView.pending or scene.pending
	for i=#self_pending, 1 ,-1 do
		local v = self_pending[i]
		assert(v ,'error '..i..'  '..#self_pending..'   '..tostring(v))

		local key = v.key
		local arg = v.arg
		local viewState = v.viewState or false
		assert(funcTab[key],'don\'t have drawCommand '..key)

		local result =funcTab[key](scene,table.unpack(arg))--注意drawCommand 是否有return true
			TableFunc.Pop(self_pending)		

	end
end
local function FromLogic(scene, dataScene)--view scene使用
	local from_data= scene.battle and dataScene.battle.machine.toViewScene or dataScene.toViewScene
	local self_pending = scene.battle and scene.BattleMachineView.pending or scene.pending
	if #from_data > 0 then

		for i=#from_data ,1 ,-1  do
			local v = TableFunc.Pop(from_data)	
			TableFunc.Unshift(self_pending ,v)--.command
		end

	end
end


local Scene={}
Scene.default={events={door={},eventImg={},eventButton={},isBattle=false,ranState=nil,ranSeed=nil},
				ViewPending=ViewPending,DataPending=DataPending,FromLogic=FromLogic,FromCtrl=FromCtrl,InsertResult=InsertResult,
				Enter=Enter,Update=Update,Exit=Exit}--,MouseAct=MouseAct.new()



Scene.metatable={}
function Scene.new(name)
	local o={battle=nil,toViewScene={},pending={},Event=CallBack.new(),ButtonEvent=CallBack.new(),name=name}
	setmetatable(o,Scene.metatable)
	return o
end
Scene.metatable.__index=function (table,key) return Scene.default[key] end

return Scene