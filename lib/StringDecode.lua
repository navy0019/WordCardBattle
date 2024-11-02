local TableFunc = require('lib.TableFunc')
local StringDecode = {}
--做初步的轉換(轉換成table 數字轉乘number type 複數項目放入table)
function StringDecode.Split_math_symbol(str)
	local parts = {}
	local stack = {}
	local currentPart = ""
	local count = 0

	for i = 1, #str do
		local char = str:sub(i, i)

		if char == "(" then
			count = count + 1
			--table.insert(stack, "(")
			currentPart = currentPart .. char
		elseif char == ")" then
			--table.remove(stack)
			count = count - 1
			currentPart = currentPart .. char
			if count == 0 then --#stack == 0 then
				--print('current part is empty')
				table.insert(parts, currentPart)
				currentPart = ""
			end
			--elseif #stack > 0 then
			--currentPart = currentPart .. char
		elseif char:match("[%+%-%*/]") then
			if currentPart ~= "" and count == 0 then
				table.insert(parts, currentPart)
				currentPart = ""
			elseif currentPart ~= "" and count ~= 0 then
				currentPart = currentPart .. char
			end
			--table.insert(parts, char)
		else
			currentPart = currentPart .. char
		end
		currentPart = StringDecode.Trim(currentPart)
	end


	if currentPart ~= "" then
		table.insert(parts, currentPart)
	end

	return parts
end

function StringDecode.Split_by(s, arg)
	local t = {}
	for v in string.gmatch(s, '[^' .. arg .. ']*') do
		local str = StringDecode.Trim_head_tail(v)
		if #str > 0 then
			TableFunc.Push(t, str)
		end
	end
	return table.unpack(t)
end

function StringDecode.Trim_head_tail(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

function StringDecode.Trim(s, arg)
	if arg then
		return s:gsub(arg, "")
	else
		return s:gsub("%s*", "")
	end
end

function StringDecode.Trim_quote(s)
	return s:gsub("^%s*%p?(.-)%p?%s*$", "%1")
end

function StringDecode.Split_comma_enter(s)
	local t = {}
	for v in string.gmatch(s, '([^,^\n]+)') do
		TableFunc.Push(t, v)
	end
	return t
end

local function merge_detect(s, t, symbol_left, symbol_right)
	--print('merge_detect',s)
	--TableFunc.Dump(t)
	local left, right
	if #symbol_left > 1 then
		left = symbol_left:sub(#symbol_left, #symbol_left)
		right = symbol_right:sub(#symbol_right, #symbol_right)
	else
		left = symbol_left
		right = symbol_right
	end
	local target_string = type(t[#t]) == 'string' and StringDecode.Trim_head_tail(t[#t]) or t[#t]
	local s_head = s:sub(1, 1)
	local s_tail = s:sub(#s, #s)
	local target_left, target_right = StringDecode.Count_symbol(target_string, symbol_left),
		StringDecode.Count_symbol(target_string, symbol_right)

	--print('target_string',target_string)
	--print('merge_detect',s_head ,s_tail ,s_tail ==right ,symbol_right,target_left,target_right)

	if s_head == symbol_left or s_head == right or s_head:find('%p') then
		return true
	elseif target_left ~= target_right then --and (s_head ==left or s_tail ==right)
		--print('re true')
		return true
	end
	--print('merge_detect' ,s, left ,right)
	return false
end

local function split_line(str)
	local tab = {}
	local index = 1
	while index < #str do
		local enter = str:find('\n', index)
		if enter then
			local s = str:sub(index, enter - 1)
			TableFunc.Push(tab, s)
			index = enter + 1
		else
			local s = str:sub(index, #str)
			TableFunc.Push(tab, s)
			break
		end
	end
	return tab
end
local function merge_line(t)
	local tab = {}
	for k, v in pairs(t) do
		local equal = v:find('=')
		if not equal then
			local line = StringDecode.Trim_head_tail(v)
			if #line > 0 then
				tab[#tab] = tab[#tab] .. line
			end
		else
			TableFunc.Push(tab, v)
		end
	end
	return tab
end
--[[local function detect_dic(value)
	if type(value) =='table' then
	elseif type(value)=='string' and value:find(':') and not value:find('(') then

	end
end]]
local function decode_value(t)
	for k, value in pairs(t) do
		if tonumber(value) then
			t[k] = tonumber(value)
		elseif type(value) == 'string' and value:find(':') and not value:find('%(') then
			--print('str to  dic' ,value)
			local nt = StringDecode.TransToDic({ value })
			t[k] = nt
		elseif type(value) == 'table' then
			local is_dic = false

			--合併{}範圍內的元素
			local nt = { value[1] }
			for i = 2, #value do
				local s = value[i]
				if merge_detect(s, nt, '%{', '%}') then
					local len = #nt
					nt[len] = nt[len] .. ',' .. s
					nt[len] = StringDecode.Trim(nt[len], '{')
					nt[len] = StringDecode.Trim(nt[len], '}')
					--print('merge',nt[len])
				else
					TableFunc.Push(nt, s)
					--print('not merge',s)
				end
			end
			--print('nt')
			--TableFunc.Dump(nt)
			for i, j in pairs(nt) do
				if type(j) == 'string' and j:find(':') and not j:find('%(') then
					--print('value to dic',j)
					is_dic = true
					break
				end
			end
			if is_dic then
				local dic = StringDecode.TransToDic(nt)
				t[k] = dic
			end
		end
	end
end
local function make_table(t)
	local tab = {}
	--print('make_table')
	--TableFunc.Dump(t)
	--print('\n')
	for k, v in pairs(t) do
		local equal = v:find('=')
		local key = StringDecode.Trim(v:sub(1, equal - 1))
		local value = StringDecode.Split_comma_enter(StringDecode.Trim_head_tail(v:sub(equal + 1, #v)))
		if #value > 1 then
			tab[key] = {}
			for i, j in pairs(value) do
				j = StringDecode.Trim_head_tail(j)
				local new_value = tonumber(j) and tonumber(j) or j
				TableFunc.Push(tab[key], new_value)
			end
		else
			tab[key] = value[1]
		end
	end
	for key, v in pairs(tab) do
		if type(tab[key]) == 'table' then
			local t = { TableFunc.Shift(tab[key]) }
			for i = 1, #tab[key] do
				local s = tab[key][i]
				if merge_detect(s, t, '%(', '%)') then
					local len = #t
					t[len] = t[len] .. ',' .. s
				else
					local s = tab[key][i]
					TableFunc.Push(t, s)
				end
			end
			tab[key] = t
		end
	end
	decode_value(tab)
	return tab
end
local calculate_map = { '+', '-', '*', '/' }
local compare_map = { '>=', '<=', '==', '>', '<' }

function StringDecode.Find_compare_symbol(str)
	for k, v in pairs(compare_map) do
		if str:find(v) then
			return k
		end
	end
end

function StringDecode.Find_calculate_symbol(str)
	for k, v in pairs(calculate_map) do
		if str:find(v) then
			return k
		end
	end
end

function StringDecode.Count_symbol(s, pattern)
	local count = 0
	for v in s:gmatch(pattern) do
		count = count + 1
	end
	return count
end

function StringDecode.Find_symbol_scope(i, s, symbol_left, symbol_right)
	local count = 0
	local index = i
	local symbol_right = symbol_right or symbol_left
	--print('try find',s,symbol_left ,symbol_right)
	--print('start index ',i)
	while index <= #s do
		local w = s:sub(index, index)
		if w == symbol_left then
			if symbol_left ~= symbol_right then
				count = count + 1
				index = index + 1
				--print('count++',count)
			elseif count == 0 then
				--print('count 0')
				return index
			end
		elseif w == symbol_right then
			count = count - 1
			if count == 0 then
				--print('re')
				return index
			end

			index = index + 1
		else
			index = index + 1
		end
	end
end

function StringDecode.Gsub_by_index(str1, str2, p1, p2) --str1 p1~p2範圍內的字替換成 str2
	--print('str1',str1)
	--將str每個字放入table -> 把要替換的範圍remove
	function string_to_table(str, t)
		str:gsub(".", function(c) TableFunc.Push(t, c) end)
	end

	local tab = {}
	string_to_table(str1, tab)
	--print('string_to_table')
	--TableFunc.Dump(tab)
	--print('#',#tab ,p1 ,p2)
	for i = 1, #str1 do
		if i >= p1 and i <= p2 then
			table.remove(tab, p1)
		end
	end
	if #tab < p1 then
		TableFunc.Push(tab, '')
	end
	local s = ''
	for k, v in pairs(tab) do
		if k == p1 then
			s = s .. str2 .. v
		else
			s = s .. v
		end
	end
	return s
end

--[[function StringDecode.Replace_copy_scope(tab,copy_scope)
	local new_tab={}
	local copy = TableFunc.DeepCopy(copy_scope)

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
end]]

function StringDecode.Replace_symbol_for_find(str)
	local t = {}
	local pattern = ''
	local index = 1
	while index <= #str do
		local s = str:sub(index, index)
		if s == '(' or (s:find('%p') and s ~= ')') then
			pattern = pattern .. '%' .. s
		elseif s == ')' then
			pattern = pattern .. '%' .. s
			if index == #str then
				TableFunc.Push(t, pattern)
				pattern = ''
			end
		else
			pattern = pattern .. s
		end

		index = index + 1
	end
	--print('t',#t)
	return t
end

function StringDecode.Trim_Command(str)
	local split = { StringDecode.Split_by(str, '%s') }
	local copy_split = TableFunc.DeepCopy(split)
	local complete = {}
	--TableFunc.Dump(copy_split)
	TableFunc.Push(complete, TableFunc.Shift(split))
	for i = 1, #split do
		local command = StringDecode.Trim_head_tail(split[i])
		if merge_detect(command, complete, '%(', '%)') then
			local len = #complete
			complete[len] = complete[len] .. ' ' .. command
		else
			local s = StringDecode.Trim_head_tail(split[i])
			TableFunc.Push(complete, s)
		end
	end
	return complete, copy_split
end

function StringDecode.Split_Command_Arg(s) --將command & arg 分開
	local command
	local arg = {}
	local left = s:find('%(')
	--print('Split_Command_Arg ' ,s ,left)
	if left then
		local right = StringDecode.Find_symbol_scope(left, s, '(', ')')
		--print('right ',s:sub(left+1,left+1) ,right)
		command = s:sub(1, left - 1)
		--print('Split_Command_Arg', command)
		arg = { StringDecode.Split_by(s:sub(left + 1, right - 1), ',') }
		local other = s:sub(right + 1, #s)
		if other and #other > 0 then
			TableFunc.Push(arg, other)
		end
		--print('Split_Command_Arg', command)
		--TableFunc.Dump(arg)
	else
		command = s
	end


	return command, arg
end

function StringDecode.TransToTable(obj, key, value)
	if type(obj[key]) ~= 'table' then
		--print(obj,key,value)
		local new_value = tonumber(value) and tonumber(value) or value
		obj[key] = { new_value }
	end
end

function StringDecode.TransToDic(tab)
	local t = {}
	local pre_key
	--print('TransToDic')
	--TableFunc.Dump(tab)
	for k, v in pairs(tab) do
		if type(v) == 'string' and v:find(':') then
			--print('v',v)
			local p         = v:find(':')
			local new_key   = StringDecode.Trim_head_tail(v:sub(1, p - 1))
			local new_value = StringDecode.Trim_head_tail(v:sub(p + 1, #v))
			new_value       = tonumber(new_value) and tonumber(new_value) or new_value
			--print('new')
			--print(new_key)
			--print(new_value)
			if type(new_value) == 'string' and new_value:find(':') then
				new_value = { StringDecode.Split_by(new_value, ',') }
				t[new_key] = new_value
				t[new_key] = StringDecode.TransToDic(t[new_key])
			else
				--print('the end')
				t[new_key] = new_value
				pre_key = new_key
			end
			--[[for key ,value in v:gmatch('(.+):(.+)') do
				local new_key   =StringDecode.Trim_head_tail(key)
				local new_value =StringDecode.Trim_head_tail(value)
				print('match :',new_key)
				new_value = tonumber(new_value) and tonumber(new_value) or new_value
				t[new_key]=new_value
				pre_key=new_key
			end]]
		else
			--print('v~= string')
			local new_value = type(v) == 'string' and StringDecode.Trim_head_tail(v) or v
			new_value = tonumber(new_value) and tonumber(new_value) or new_value
			if type(t[pre_key]) ~= 'table' then
				StringDecode.TransToTable(t, pre_key, t[pre_key])
				TableFunc.Push(t[pre_key], new_value)
			else
				TableFunc.Push(t[pre_key], new_value)
			end
		end
	end
	return t
end

function StringDecode.Decode(filename)
	local file = io.open(filename, 'r')
	local content = file:read('*all')
	local index = 1
	local tab = {}
	while index <= #content do
		local scope_start = content:find('{', index)
		if scope_start then
			local scope_end = StringDecode.Find_symbol_scope(scope_start, content, '{', '}')
			local scope_name = StringDecode.Trim_head_tail(content:sub(index, scope_start - 1))
			local str = content:sub(scope_start + 1, scope_end - 1)
			--print('Decode ',str)
			local t = split_line(str)
			--print('split_line')			
			t = merge_line(t)
			--print('merge_line')			
			t = make_table(t)
			--print('make_table')
			--TableFunc.Dump(t)

			tab[scope_name] = {}
			for key, value in pairs(t) do
				--print(scope_name,key,value)
				local new_value = value --detect_dic(value)
				tab[scope_name][key] = new_value
			end

			index = scope_end + 1
		else
			index = index + 1
		end
	end

	file:close()
	return tab
end

return StringDecode
