local Resource = require('resource.Resource')
local StringAct= require('lib.StringAct')
local StringDecode= require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local StateHandler={}
StateHandler.machine=StringAct.NewMachine()
function StateHandler.Init(battle ,target , key ,parameter)
end
function StateHandler.Remove( battle,character ,timing_tab ,res ,index)
	if res.remove then
		print('res remove')
		local effect = res.remove 
		local toUse={self = res ,target_table=character }
		StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse)
	else
		print('remove')
	end

	table.remove(timing_tab , index)
end
function StateHandler.Update( battle, character ,state ,timing_tab)

	local name = state.name
	local res = TableFunc.DeepCopy(Resource.state[name])
	if res.update then 
		local effect = res.update 
		local toUse={self = state ,target_table=character }
		StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse )
	end

	if state.round and type(state.round )=='number' then
		state.round=state.round -1 
		if state.round <=0 then
			StateHandler.Remove( battle, character ,timing_tab ,res , i)
		end
	end
	--[[local args = {...}
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
	end]]
end
function StateHandler.AddBuff(battle,target,key,parameter)
	for k,v in pairs(target) do
		local state = TableFunc.DeepCopy(Resource.state[key])
		local state_time ,name = state.update_timing ,state.data.name

		local buff_data
		if parameter then
			local input_data
			buff_data=StringDecode.TransToDic({StringDecode.trim_head_tail(parameter):sub(2,#parameter-1)})
			for key,v in pairs(state.data) do
				buff_data[key] = buff_data[key] or v
			end
			state.data=buff_data
		end

		local index = TableFunc.Find(v.state[state_time] , name ,'name')

		
		if index then
			local effect = state.overlay
			--print('v.state[state_time][index]')
			--print('overlay!')
			--TableFunc.Dump(v.state[state_time][index])
			local toUse={self = state ,target_table=v.state[state_time][index]}
			StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse)
		else
			--print('add!')
			local effect = state.add
			local toUse={self = state ,target_table=v}
			StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse )
			--state[key].add(target,state[key].state,table.unpack(args))
		end
	end





end
return StateHandler