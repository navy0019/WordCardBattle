local Keyboard  = require('Keyboard')
local CallBack = require("lib.callback")
local TableFunc = require("lib.TableFunc")

--[[
ViewScenesMgrEvent{ Enter ,Exit }  Exit:清空全部 Enter:跟CurrentScene做連接 (在換場景時觸發這兩個)
Event{ WaitIoRead ,RemoveButton ,AddButton} CurrentScene透過 AddButton RemoveButton 增減Button 當CurrentScene增減Button時 Control也會同步改變
ButtonEvent{ 場景所有button }
button:{function,function....} 
]]
local Control={WaitIoRead=false,Keyboard=Keyboard.new(),keyMap={},ViewScenesMgrEvent=CallBack.new(),Event=CallBack.new(),ButtonEvent=CallBack.new()}
function Control.MakeBasicEvent(ViewScenesMgr,LogicScenesMgr)
	local CurrentSceneEvent = ViewScenesMgr.CurrentScene.Event
	local CurrentViewScenesMgrButton = ViewScenesMgr.CurrentScene.ButtonEvent

	Control.Event:Attach(CurrentSceneEvent,'WaitIoRead',function() Control.WaitIoRead=true end)

	Control.Event:Attach(CurrentSceneEvent,'RemoveButton',
		function(name)
				Control.ButtonEvent:RemoveRegister(name)
				local p = TableFunc.Find(Control.keyMap,name,'buttonName') 
				table.remove(Control.keyMap,p)
		end)

	--[[AddButton: 增加的 button 哪個按鍵按下後對應哪個function name 
		key 對應特定的輸入 or 按任意鍵		
		是否要傳給LogicScenesMgr看是否有funcName      
		]]	
	Control.Event:Attach(CurrentSceneEvent,'AddButton',
		function(buttonName,key,funcName,...)
			--print('AddButton ',buttonName,key,funcName)
			if not Control.ButtonEvent[buttonName] then

				TableFunc.Push(Control.keyMap,{key=key,buttonName=buttonName,arg={...}})
				--print('AddButton ',buttonName,key,funcName)
			else
				local p = TableFunc.Find(Control.keyMap ,key ,'key')
				--print('p',p ,key ,funcName)
				local button = Control.keyMap[p]
				for k,v in pairs({...}) do
					TableFunc.Push(button.arg ,v)
				end

			end

			if not Control.ButtonEvent[buttonName] then
				--print('control not have '..buttonName)	
				Control.ButtonEvent:Register(buttonName,
					function(...)
							if funcName then

								TableFunc.Push(LogicScenesMgr.CurrentScene.pending,{key=funcName,arg={...}})
							end
						end)
				CurrentViewScenesMgrButton:Attach(Control.ButtonEvent,buttonName,
						function(...)end
						)
			elseif Control.ButtonEvent[buttonName] then
				--print('control have '..buttonName)	
				Control.ButtonEvent:Register(buttonName,
					function(...)
							if funcName then
								TableFunc.Push(LogicScenesMgr.CurrentScene.pending,{key=funcName,arg={...}})
							end
					end)
			end
	end)

end
function Control.Init( ViewScenesMgr  ,LogicScenesMgr)
	Control.ViewScenesMgrEvent:Attach(ViewScenesMgr.Event,'Enter',function()
		Control.MakeBasicEvent(ViewScenesMgr,LogicScenesMgr)
	end)
	Control.ViewScenesMgrEvent:Attach(ViewScenesMgr.Event,'Exit' ,
		function()
			Control.keyMap={}
			Control.Event:RemoveAll()
			Control.ButtonEvent:RemoveAll()

		end)
end
function Control.KeyPress(GameMachine)
	local Control =GameMachine.Control
	Control.Keyboard:Update(Control ,GameMachine)
	if Control.WaitIoRead then
		Control.WaitIoRead =false
		Control.Keyboard:TransitionTo('read',Control ,GameMachine)
	end

end

return Control