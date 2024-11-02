local TableFunc = {}
function TableFunc.Upset(tab)
	local nt = {}
	for i = 1, #tab do
		local r = math.random(1, #tab)
		local v = tab[r]
		table.insert(nt, v)
		table.remove(tab, r)
	end
	for k, v in pairs(nt) do
		table.insert(tab, v)
	end
end

function TableFunc.IsDictionary(tab)
	if type(tab) ~= 'table' then return false end
	for k, v in pairs(tab) do
		if type(k) ~= 'string' then
			return false
		elseif type(k) == 'string' then
			return true
		end
	end
	if #tab <= 0 then return false end
	return true
end

function TableFunc.IsArray(tab)
	if type(tab) ~= 'table' then return false end
	for k, v in pairs(tab) do
		if type(k) == 'string' then
			return false
		end
	end
	if #tab == 0 then return true end
	return true
end

function TableFunc.GetSerial(tab)
	local s = tostring(tab)
	return s:gsub('table: ', '')
end

function TableFunc.MatchSerial(tab, serial)
	for k, v in pairs(tab) do
		local s = TableFunc.GetSerial(v)
		if s == serial then
			return k
		end
	end
	return false
end

function TableFunc.DicToArray(dic)
	local t = {}
	for k, v in pairs(dic) do
		TableFunc.Push(t, v)
	end
	return t
end

function TableFunc.Print_one_line(tab)
	--print('print',#tab)
	local s = ''
	if #tab == 0 then return '[ ]' end
	for k, v in pairs(tab) do
		if type(v) == 'table' then
			--print('is table')
			s = s .. '['
			if TableFunc.IsDictionary(v) then
				--print('is dic')
				s = s .. 'obj'
			else
				--print('not dic')
				for i, j in pairs(v) do
					if type(j) ~= 'table' then
						s = s .. tostring(j)
					else
						s = s .. 'obj'
					end
					if i < #v then
						s = s .. ','
					end
				end
			end
			s = s .. '], '
		else
			s = s .. '[' .. tostring(v) .. '], '
		end
	end
	return s
end

function TableFunc.Find(tab, target, key)
	local key = key or nil
	if key then
		for k, v in pairs(tab) do
			if TableFunc.IsDictionary(v) and v[key] == target then
				return k
			elseif k == key then
				return k
			end
		end
	else
		for k, v in pairs(tab) do
			if v == target then
				return k
			elseif TableFunc.IsArray(v) then
				--print('find in t')
				local p = TableFunc.Find(v, target)
				if p then return p end
			end
		end
	end
	return false
end

function TableFunc.Dump(data, showMetatable, lastCount)
	if type(data) ~= "table" then
		--Value
		if type(data) == "string" then
			io.write("\"", data, "\"")
		else
			io.write(tostring(data))
		end
	else
		--Format
		local count = lastCount or 0
		count = count + 1
		io.write("{\n")
		--Metatable
		if showMetatable then
			for i = 1, count do io.write("\t") end
			local mt = getmetatable(data)
			io.write("\"__metatable\" = ")
			TableFunc.Dump(mt, showMetatable, count) -- 如果不想看到元表的元表，可将showMetatable处填nil
			io.write(",\n")                 --如果不想在元表后加逗号，可以删除这里的逗号
		end
		--Key
		for key, value in pairs(data) do
			for i = 1, count do io.write("\t") end
			if type(key) == "string" then
				-- io.write("\"", key, "\" = ")
				io.write(key, " = ")
			elseif type(key) == "number" then
				-- io.write("[", key, "] = ")
			else
				io.write(tostring(key))
			end
			TableFunc.Dump(value, showMetatable, count) -- 如果不想看到子table的元表，可将showMetatable处填nil
			io.write(",\n")                    --如果不想在table的每一个item后加逗号，可以删除这里的逗号
		end
		--Format
		for i = 1, lastCount or 0 do io.write("\t") end
		io.write("}")
	end
	--Format
	if not lastCount then
		io.write("\n")
	end
end

function TableFunc.ShallowCopy(tab)
	local nt = {}
	for k, v in pairs(tab) do
		nt[k] = v
	end
	return nt
end

function TableFunc.DeepCopy(tab)
	local nt = {}
	for k, v in pairs(tab) do
		if type(v) ~= 'table' then
			nt[k] = v
		else
			nt[k] = TableFunc.DeepCopy(v)
		end
	end
	return nt
end

function TableFunc.Merge(targetTab, tab)
	for k, v in pairs(tab) do
		if type(v) == 'table' and type(k) == 'string' then
			targetTab[k] = {}
			TableFunc.Merge(targetTab[k], v)
		elseif type(v) == 'table' then
			table.insert(targetTab, v)
		elseif type(k) == 'number' then
			table.insert(targetTab, v)
		else
			--print('merge key')
			targetTab[k] = v
		end
	end
end

function TableFunc.Shift(tab)
	local v = tab[1]
	table.remove(tab, 1)
	return v
end

function TableFunc.Unshift(tab, ...)
	local t = { ... }
	local len = #t
	for i = len, 1, -1 do
		table.insert(tab, 1, t[i])
	end
end

function TableFunc.Pop(tab)
	local len = #tab
	local v = tab[len]
	table.remove(tab, len)
	return v
end

function TableFunc.Push(tab, ...)
	local t = { ... }
	for k, v in pairs(t) do
		table.insert(tab, v)
	end
end

function TableFunc.Swap(tab, a, b)
	local temp = tab[a]
	tab[a] = tab[b]
	tab[b] = temp
end

function TableFunc.Clear(tab)
	for key, value in pairs(tab) do
		tab[key] = nil
	end
end

return TableFunc
