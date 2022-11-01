local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local StringRead={}
function StringRead.ReadStrTable(tab,obj ,battle)
	local s =''
	local value
	--TableFunc.Dump(tab)
	for i,t in pairs(tab) do
		value=t.value
		if tonumber(value) then value ='+'..value end
		s='('..s..value..')'
	end
	value=StringRead.StrToValue(s ,obj ,battle)
	return value
end

function StringRead.StrFormat(str,...)
	local t ={}
	local head,tail
	local arg={...}
	for v in string.gmatch(str, '((%%)%a+(%%))') do
		TableFunc.Push(t,v)
	end

	local s =str
	for k,v in pairs(t) do
		local pattern = type(arg[k])=='number' and'%%d' or '%%s'
		--print(arg[k],pattern)
		s=s:gsub('%'..v..'%',pattern)
	end

	return s:format(...)
	
end
function StringRead.StrColor(str)
	local Resource =require('resource.Resource')
	local word_table={}
	local t ={}
	local s =str

	for v in str:gmatch('(%#.-%#)') do
		TableFunc.Push(word_table ,v)
	end

	local index=1
	--[[while index <#str do
		local w =s:sub(index,index)
		if w =='#' then
			--print('S',s ,index)
			local scope_end=StringDecode.FindCommandScope(index+1 ,s,'#')
			local value = str:sub(index,scope_end)
			--print('value',value,scope_end)
			TableFunc.Push(word_table, value)
			index=scope_end+1
		else
			index=index+1
		end
	end]]

	for k,v in pairs(word_table) do
		--print('str color ',v)
		local color = v:match('%a+')
		--print(color)
		assert(Resource.color[color],'color '..color..' is nil')
		TableFunc.Push(t, Resource.color[color])
		if k+1 <= #word_table then
			local self_head ,self_tail = s:find(word_table[k])
			local head,tail = s:find(word_table[k+1], self_tail+1)
			local between = s:sub(self_tail+1, head-1)
			if k==1 and between:sub(1,1)==' ' then
				between=between:sub(2, #between)
			end
			TableFunc.Push(t, between)
			s=s:gsub(v,'')
			s=s:gsub(between,'')

		else		
			s=StringDecode.trim_head_tail(s:gsub(v,'')) 
			TableFunc.Push(t, s)
		end
	end
	return t
end
function StringRead.StrPrintf(str,obj,battle,...)
	local Resource =require('resource.Resource')

	local s =str
	if s:find('%%.-%%') then
		if type(obj)== 'table' then
			local head,tail = s:find('%%.-%%')
			local w = s:sub(head+1,tail-1)
			
			s=s:gsub(w,'self.'..w)
			w=w:gsub(w,'self.'..w..'')		
			local v =StringRead.StrToValue(w ,obj ,battle)	
			s=s:gsub('%%'..w..'%%'	,v)
		else
			s=StringRead.StrFormat(s,...)
		end
	end

	if s:find('%#%a+%#') then
		s=StringRead.StrColor(s)
	else
		s={Resource.color['black'],s}
	end
	return s
end
local function split_dot_word(str)
	local word_table={}
	for v in string.gmatch(str, '(%a+[^%(%)^+^-^*^/])') do
		table.insert(word_table, v)
	end

	local t={}
	local n = ''
	for k,v in pairs(word_table) do
		if v:find('%.') then
			n=n..v
		else
			n=n..v
			table.insert(t,n)
			n=''
		end
	end
	return t
end
function StringRead.StrToValue(str,obj,battle)
	--將特定文字轉成數字 ex:(master.data.atk + card.level)*2 -->return (10 + 3)*2
	--擷取特定文字片段 word_table == {master.atk ,card.level}
	local word_table=split_dot_word(str)
	local value_table ={}

	--word_table 取得數字 放入value_table
	local StringAct=require('lib.StringAct')
	local machine = StringAct.NewMachine()
	for k,v in pairs(word_table) do
		local arg = {StringDecode.split_by(v,'.')}
		local key1 =TableFunc.Shift(arg)
		local effect={key1}
		for k,v in pairs(arg) do
			TableFunc.Push(effect ,'get '..v)
		end
		local toUse={card=obj,self=obj}
		StringAct.ReadEffect(battle ,machine ,effect , toUse )
		local value = TableFunc.Pop(machine.stack)
		if type(value)=='table' then value=TableFunc.Pop(value) end
		TableFunc.Push(value_table,value)
	end

	-- 將數字取代文字
	s =str		
	for k,v in pairs(value_table) do
		s=s:gsub(word_table[k],v)
	end
	local value = load('return '..s)()
	return value

end

return StringRead