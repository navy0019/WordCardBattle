local TableFunc=require('lib.TableFunc')
local StringDecode={}
--做初步的轉換(轉換成table 數字轉乘number type 複數項目放入table)

function StringDecode.split_by(s ,arg)
	local t ={}
	for v in string.gmatch(s, '[^'..arg..']*') do
		local str=StringDecode.trim_head_tail(v)
		TableFunc.Push(t ,str)
	end
	return table.unpack(t)
end
function StringDecode.trim_head_tail(s)
   return s:gsub("^%s*(.-)%s*$", "%1")
end
function StringDecode.trim(s,arg)
	if arg then
		return s:gsub(arg,"")
	else
		return s:gsub("%s*","")
	end
end
function StringDecode.trim_quote( s )
	return s:gsub("^%s*%p?(.-)%p?%s*$", "%1")
end

function StringDecode.split_comma_enter( s )
	local t = {}
	for v in string.gmatch(s, '([^,^\n]+)') do
		TableFunc.Push(t, v)
	end
	return t
end

local function split_line(str)
	local tab = {}
	local index = 1
	while index < #str do
		local enter = str:find('\n',index)
		if enter then
			local s = str:sub(index,enter-1)			
			TableFunc.Push(tab, s)
			index = enter+1
		else
			local s = str:sub(index,#str)
			TableFunc.Push(tab, s)		
			break
		end
	end
	return tab
end
local function merge_line(t)
	local tab={}
	for k,v in pairs(t) do
		local equal = v:find('=')
		if not equal then
			local line = StringDecode.trim_head_tail(v)
			if #line >0 then
				tab[#tab]=tab[#tab]..line
			end
		else
			TableFunc.Push(tab ,v)
		end
	end
	return tab
end
local function decode_value( t )
	for k,v in pairs(t) do
		if tonumber(v) then
			t[k]=tonumber(v)
		end
	end
end
local function make_table(t)
	local tab={}
	for k,v in pairs(t) do
		local equal = v:find('=')
		--print('v',v)
		local sq_brackets =v:find('%[')
		if equal and not sq_brackets then
			
			local key = StringDecode.trim(v:sub(1,equal-1))
			--print('just equal',key)
			local value = StringDecode.split_comma_enter(StringDecode.trim_head_tail(v:sub(equal+1,#v)))
			if #value >1 then
				tab[key]={}
				for i,j in pairs(value) do
					j=StringDecode.trim_head_tail(j)
					local new_value = tonumber(j) and tonumber(j) or j
					TableFunc.Push(tab[key], new_value)
				end
			else
				tab[key]=value[1]
			end
		elseif equal and sq_brackets then
			
			local key = StringDecode.trim(v:sub(1,equal-1))
			local str = StringDecode.trim_head_tail(v:sub(equal+1,#v))
			local act ,copy_scope=StringDecode.Split_Command(str)
			act=StringDecode.Replace_copy_scope(act,copy_scope)
			tab[key]=act

		end
	end
	decode_value(tab)
	return tab
end
function StringDecode.CheckInclude(content)
	local include_start , include_end = content:find('include')

	if include_end then
		local include_line_start = content:find('=',include_end)
		local include_line_end = content:find('\n',include_end)
		local str =content:sub(include_line_start+1 ,include_line_end-1)
		local tab=StringDecode.split_comma_enter(str)
		for k,v in pairs(tab) do
			tab[k]=StringDecode.trim_head_tail(v)
		end
		return tab
	else
		return nil
	end
end

function StringDecode.FindCommandScope(i,s ,symbol_left ,symbol_right)
	local count =0
	local index=i
	local symbol_right =symbol_right or symbol_left
	--print('try find',s,i,symbol_left ,symbol_right)
	while index <= #s do
		local w = s:sub(index,index)
		if w==symbol_left then			
			if symbol_left~= symbol_right then
				count=count+1
				index=index+1
			elseif count==0 then
					return index
			end

		elseif w==symbol_right then
			if count==0 then
				return index
			end
			count=count-1
			index=index+1
		else
			index=index+1
		end
	end
end

function StringDecode.Gsub_by_index(str1 ,str2,p1,p2)
	--print('str1',str1)
	--將str每個字放入table -> 把要替換的範圍remove
	function string_to_table(str,t)
		str:gsub(".",function(c) TableFunc.Push(t,c) end)
	end
	local tab={}
	string_to_table(str1,tab)
	--print('p12',p1,p2)
	for i=1,#str1 do
		if i >= p1 and i <=p2 then
			table.remove(tab,p1)
		end
	end
	if #tab < p1 then
		TableFunc.Push(tab,'')
	end
	local s=''
	for k,v in pairs(tab) do
		if k== p1 then
			s=s..str2..v
		else
			s=s..v
		end

	end
	return s
end
function StringDecode.Replace_copy_scope(tab,copy_scope)
	local new_tab={}
	local copy = TableFunc.Copy(copy_scope)

	for i,str in pairs(tab) do
		local index =1
		while tab[i]:find('\"copy_scope\"') do
			--print('tab[i]',tab[i])
			local a,b = tab[i]:find('\"copy_scope\"')
			local key = TableFunc.Shift(copy)
			--print('key!',key)
			tab[i] =StringDecode.Gsub_by_index(tab[i] ,key,a , b)
		end

	end
	new_tab=tab
	return new_tab	
end

function StringDecode.Split_Command(command)--裁切[ ]部分
	local copy_scope ={}
	local act={}
	local index=1										
	local word=''
	--print('Split_Command',command)
	while index <= string.len(command) do
		local w = command:sub(index,index)
		if w =='[' then
			local scope_end=StringDecode.FindCommandScope(index+1 ,command,'[',']')
			local scope_word =command:sub(index,scope_end)
			--print('scope_word',scope_word)
			TableFunc.Push(copy_scope, scope_word)
			word=word.."\"copy_scope\""

			index = scope_end
		else
			word=word..w
		end

		index=index+1
	end

	--print('w',word)
	act={StringDecode.split_by(word,',')}
	--TableFunc.Dump(act)
	--TableFunc.Dump(copy_scope)
	return act,copy_scope
end
function StringDecode.TransToTable(obj ,key ,value)
	if type(obj[key])~='table' then
		--print(obj,key,value)
		local new_value = tonumber(value) and tonumber(value) or value
		obj[key]={ new_value }
	end
end
function StringDecode.TransToDic(tab)	
	local t={}
	for k,v in pairs(tab) do
		if v:find(':') then
			for key ,value in v:gmatch('(.+):(.+)') do
				local new_key   =StringDecode.trim_head_tail(key)
				local new_value =StringDecode.trim_head_tail(value)
				new_value = tonumber(new_value) and tonumber(new_value) or new_value
				t[key]=new_value
			end
		end
	end
	return t
end
function StringDecode.Decode(filename)
	local file = io.open(filename,'r')
	local content = file:read('*all')
	local index =1
	local tab={}
	while index <= #content do
		local scope_start =content:find('{',index)
		if scope_start then
			local scope_end = StringDecode.FindCommandScope(scope_start+1,content ,'{' ,'}')
			local scope_name = StringDecode.trim_head_tail(content:sub(index,scope_start-1))
			local str = content:sub(scope_start+1 ,scope_end-1)
			local t=	split_line(str)
			t = merge_line(t)
			t = make_table(t)
			if #scope_name> 0 then
				tab[scope_name]={} 
				for key,value in pairs(t) do
					--print(scope_name,key,value)
					tab[scope_name][key]=value
				end
			else
				for key,value in pairs(t) do
					tab[key]=value
				end
			end
			index =scope_end+1
		else
			index=index+1
		end
	end

	file:close()
	return tab
end
return StringDecode


