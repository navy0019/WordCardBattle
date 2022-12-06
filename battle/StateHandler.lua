local Resource = require('resource.Resource')
local StringAct = require('lib.StringAct')
local StringDecode = require('lib.StringDecode')
local TableFunc = require('lib.TableFunc')
local Card_state = require('lib.card_state')
local universal_func = require('lib.command_act.universal_func')

local StateHandler={}
StateHandler.machine=StringAct.NewMachine()

local function get_parameter(key)
	if key:find('%[') then
		local left = key:find('%[')
		local right = StringDecode.FindCommandScope(left+1 ,key ,'[',']')
		local parameter = key:sub(left,right)
		key = StringDecode.trim_head_tail( key:sub(1, left-1) ) 
		parameter = StringDecode.trim_head_tail(parameter):sub(2,#parameter-1)
		parameter = {StringDecode.split_by(parameter ,',')}
		parameter = StringDecode.TransToDic(parameter)
		return key,parameter
	else
		return key
	end
end
function StateHandler.Init(battle ,target , key ,parameter)
end
function StateHandler.Remove( battle,character ,timing_tab ,res ,index)
	if res.remove then
		--print('res remove')
		local effect = res.remove 
		local toUse={self = res ,target_table=character }
		StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse)
	else
		--print('remove')
	end

	table.remove(timing_tab , index)
end
function StateHandler.Update( battle, character ,state ,timing_tab)
	local name = state.name
	local res = Resource.state[name]--TableFunc.DeepCopy(
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
end
function StateHandler.Card_State_Update(target ,state)
	--print('state ',state.key ,state.times ,'update')
	local key =state.key
	Card_state[key].update(state)
	if type(state.times)=='number' and state.times <=0 then
		Card_state[key].remove(target, state)
	end
end
function StateHandler.AddBuff(battle,target,key)
	local state_key,parameter = get_parameter(key) 
	for k,v in pairs(target) do
		local state = TableFunc.DeepCopy(Resource.state[state_key])
		local state_time ,name = state.update_timing ,state.data.name
		
		if parameter then
			local new_data = TableFunc.DeepCopy(parameter)
			for k,v in pairs(state.data) do
				new_data[k] = new_data[k] or v
			end
			state.data=new_data
		end

		local index = TableFunc.Find(v.state[state_time] , name ,'name')

		if index and state.overlay then
			local effect = state.overlay
			local toUse={self = state ,target_table=v.state[state_time][index]}
			StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse)
		else --已存在同樣state但沒定義overlay則以add 處理
			local effect = state.add
			local toUse={self = state ,target_table=v}
			StringAct.ReadEffect(battle, StateHandler.machine ,effect, toUse )
		end
	end
end

local card_buff_type={
	current=function(battle,card,toUse,arg)
		local need_type ,key ,parameter ,number
		key  =TableFunc.Shift(arg)
		key,parameter = get_parameter(key)
 		Card_state[key].add(card  ,parameter)
	end,
	next=function(battle,card,toUse,arg)--放在cardLogic等待處理
		local need_type ,key ,parameter ,number
		number ,need_type  ,key ,parameter =table.unpack(arg)
		number=tonumber(number)
		need_type=need_type:gsub('_type','')
		key,parameter = get_parameter(key)
		local target_tab = battle.machine.cardLogic.state_pending
		TableFunc.Push(target_tab,{need_type=need_type ,number=number , key =key ,parameter=parameter })
	end,
	hand=function(battle,card,toUse,arg)
		local need_type ,key ,parameter ,number
		if #arg > 3 then
			number ,need_type ,key  =table.unpack(arg)
			number=tonumber(number)
			key,parameter = get_parameter(key)
			need_type=need_type:gsub('_type','')
			--print('need_type',need_type)
			for k,card in pairs(battle.battleData.hand) do
				for i=1,number do
					local bool=universal_func.match_type(need_type , card.type)
					if bool then
					end 
				end
			end

		elseif #arg > 2 then
			need_type  ,key  =table.unpack(arg)
			key,parameter = get_parameter(key)
		else
			key  =table.unpack(arg)
			key,parameter = get_parameter(key)	
			for k,card in pairs(battle.battleData.hand) do
				--print('key ',key,parameter)
				Card_state[key].add(card  ,parameter)
			end
		end
	end
}
function StateHandler.Add_Card_Buff(card,tab)
	local key = tab.key
	local parameter = tab.parameter
	Card_state[key].add(card  ,parameter)
	tab.number=tab.number-1

end
function StateHandler.Analysis_CardBuff(battle,toUse,arg)
	local arg =arg
	local which =TableFunc.Shift(arg)
	local card=toUse.card
	card_buff_type[which](battle,card,toUse,arg)

end
return StateHandler