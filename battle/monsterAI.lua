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
	local Act = State.new("Act")

	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait,MakeChance  ,DecideChance ,ChooseSkill ,Act
		},
		events={
			--[[ 					
			Wait--> MakeChance-->DecideChance -->ChooseSkill --> Act
			 |	    
			Act 
			]]
			{state=Wait,to='MakeChance'},
			{state=Wait,to='Act'},
			{state=MakeChance,to='DecideChance'},
			{state=DecideChance,to='ChooseSkill'},
			{state=ChooseSkill,to='Act'},			
			{state=Act,to='Wait'},
		}
	})
	machine.chance_tab={}
	machine.decide={}
	machine.think_tab=Make_think_tab(m)
	machine.skill_card=skill_card
	Wait.Do=function(slef,battle ,mon)
		if #machine.decide >0 then
			machine:TransitionTo('Act',battle ,m)
		elseif not machine.already_think then
			machine:TransitionTo('MakeChance',battle ,mon)
		end
	end
	MakeChance.DoOnEnter=function(slef,battle, mon )--依據 think_tab 的目標是否存在 製作 機率範圍
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

	DecideChance.DoOnEnter=function(slef,battle,mon ,chance_tab)
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
	ChooseSkill.DoOnEnter=function(slef,battle, mon ,current)
	    TableFunc.Dump(current)
	    local card_option={}
	    for k,card in pairs(machine.skill_card) do
	    	if StringAct.Match_type(current.type ,card.type)then
	    		TableFunc.Push(card_option , card)
	    	end
	    end

	end
	return machine
end


local function PreviewAct(battle, m ,skill_card,seed)
	local chance_tab ,ran_max =MakeChance(battle, m.think_weights )

	local current = DecideChance(chance_tab, ran_max ,seed)
	--TableFunc.Dump(current)

	local decide={}
	local optional={}
	--print('skill_card',#m.skill_card)
	local num =tonumber(m.data.team_index)
	--print(num)
	--TableFunc.Dump(skill_card)
	for k,card in pairs(skill_card[num]) do
		for i,type in pairs(card.type) do
			if StringAct.Find_type(current.type) then
				TableFunc.Push(optional,{card=card,group=current.group}) 
			end
		end
	end
	--print('optional',#optional)
	local cost = 0
	while cost < m.data.act do
		local index = math.random(#optional)
		local card =optional[index].card
		if cost +card.data.cost <= m.data.act then
			cost = cost +card.data.cost
			TableFunc.Push(decide, optional[index])
		else
			for i=#optional, 1 ,-1 do
				local card=optional[i].card
				if cost +card.data.cost > m.data.act then
					TableFunc.Pop(optional)
				end
			end
			if #optional <= 0 then
				break
			end
		end
	end
	return decide
end
local function DecideAct(battle, m ,skill_card,seed)
	local characterData=TableFunc.Copy(battle.characterData)
	local decide=PreviewAct(battle, m ,skill_card,seed)
	return decide
end

mAI.default={DecideAct=DecideAct ,MakeChance=MakeChance,decideMachine=decideMachine}
mAI.metatable={}
function mAI.new(battle)
	local o={battle=battle}
	setmetatable(o,mAI.metatable)
	return o
end
mAI.metatable.__index=function (table,key) return mAI.default[key] end
return mAI 