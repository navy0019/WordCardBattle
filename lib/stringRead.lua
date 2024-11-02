local StringDecode           = require('lib.StringDecode')
local TableFunc              = require('lib.TableFunc')
local MathExtend             = require('lib.math')

local StringRead             = {}
local Simple_Command_Machine = require('battle.SimpleCommandMachine')
StringRead.machine           = Simple_Command_Machine.NewMachine()

--[[function StringRead.ReadStrTable(tab, obj, battle)
	local s = ''
	local value
	--TableFunc.Dump(tab)
	for i, t in pairs(tab) do
		value = t.value
		if tonumber(value) then value = '+' .. value end
		s = '(' .. s .. value .. ')'
	end
	value = StringRead.StrToValue(s, obj, battle)
	return value
end]]

--[[function StringRead.StrFormat(str, ...)
	local t = {}
	local head, tail

	for v in string.gmatch(str, '((%%)%a+(%%))') do
		TableFunc.Push(t, v)
	end

	local s = str
	--print('format ',s)

	for k, v in pairs(t) do
		local pattern = type(arg[k]) == 'number' and '%%d' or '%%s'
		--print(arg[k],pattern)
		s = s:gsub('%' .. v .. '%', pattern)
	end

	return s:format(...)
end]]

function StringRead.StrPrintf(str_t, obj, battle, ...)
	local Hex2Color = require("lib.hex2color")
	local s = ''
	local t = {}
	--print('String Read Printf',str_t)

	for key, value in pairs(str_t) do
		local current_s = value.insert
		local num_t = {}
		local ns = ''
		for k in current_s:gmatch("%{.-%}") do
			local value = StringDecode.Trim(k:sub(2, #k - 1))
			local nt = { StringDecode.Split_by(value, ',') }

			for i, v in pairs(nt) do
				if v:find('%.') then
					--print('printf',v)
					local key_link = { card = obj }
					local nv = StringRead.StrToValue(v, key_link, battle)
					--TableFunc.Push(num_t , nv)
					ns = ns .. nv
				else
					--local nv = v:sub(v:find(':') , #v)
					--TableFunc.Push(num_t , v)
					ns = ns .. v
				end
			end
			TableFunc.Push(num_t, ns)
		end
		ns = ''
		local index = 1
		while index <= #current_s do
			local right
			if current_s:find('%{', index) then
				index = current_s:find('%{', index)
				right = StringDecode.Find_symbol_scope(index, current_s, '{', '}')
				local replace_s = TableFunc.Shift(num_t)
				ns = StringDecode.Gsub_by_index(current_s, replace_s, index, right)
				index = right + 1
			else
				index = #current_s + 1
			end
		end
		s = s .. ns

		if value.attributes then
			local color = Hex2Color(value.attributes.color)
			print('after replace', ns)
			TableFunc.Dump(color)
			TableFunc.Push(t, color, s)
		else
			local color = { 0, 0, 0, 1 }
			TableFunc.Push(t, color, s)
		end
	end

	return t
end

function StringRead.StrToValue(str, key_link, battle)
	--將特定文字轉成數字 ex:(holder.data.atk + card.level)*2 -->return (10 + 3)*2
	--擷取特定文字片段 word_table == {holder.atk ,card.level}
	--print('StrToValue', str, #StringRead.machine.stack)
	local word_table = StringDecode.Split_math_symbol(str) --split_part(str)
	--TableFunc.Dump(word_table)
	local value_table = {}

	--word_table 取得數字 放入value_table

	for k, v in pairs(word_table) do
		local p = v:find('%(')
		local word_type
		if p then
			word_type = p == 1 and 1 or v:sub(1, v:find('%(') - 1)
		else
			word_type = v
		end

		if type(word_type) == 'string' and not word_type:find('%p') then
			StringRead.machine:ReadEffect(battle, { v }, key_link)
			local value = TableFunc.Pop(StringRead.machine.stack)
			--print('func value', value)
			TableFunc.Push(value_table, value)
		elseif word_type == 1 then
			local s = v:sub(2, #v - 1)
			local value = StringRead.StrToValue(s, key_link, battle)
			--print('( ) value', value)
			TableFunc.Push(value_table, value)
		else
			local dot = v:find('%.')
			local left = v:sub(1, dot - 1)
			if not tonumber(left) then
				local arg = { StringDecode.Split_by(v, '.') }
				local key1 = TableFunc.Shift(arg)
				local effect = { key1 }
				for k, v in pairs(arg) do
					TableFunc.Push(effect, 'get ' .. v)
				end

				local key_link = key_link
				--print('string read strToValue')
				--TableFunc.Dump(key_link)
				--TableFunc.Dump(effect)
				key_link.holder = key_link.card and key_link.card.holder or key_link.holder
				StringRead.machine:ReadEffect(battle, effect, key_link)
				local value = TableFunc.Pop(StringRead.machine.stack)
				--print('value ',value ,type(value))
				if type(value) == 'table' then value = TableFunc.Pop(value) end
				if type(value) == 'string' then value = StringRead.StrToValue(value, key_link, battle) end
				--print('else value', value)
				TableFunc.Push(value_table, value)
			else
				TableFunc.Push(value_table, tonumber(v))
			end
		end
	end

	-- 將數字取代文字
	local s = str
	--print('befor gsub',s)	
	--TableFunc.Dump(word_table)
	for k, v in pairs(value_table) do
		local pattern
		--print('replace',word_table[k])
		if word_table[k]:find('%(') then
			--[[pattern =table.unpack(StringDecode.Replace_symbol_for_find(word_table[k]))
			print('pattern',pattern)
			s=s:gsub(pattern ,v)
			print(s ,'after',v)]]
			local p = word_table[k]:find('%(')
			local w = word_table[k]:sub(1, p)
			if w:find('%a+') then
				s = StringDecode.Gsub_by_index(s, v, 1, #word_table[k])
			else
				local p1 = word_table[k]:find('%(')
				local p2 = StringDecode.Find_symbol_scope(p1, s, '(', ')')
				s = StringDecode.Gsub_by_index(s, v, p1, p2)
			end
			--print(s ,'after')
		else
			s = s:gsub(word_table[k], v)
		end
		--print('pattern ',word_table[k])

		--print('s? ',s)
	end

	--print(s)
	local value = type(s) == 'number' and MathExtend.round(load('return ' .. s)()) or s
	--print('StrToValue ',s ,value)
	StringRead.machine.stack = {}
	return value
end

return StringRead
