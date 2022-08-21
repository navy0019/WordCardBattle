local StringDecode=require('lib.StringDecode')

local StringRead={}
local function valueMap(key1 ,key2 ,obj)
	map={
		master= function()return obj[key1].data[key2] end,
		card= function()
					local v = obj.data[key2]
					if type(v)=='string' then
						return StringRead.StrToValue(v ,obj)
					end
					return v
				end,
		self= function()
			local v = obj.data[key2]
			if type(v)=='string' then
				return StringRead.StrToValue(v ,obj)
			end
			return v
		end
	}
	assert(map[key1],key1..' is nil')
	return map[key1](key1 ,key2 ,obj)
end

function StringRead.StrFormat(str,...)
	local t ={}
	local head,tail
	local arg={...}
	for v in string.gmatch(str, '((%%)%a+(%%))') do
		table.insert(t,v)
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
	for v in string.gmatch(str, '([%#%a+%#]+)') do	
		table.insert(word_table,v)
	end


	for k,v in pairs(word_table) do
		--print('str color ',v)
		local color = v:match('%a+')
		--print(color)
		assert(Resource.color[color],'color '..color..' is nil')
		table.insert(t,Resource.color[color])
		if k+1 <= #word_table then
			local self_head ,self_tail = s:find(word_table[k])
			local head,tail = s:find(word_table[k+1],self_tail+1)
			local between = s:sub(self_tail+1, head-1)
			if k==1 and between:sub(1,1)==' ' then
				between=between:sub(2,#between)
			end
			table.insert(t,between)
			s=s:gsub(v,'')
			s=s:gsub(between,'')

		else		
			s=StringDecode.trim_head_tail(s:gsub(v,'')) 
			table.insert(t,s)
		end
	end
	return t
end
function StringRead.StrPrintf(str,...)
	local Resource =require('resource.Resource')
	local obj = ...
	local s =str
	if s:find('%%%a+%%') then
		if type(obj)== 'table' then
			local head,tail = s:find('%%%a+%%')
			local w = s:sub(head+1,tail-1)
			s=s:gsub(w,'self.'..w)
			w=w:gsub(w,'self.'..w..'')			
			local v =StringRead.StrToValue(w,obj)	
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
function StringRead.StrToValue(str,obj)
	--將特定文字轉成數字
	local word_table={}
	local value_table ={}

	--擷取特定文字片段 word_table == {master.atk ,card.level}
	for v in string.gmatch(str, '([%a.%a]+)') do
		--print('v ',v)
    	table.insert(word_table,v)
	end

	--word_table 取得數字 放入value_table
	for k,v in pairs(word_table) do
		local key1 ,key2 = StringDecode.split_by(v,'.')
		local i = valueMap(key1 ,key2 ,obj)
		--print('i',i)
		table.insert(value_table,i)
	end

	-- 將數字取代文字 ex:(master.atk + card.level)*2 --> (10 + 3)*2
	s =str	
	
	for k,v in pairs(value_table) do
		s=s:gsub(word_table[k],v)
		--print('ss',s)
	end

	local value = load('return '..s)()
	return value

end

return StringRead