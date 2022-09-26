local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StringDecode=require('lib.StringDecode')
local StringAct=require('lib.StringAct')
local TableFunc=require('lib.TableFunc')

local mAI={}
local function CheckGroupExist(battle, opt )
	--print(opt.group)
	local machine=StringAct.NewMachine({opt.group},{ target_table={}} ,battle)
	StringAct.ReadEffect(battle ,machine)
	local result=TableFunc.Pop(machine.stack)
	if #result > 0 then
		return true
	end
	--TableFunc.Dump(result)
	return false
end
local function Make_think_tab( mon )

	local think_tab={}
	local command=''
	for i,v in pairs(mon.think_weights) do
		local act,copy_scope = StringDecode.Split_Command(v)
		act ={StringDecode.split_by(act[1],'%s')}
		act=StringDecode.Replace_copy_scope(act,copy_scope)

		local first = StringDecode.trim_head_tail(TableFunc.Shift(act)) 
		if first:find('%%') then
			local type = TableFunc.Shift(act)
			command   = StringDecode.trim_head_tail(table.concat(act,' '))						
			chance =first:match('%d+')
			TableFunc.Push(think_tab,{chance=chance ,option={{type=type,group=command}} }) 	
		else
			command=StringDecode.trim_head_tail(table.concat(act,' '))
			local len = #think_tab
			TableFunc.Push(think_tab[len].option ,{type=first,group=command}) 	
		end
	end
	return think_tab
end
local function decideMachine(battle ,m ,skill_card)
	local Wait = State.new("Wait")
	local MakeChance = State.new("MakeChance")
	local DecideChance = State.new("DecideChance")
	local ChooseSkill= State.new("ChooseSkill")

	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait,MakeChance  ,DecideChance ,ChooseSkill
		},
		events={
			--[[ 					
			Wait--> MakeChance-->DecideChance -->ChooseSkill					
			]]
			{state=Wait,to='MakeChance'},

			{state=MakeChance,to='DecideChance'},
			{state=DecideChance,to='ChooseSkill'},
			{state=ChooseSkill,to='Wait'},	
		}
	})
	machine.chance_tab={}
	machine.decide={}
	machine.think_tab=Make_think_tab(m)
	machine.skill_card=skill_card
	Wait.Do=function(self ,battle ,mon)

		machine:TransitionTo('MakeChance',battle ,mon)

	end
	MakeChance.DoOnEnter=function(self ,battle, mon )--依據 think_tab 的目標是否存在 製作 機率範圍
		local chance_tab={}
		local min,max = 1, 0

		for i,v in pairs(machine.think_tab) do
			local chance =tonumber(v.chance)
			TableFunc.Push(chance_tab,{})
			for k,opt in pairs(v.option) do
				local exist=CheckGroupExist(battle,  opt)
				if exist then
					--print('exist',opt.group)
					local len = #chance_tab
					
					chance_tab[len].option = chance_tab[len].option or {}
					TableFunc.Push(chance_tab[len].option ,opt)

					if not chance_tab[len].max then 
						max=max+chance
						chance_tab[len].max =max 
					end				
					if not chance_tab[len].min then
						chance_tab[len].min = chance_tab[len].min or min
						min=chance+1
					end
				end
			end
		end
		--TableFunc.Dump(chance_tab)
		machine:TransitionTo('DecideChance',battle ,mon , chance_tab)
	end

	DecideChance.DoOnEnter=function(self ,battle , mon ,chance_tab)
		local current
		local ran_max = 0
		for k,v in pairs(chance_tab) do
			ran_max =math.max(ran_max, v.max)
		end
		local num =math.random(ran_max)
		for k,v in pairs(chance_tab) do
			if v.min <= num and v.max >= num then
				local len = #v.option
				num=math.random(len)
				current = v.option[num]
				break
			end
		end
		--TableFunc.Dump(current)
		machine:TransitionTo('ChooseSkill',battle, mon ,current)
	end
	ChooseSkill.DoOnEnter=function(self ,battle , mon ,current)
	    --TableFunc.Dump(current)
	    local card_option ={}
	    for k,card in pairs(machine.skill_card) do
	    	if StringAct.Match_type(current.type ,card.type)then
	    		TableFunc.Push(card_option , card)
	    	end
	    end

	    local cost = 0
	    while cost < mon.data.act do
	    	local index = math.random(#card_option)
	    	local card =card_option[index]
	    	if cost +card.data.cost <= mon.data.act then
	    		cost = cost +card.data.cost
	    		TableFunc.Push(machine.decide, card_option[index])
	    	else
	    		for i=#card_option, 1 ,-1 do
	    			local card=card_option[i]
	    			if cost +card.data.cost > mon.data.act then
	    				TableFunc.Pop(card_option)
	    			end
	    		end
	    		if #card_option <= 0 then
	    			break
	    		end
	    	end
	    end
	    --TableFunc.Dump(machine.decide)
	    local s =''
	    for k,v in pairs(machine.decide) do
	    	s=s..v.key..' '
	    end
	    print(mon.key..' make decide '..s)
	end
	ChooseSkill.DoOnLeave=function(self ,battle , mon ,current)
		machine.decide={}
	end
	return machine
end

mAI.default={DecideMachine=decideMachine}
mAI.metatable={}
function mAI.new(battle)
	local o={battle=battle}
	setmetatable(o,mAI.metatable)
	return o
end
mAI.metatable.__index=function (table,key) return mAI.default[key] end
return mAI 