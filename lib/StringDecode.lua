local StringDecode={}
--做初步的轉換(轉換成table 數字轉乘number type 複數項目放入table)

function StringDecode.split_by(s ,arg)
	local t ={}
	for v in string.gmatch(s, '[^'..arg..']*') do-- +-*/()
		table.insert(t,v)
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
		table.insert(t,v)
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
			table.insert(tab, s)
			index = enter+1
		else
			local s = str:sub(index,#str)
			table.insert(tab, s)		
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
			table.insert(tab,v)
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
		if equal then
			local key = StringDecode.trim(v:sub(1,equal-1))
			local value = StringDecode.split_comma_enter(StringDecode.trim_head_tail(v:sub(equal+1,#v)))
			if #value >1 then
				tab[key]={}
				for i,j in pairs(value) do
					j=StringDecode.trim_head_tail(j)
					table.insert(tab[key],j)
				end
			else
				tab[key]=value[1]
			end
		end
	end
	decode_value(tab)
	return tab
end
local function find_scope(str,p)
	local scope_start = str:find('{',p) 		
	local scope_end   = str:find('}',p)
	return scope_start,scope_end
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

function StringDecode.Decode(filename)
	local file = io.open(filename,'r')
	local content = file:read('*all')
	local tab={}
	local includeTab=StringDecode.CheckInclude(content)

	if includeTab then
		for k,v in pairs(includeTab) do
			tab[v]={}
			local t={}
			local part_start , part_end = content:find(v..'_part')
			local scope_start = content:find('{',part_end) 		
			local scope_end   = content:find('}',part_end)
			local start = content:find('%a',scope_start)
			local str = content:sub( start,scope_end-1)--scope_start+2
			t = split_line(str)
			t = merge_line(t)
			t = make_table(t)
			for key,value in pairs(t) do
				tab[v][key]=value
			end	
		end
	else
		local t={}
		local scope_start = content:find('{',1) 		
		local scope_end   = content:find('}',1)
		local start = content:find('%a',scope_start)
		local str = content:sub( start,scope_end-1)--scope_start+2
		t = split_line(str)
		t = merge_line(t)
		t = make_table(t)
		for key,value in pairs(t) do
			tab[key]=value
		end
	end
	file:close()
	return tab
end

return StringDecode


