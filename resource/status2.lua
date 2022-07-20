local TableFunc = require('lib.TableFunc')

local stateAsset = {}

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


return stateHandle