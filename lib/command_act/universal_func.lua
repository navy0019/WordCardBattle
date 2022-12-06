local TableFunc		= require('lib.TableFunc')
local StringRead 	= require('lib.StringRead')
local StringDecode	= require('lib.StringDecode')


local map={
	compare		={'>=','<=','==','>','<'},
	calculate	={'sum','minus','multiplie','divided'},
	type_tab	={atk={'melee','range','magic','atk'}}
}
--local compare_map	={'>=','<=','==','>','<'}
--local calculate_map	={'sum','minus','multiplie','divided'}
--local type_tab={atk={'melee','range','magic','atk'}}

local function group_with_condition(data,condition)
	local StringAct		= require('lib.StringAct')
	local mini_command =condition:sub(2,#condition-1)
	local act={StringDecode.split_by(mini_command,',')}	
	local m=StringAct.NewMachine()
	local t={}
	m.stack={data}				
	StringAct.ReadEffect(battle ,m ,act )

	local result =TableFunc.Shift(m.stack)
	--TableFunc.Dump(result)
	for k,v in pairs(result) do
		if v then
			TableFunc.Push(t ,data[k])
		end
	end
	return t
end
local function excute_arg(battle ,effect,toUse)
	local StringAct=require('lib.StringAct')
	local m=StringAct.NewMachine()
	for k,v in pairs(effect) do
		if v:find('%.') and not v:find('%[') then
			local act= {StringDecode.split_by(v,'.')}
			for i=#act,2,-1 do
				act[i]='get '..act[i]
			end
			local parameter = excute_arg(battle ,act ,toUse)
			effect[k]=parameter
		end
	end
	StringAct.ReadEffect(battle ,m ,effect,toUse)
	local result =TableFunc.Shift(m.stack)
	return result
end

local universal_func={
	get_group=function(data,stack,arg)
		local condition , num
		for k,v in pairs(arg) do
			if tonumber(v) then
				num=tonumber(v)
			else
				condition=v
			end
		end

		local t
		if condition and not num then
			t=group_with_condition(data,condition)
			if #t >1 or #t==0 then
				TableFunc.Push(stack, t)
			else
				TableFunc.Push(stack, t[1])
			end
		elseif not condition and num then
			if data[num] then
				TableFunc.Push(stack, data[num])
			else
				TableFunc.Push(stack, {})
			end
		elseif condition and num then
			t=group_with_condition(data ,condition)

			if t[num] then
				TableFunc.Push(stack, t[num])
			else
				TableFunc.Push(stack, {})
			end
		else
			TableFunc.Push(stack ,data) 
		end
	end,
	excute_arg=function(battle ,effect,toUse)
		local result =excute_arg(battle ,effect,toUse)
		return result
	end,
	identifyType=function(o)
		if type(o)~='table' then return type(o) end
		if TableFunc.IsDictionary(o) then 
			return 'dictionary'
		else
			return 'array'
		end

	end,
	findSymbol=function(str,tab_name)
		for k,v in pairs(map[tab_name]) do
			if str:find(v) then
				return k
			end
		end
	end,
	match_type=function(except ,card_type)
		for i ,card_key in pairs(card_type) do
			for k ,tab_value in pairs(map['type_tab']) do
				if card_key == except then return true end
				if type(tab_value)=='table' and TableFunc.Find(tab_value ,except) and TableFunc.Find(tab_value ,card_key) then
					return true
				end
			end
		end
		return false
	end

}
return universal_func