local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')

local function Check(key)
	if tonumber(key) and tonumber(key) < 10 then
		return tonumber(key)
	elseif tostring(key) then
		return tostring(key)
	end
	return false
end

local Keyboard={}
function Keyboard.new()
	local read = State.new('read')
	local gamestate = State.new("gamestate")
	local stopRead = State.new("stopRead")
	local keyboard=Machine.new({
		initial=stopRead,
		states={read  ,gamestate,stopRead},
		events={  					
			{state=read,global=true,self=true},
			{state=stopRead,to='read'},
			{state=stopRead,to='stopRead'},
			{state=gamestate,global=true,self=true}
		},	
	})

	read.DoOnEnter=function ( self ,Control ,GameMachine)
		--print('wait input')
		local key=string.lower(io.read())
		local check = Check(key)	
		if check then
			if check =='end' then
				keyboard:TransitionTo('gamestate')
				return
			end
			for k,v in pairs(Control.keyMap) do
				if check == v.key  or v.key == 'any' then				
					--Control.CurrentScene.ButtonEvent:Emit(v.buttonName ,check ,table.unpack(v.arg))
					Control.ButtonEvent:Emit(v.buttonName ,check ,table.unpack(v.arg))
					keyboard:TransitionTo('stopRead')
					return
				end 
			end

			print('無效按鍵',check )
			keyboard:TransitionTo('read',Control, GameMachine)
		else
			print('無效按鍵')
			keyboard:TransitionTo('read',Control, GameMachine)
		end
	end

	stopRead.Do=function ( self ,Control, GameMachine)
	end

	gamestate.DoOnEnter=function(self ,Control, GameMachine)
		_G.GameMachine.stop=true
	end

	return keyboard
end

return Keyboard
