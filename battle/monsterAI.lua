local State = require('lib.FSMstate')
local Machine = require('lib.FSMmachine')
local StringDecode=require('lib.StringDecode')
local Simple_Command_Machine=require('battle.SimpleCommandMachine')
local TableFunc=require('lib.TableFunc')
local CardAssets=require('resource.cardAssets')

local mAI={}
local function Check_group_exist(battle, command )
	local machine=Simple_Command_Machine.NewMachine()
	--print('Check_group_exist',command)
	machine:ReadEffect(battle , command )--,temp_key_link
	--print('machine.stack ',#machine.stack)
	local result =TableFunc.Pop(machine.stack)
	--print('Check_group_exist ',command ,#result)
	--TableFunc.Dump(result)
	for i=#result ,1 ,-1 do
		local m =result[i]
		if m.data.hp <=0 then
			table.remove(result , i)
		end
	end
	if #result>0 then	
		--print('return true')
		return result
	end
	
	return false
end

local function new_machine(battle ,m )

	local Wait = State.new("Wait")
	local MakeOptions = State.new("MakeOptions")
	local Decide = State.new("Decide")
	local Act = State.new("Act")


	local machine =  Machine.new({
		initial=Wait,
		states={
			Wait,MakeOptions  ,Decide  ,Act
		},
		events={
			--[[ 					
			Wait--> MakeOptions-->Decide -->Act -->  Wait
									^--------|
																 
			]]
			{state=Wait,global=true},

			{state=MakeOptions,to='Decide'},
			{state=Decide,to='Act'},
			{state=Act,to='Decide'},	
			{state=Act,to='Wait'},	
		}
	})	
	machine.queue={}
	machine.decide=nil

	machine.current_index=1
	machine.target_tab={}
	machine.card_tab={}

	MakeOptions.DoOnEnter=function(self ,battle, mon )--遍歷選項 設置current_index
		--print('AI make option')
		for k,v in pairs(mon.AI_act) do
			local complete = StringDecode.Trim_Command(v)
			--TableFunc.Dump(complete)
			--print('\n\n')
			TableFunc.Push(machine.target_tab ,complete[#complete])
		end
		--print('AI make option',#machine.target_tab)
		machine:TransitionTo('Decide',battle ,mon )
	end

	Decide.DoOnEnter=function(self ,battle , mon )
		--print('Decide!')
		local function detect_all()
			for k,command in pairs(machine.target_tab) do
				local exist=Check_group_exist(battle, command )
				if exist then
					return k
				end
			end
			return false
		end

		machine.current_index = math.max(1 , machine.current_index)

		for i=machine.current_index ,#machine.target_tab do
			local command = machine.target_tab[i]
			local exist=Check_group_exist(battle, command )
			--print('Decide ',exist )
			if exist then
				--print('exist!',i)
				machine.current_index = i
				break
			elseif i ==#machine.target_tab then
				--print('not exist')
				local result = detect_all()
				if result then
					--print('Decide detect_all',result)
					machine.current_index = result
					break
				else
					--print('Decide detect_all',0)
					machine.current_index = 0
					break
				end
			end
			--print('\n')
		end
		if machine.current_index > 0 then
			machine.decide = mon.AI_act[machine.current_index]
		else
			machine.decide = 'grow_up_and_atk to random(1 ,enemy (hp > 0))'
		end
		
		machine:TransitionTo('Wait')
	end

	Act.DoOnEnter=function(self ,battle , mon )
		local SCM_machine=Simple_Command_Machine.NewMachine()
		local target = SCM_machine:ReadEffect(battle ,machine.target_tab[machine.current_index] )
		local card = machine.card_tab[machine.current_index]
		local key_link ={card = card,self=card,target_table=target}

		--CCM_machine:ReadEffect(battle ,machine.decide ,key_link )

		--local o ={toPending={key='ReadyToUse' ,arg={ toUse ,battle ,'monster'},actName='toUse' }}
		--TableFunc.Push(machine.queue , o)
		machine:TransitionTo('Wait')
	end

	machine.Update=function(self,battle,...)
		if #machine.queue > 0 then
			local o = TableFunc.Shift(machine.queue)			
			return o
		end
		self.current:Do(...)
		--print(self.current.name)
	end
	return machine
end

function Think(self ,battle, mon )--每一個動作後(玩家出牌,buff的效果) 都會確認一次 
	--print('Think!!')
	local target
	if self.machine.current_index > 0 then
		target = self.machine.target_tab[ self.machine.current_index ]
		--print('Think ',target ,self.machine.current_index )
		local exist=Check_group_exist(battle, target )
		if not exist then
			--print('Think ',target ,'not exist' )
			self.machine.current_index =math.min(4 , self.machine.current_index +1) 
			self.machine:TransitionTo('Decide',battle, mon )
		end
	end

end
mAI.default={Think=Think}
mAI.metatable={}

function mAI.new(battle,m )
	--TableFunc.Dump(m)
	local o={machine=new_machine(battle ,m )}
	for k,v in pairs(m.AI_act) do
		local complete = StringDecode.Trim_Command(v)
		local holder = 'monster '..TableFunc.GetSerial(m)
		local card = CardAssets.instance(complete[1] ,holder)
		TableFunc.Push(o.machine.card_tab , card)
	end
	setmetatable(o,mAI.metatable)
	return o
end
mAI.metatable.__index=function (table,key) return mAI.default[key] end
return mAI 