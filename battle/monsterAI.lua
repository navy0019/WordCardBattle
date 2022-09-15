local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local function MakeTarget(o)
end
local function CheckGroupExist(battle, command)
	local effect = {command}
	local StringAct=require('lib.StringAct')
	local m=StringAct.NewMachine(effect,{ target_table={}} ,battle)
	StringAct.ReadEffect(battle ,m)
	local group=TableFunc.Pop(m.stack)
	if #group > 0 then
		return group
	end
	return false
end
local function MakeChance(battle, t)
   local chance_tab={}
   local min=1
   local max=0
   for k,v in pairs(t) do--{think_weights={'70% atk hero [find_state spell] ','30% buff enemy'}}
      local act,copy_scope = StringDecode.Split_Command(v)
      act ={StringDecode.split_by(act[1],'%s')}
      act=StringDecode.Replace_copy_scope(act,copy_scope)

      local chance,type   = TableFunc.Shift(act) ,TableFunc.Shift(act) 
      local command   = ''
      for k,v in pairs(act) do
        	command=command..v..' '
      end
      command=StringDecode.trim_head_tail(command)  
      chance =chance:match('%d+')
      
      local exist=CheckGroupExist(battle, command)
      --print('exist',exist)
      if exist then
      	max=max+chance
      	TableFunc.Push(chance_tab,{min=min,max= max ,type=type ,group=exist})
      	min=chance+1
      end

    end 
    --TableFunc.Dump(t)
    return chance_tab ,max
end
local function DecideAct(battle, m ,seed)
	local chance ,max =MakeChance(battle, m.think_weights)
	math.randomseed(seed)
	local num =math.random(max)
	local current
	for k,v in pairs(chance) do
		if v.min <= num and v.max >= num then
			current = v
			break
		end
	end

	local type_tab={atk={'melee','range','magic','atk'}}
	local optional={}
	for k,card in pairs(m.skill_card) do
		for i,type in pairs(card.type) do
			if TableFunc.Find(type_tab.atk ,current.type) then
				TableFunc.Push(optional,card)
			elseif current.type==type then
				TableFunc.Push(optional,card)
			end
		end
	end

	local cost = 0
	while cost < m.actPoint do
		local index = math.random(#optional)
		local card =optional[index]
		if cost +card.cost <= m.actPoint then
			cost = cost +card.cost
			TableFunc.Push(m.decide, card)
		else
			for i=#optional, 1 ,-1 do
				local card=optional[i]
				if cost +card.cost > m.actPoint then
					TableFunc.Pop(optional)
				end
			end
			if #optional <= 0 then
				break
			end
		end
	end

end

local mAI={}
mAI.default={DecideAct=DecideAct ,MakeChance=MakeChance}
mAI.metatable={}
function mAI.new()
	local o={}
	setmetatable(o,mAI.metatable)
	return o
end
mAI.metatable.__index=function (table,key) return mAI.default[key] end
return mAI 