local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')
local MathExtend 	= require('lib.math')

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

	for v in string.gmatch(str, '((%%)%a+(%%))') do
		TableFunc.Push(t,v)
	end

	local s =str
	--print('format ',s)

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
			s=StringDecode.Trim_head_tail(s:gsub(v,'')) 
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
			s=StringRead.StrFormat(s,obj,battle,...)
		end
	end

	if s:find('%#%a+%#') then
		s=StringRead.StrColor(s)
	else
		s={Resource.color['black'],s}
	end
	return s
end


function StringRead.StrToValue(str,key_link,battle)
	--將特定文字轉成數字 ex:(holder.data.atk + card.level)*2 -->return (10 + 3)*2
	--擷取特定文字片段 word_table == {holder.atk ,card.level}
	--print('StrToValue' , str)
	local word_table=StringDecode.Split_math_symbol(str ,'%+%-%*/')--split_part(str)
	--TableFunc.Dump(word_table)
	local value_table ={}

	--word_table 取得數字 放入value_table
	local Simple_Command_Machine=require('battle.SimpleCommandMachine')
	local machine = Simple_Command_Machine.NewMachine()
	for k,v in pairs(word_table) do
		local p = v:find('%(') 
		local word_type 
		if p then
			word_type = p==1 and 1 or v:sub(1 , v:find('%(')-1 )
		else
			word_type = v
		end

		if type(word_type)=='string' and not word_type:find('%p') then
			machine:ReadEffect(battle  ,{v} , key_link )
			local value = TableFunc.Pop(machine.stack)
			--print('func value',value)
			TableFunc.Push(value_table,value)
		elseif  word_type==1 then
			local s =v:sub(2,#v-1)		
			local value = StringRead.StrToValue(s ,key_link ,battle)
			--print('( ) value',value)
			TableFunc.Push(value_table,value)
		else
			local arg = {StringDecode.Split_by(v,'.')}
			local key1 =TableFunc.Shift(arg)
			local effect={key1}
			for k,v in pairs(arg) do
				TableFunc.Push(effect ,'get '..v)
			end

			local key_link=key_link
			--print('string read ')
			--TableFunc.Dump(effect)
			key_link.holder = key_link.card and key_link.card.holder or key_link.holder
			machine:ReadEffect(battle  ,effect , key_link )
			local value = TableFunc.Pop(machine.stack)
			--print('value ',value ,type(value))
			if type(value)=='table' then value = TableFunc.Pop(value) end
			if type(value)=='string' then value = StringRead.StrToValue(value ,key_link, battle) end
			--print('value',value)
			TableFunc.Push(value_table,value)
		end

	end

	-- 將數字取代文字
	s =str		
	for k,v in pairs(value_table) do
		local pattern
		--print('replace',word_table[k])
		if word_table[k]:find('%(') then
			pattern =table.unpack(StringDecode.Replace_symbol_for_find(word_table[k])) 
			--print('pattern',pattern)
			s=s:gsub(pattern ,v)
		else
			s=s:gsub(word_table[k] ,v)
		end
		--print('pattern ',word_table[k])
		
		--print('s? ',s)
	end
	
	--print(s)
	local value = MathExtend.round(load('return '..s)())
	--print('StrToValue ',s ,value)
	return value
end

return StringRead