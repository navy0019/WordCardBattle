local TableFunc = require('lib.TableFunc')

local SceneMgr = require('lib.sceneManager')

local stateHandle = {}
local state = {
	poison={
		state={name='poison',value=4,round=4},
		update=function(target,state,battle)
			stateHandle.effect(target,state,battle)
		end,
		effect=function (target,state,battle)
			target:GetHit((state.value)*-1,true,false,battle)

			state.round=state.round-1
			state.value=state.round
		end,
		add=function ( target,state,card  )
			for k,v in pairs(target.data.state.before) do
				if v.name == state.name then
					v.round =v.round+2*(card.level-1)+4
					v.value =v.round
					return 
				end
			end
			local s = TableFunc.Copy(state)
			s.round = 2*(card.level-1)+4
			s.value=s.round
			table.insert(target.data.state.before,s)
		end,
		remove=function(target,state)

		end
	},
	aerolite={
		state={name='aerolite',value=30,round=2},
		update=function(target,state,battle)
			stateHandle.effect(target,state,battle)
		end,
		effect=function (target,state,battle)
			state.round=state.round-1
			if state.round<=0 then
				target:GetHit((state.value)*-1,false,false,battle)
				SceneMgr.CurrentScene.dialog:Enqueue(target.name..'受到'..(state.value)*-1 ..'中毒傷害')
			end

		end,
		add=function ( target,state,card  )
			local s = TableFunc.Copy(state)
			table.insert(target.data.state.after,s)
			SceneMgr.CurrentScene.dialog:Enqueue(target.name..'中毒了')
			
		end,
		remove=function(target,state,battle)

		end
	},
	avoid={
		state={name='avoid',value=0,round=1},
		update=function(target,state,battle)
			state.round=0
		end,
		effect=function (target,state,battle,num)
			local ran = _G.rng:random(1,10)
			if ran <= 5 then
				return true
			else
				target:GetHit((num)*-1,false,true,battle)
			end
			state.round=state.round-1
		end,
		add=function ( target,state,card )
			for k,v in pairs(target.data.state.before) do
				if v.name == state.name then
					v.value =v.value+card.level
					return k
				end
			end
			local s = TableFunc.Copy(state)
			s.value=card.level
			table.insert(target.data.state.before,s)
			
		end,
		remove=function(target,state)

		end
	},
	shield={
		state={name='shield',value=0,round=1},
		update=function(target,state,battle)
			state.round=0
		end,
		effect=function (target,state,battle)
		end,
		add=function ( target,state,num)
			for k,v in pairs(target.data.state.before) do
				if v.name == state.name then
					v.value =v.value+num
					target.data.shield=v.value
					return k
				end
			end
			local s = TableFunc.Copy(state)
			s.value=num
			target.data.shield=s.value+target.originData.shield
			table.insert(target.data.state.before,s)
		end,
		remove=function(target,state)
			target.data.shield =0
		end
	},
	angry={
		state={name='angry',value=1,round=2},
		update=function(target,state,battle,card)
			stateHandle.effect(target,state,battle,card)
		end,
		effect=function (target,state,battle,card)
			if card.type =='atk' then --使用攻擊卡牌才會減少回合
				state.round=state.round-1
				if state.round <= 0 then
					stateHandle.Remove( target,state,target.data.state.always,battle)
				end
			end
		end,
		add=function ( target,state ,card  )
			for k,v in pairs(target.data.state.always) do
				if v.name == state.name then
					
					v.round =v.round+card.level+state.round
					target.data.atk =target.originData.atk+ v.value
					return k
				end
			end

			local s = TableFunc.Copy(state)
			s.round=s.round+card.level
			target.data.atk =target.originData.atk+ s.value
			SceneMgr.CurrentScene.dialog:Enqueue(target.name..'的力量提升'..s.value)
			table.insert(target.data.state.always,s)
			card.battle:CardWordUpdate()
		end,
		remove=function(target,state,battle)
			target.data.atk =target.originData.atk
			battle:CardWordUpdate()
		end
	},
	weak={
		state={name='weak',value=0.6,round=2},
		update=function(target,state,battle)
			state.round=state.round-1
		end,
		effect=function (target,state,battle)
			
		end,
		add=function ( target,state ,card  )
			for k,v in pairs(target.data.state.before) do
				if v.name == state.name then					
					v.round =v.round+card.level+state.round
					target.data.atk =math.floor(target.data.atk* v.value)
					return k
				end
			end

			local s = TableFunc.Copy(state)
			s.round=s.round+card.level
			target.data.atk =math.floor(target.data.atk * s.value)
			table.insert(target.data.state.before,s)
		end,
		remove=function(target,state)
			target.data.atk =math.floor(target.data.atk/state.value) 
		end
	},
	improveShield={
		state={name='improveShield',value=2,round=1},
		update=function(target,state,battle)
			
		end,
		effect=function (target,state,battle)
			state.round=state.round-1
		end,
		add=function ( target,state ,card  )
			for k,v in pairs(target.data.state.before) do
				if v.name == state.name then					
					v.round =v.round+state.round
					return k
				end
			end

			local s = TableFunc.Copy(state)
			table.insert(target.data.state.before,s)
		end,
		remove=function(target,state)

		end
	},
}

function stateHandle.effect(target,state,battle,...)
	local args = {...}
	state[state.name].effect(target,state,battle,table.unpack(args))
end
function stateHandle.Find(target,key,name)
	for k,v in pairs(target.data.state[key]) do
		if v.name == name then
			return k
		end
	end
	return false
end
function stateHandle.Add(target,key,...)
	local args = {...}
	state[key].add(target,state[key].state,table.unpack(args))

end
function stateHandle.Update( target,stateTab,battle ,...)
	local args = {...}
	for i=#stateTab,1,-1 do
		local s = stateTab[i]
		for k,v in pairs(s) do
			print('s' ,k,v)
		end
		if s and s.round>0 then
			state[s.name].update(target, s ,battle,table.unpack(args))
		end
		if s and (s.round <=0 or s.value <=0) then
			local name = s.name
			state[name].remove(target,s,battle,table.unpack(args))
			table.remove(stateTab,i)
		end
	end
end
function stateHandle.Remove( target,state,stateTab,battle ,...)
	local args = {...}
	state[state.name].remove(target,state,battle,table.unpack(args))
	local p=TableFunc.Find(stateTab,state)
	table.remove(stateTab,p)
end
--[[function stateHandle.RemoveAll( target,stateTab,battle ,...)
	local args = {...}
	for i=#stateTab,1,-1 do
		local s = stateTab[i]
		local name = s.name
		state[name].remove(target,s,battle,table.unpack(args))
		table.remove(stateTab,i)
	end
end]]


return stateHandle