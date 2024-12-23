local StringDecode           = require('lib.StringDecode')
local TableFunc              = require('lib.TableFunc')
local MathExtend             = require('lib.math')

local StringRead             = {}
local Simple_Command_Machine = require('battle.SimpleCommandMachine')
StringRead.machine           = Simple_Command_Machine.NewMachine()


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
					local key_dic = { card = obj }
					local nv = StringRead.StrToValue(v, key_dic, battle)
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
			--print('after replace', ns)
			--TableFunc.Dump(color)
			TableFunc.Push(t, color, s)
		else
			local color = { 0, 0, 0, 1 }
			TableFunc.Push(t, color, s)
		end
	end

	return t
end

local function capture_string(str)
	local s_t, p_t       = {}, {}
	local start_p, end_p = nil, nil
	local s              = ''
	local index          = 1

	local function insert_str(index, current_s)
		if index and index >= #str and not current_s:match('[%s%+%-%*%/%(%)]') then
			end_p = index
		else
			end_p = index - 1
		end
		TableFunc.Push(s_t, s)

		-- print('push', end_p, s)
		s = ''
		TableFunc.Push(p_t, { start_p, end_p })
		start_p = nil
	end
	while index <= #str do
		local current_s = str:sub(index, index)
		--print('current_s', current_s)
		if current_s:match('%(') then
			if #s > 0 then
				insert_str(index, current_s)
			end
			local p2 = StringDecode.Find_symbol_scope(index, str, '(', ')')
			if #s_t > 0 then
				local last = s_t[#s_t]
				--print('last', last)
				local last_p2 = p_t[#p_t][2]
				local detect = str:sub(last_p2, index)
				--print('detect', detect)
				if not detect:match('[%+%-%*%/]') then
					local s = str:sub(index, p2)
					s_t[#s_t] = s_t[#s_t] .. s
					p_t[#p_t][2] = p2
					index = p2
				end
			end
		end
		if not current_s:match('[%s%+%-%*%/%(%)]') and not tonumber(current_s) then
			s = s .. current_s
			if not start_p then start_p = index end
		end
		if #s > 0 then
			if current_s:match('[%s%+%-%*%/%(%)]') or index >= #str then
				--print('match', current_s:match('[%s%+%-%*%/%(%)]'), index)
				insert_str(index, current_s)
			end
		end
		index = index + 1
	end
	--print('Finish', str)
	--TableFunc.Dump(s_t)
	--TableFunc.Dump(p_t)
	return s_t, p_t
end
function StringRead.StrToValue(s, key_dic, battle, index)
	--將特定文字轉成數字 ex:(holder.data.atk + card.level)*2 -->return (10 + 3)*2
	--擷取特定文字片段 word_table == {holder.atk ,card.level}

	local index = index --部分value可能是table
	local str = s
	--print('StrToValue', str)
	--TableFunc.Dump(key_dic)
	local value_table = {}
	local word_table, pos_table = capture_string(str)
	local ns = ''
	--TableFunc.Dump(word_table)
	for key, string in pairs(word_table) do
		StringRead.machine:ReadEffect(battle, { string }, key_dic)
		local value = TableFunc.Pop(StringRead.machine.stack)

		if type(value) == 'table' then
			value = value[index] and value[index] or value[#value]
			--[[if key_dic.mapping and #value > 0 then
				--print('key_dic have mapping ', index)
				--TableFunc.Dump(key_dic.mapping)
				value = TableFunc.Pop(value)
				--print(value)
			end]]
		end
		if not tonumber(value) then
			--print('not tonumber', value)
			value = StringRead.StrToValue(value, key_dic, battle, index)
		end
		--print('string to value', string, value)
		TableFunc.Push(value_table, value)
	end
	for key, value in pairs(value_table) do
		local p1, p2 = pos_table[key][1], pos_table[key][2]
		--[[if key > 1 then
			p1 = p1 - dist
			p2 = p2 - dist
		end]]
		--TableFunc.Dump(pos_table)
		--print('p1p2', p1, p2)
		str = StringDecode.Gsub_by_index(str, value, p1, p2)
	end
	str = StringDecode.Trim(str)
	--print('replace', s, str)
	local value = MathExtend.round(load('return ' .. str)()) --type(s) == 'number' and MathExtend.round(load('return ' .. s)()) or s
	print('StrToValue ', s, value)
	StringRead.machine.stack = {}
	return value
end

return StringRead
