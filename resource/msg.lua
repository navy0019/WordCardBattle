local StringRead   = require('lib.StringRead')
local Resource     = require('resource.Resource')
local StringDecode = require('lib.StringDecode')

local Msg          = {}
function Msg.msg(key, key_link, ...)
	local translate = Resource.translate
	--TableFunc.Dump(translate)
	local info      = translate[key].info
	local arg       = { ... }
	local s         = ''
	--print('mag arg ', key, ...)
	--[[for key, value in pairs(arg) do
		TableFunc.Shift(StringRead.machine.stack, value)
	end]]
	for i, t in pairs(info) do
		local insert_str = t.insert
		local temp = {}
		for scope in insert_str:gmatch('%{.-%}') do
			--local v = TableFunc.Shift(arg)
			--print('arg', v)
			TableFunc.Unshift(StringRead.machine.stack, TableFunc.Shift(arg))
			local value_str = StringDecode.Trim(scope:sub(2, #scope - 1))
			local value = StringRead.StrToValue(value_str, key_link, {})
			TableFunc.Push(temp, value)
		end

		local index = 1
		while index <= #insert_str do
			local detect_str = insert_str:sub(index, #insert_str)
			local p1, p2 = detect_str:find('%{.-%}')
			if p2 then
				local value = TableFunc.Shift(temp)
				detect_str = StringDecode.Gsub_by_index(detect_str, value, p1, p2)
				index = p2 + 1
				--print('insert_str', insert_str)
				s = s .. detect_str
			else
				s = s .. detect_str
				break
			end
		end
		--print('final msg', insert_str)
	end
	--print('s', s)
	return s
	--assert(nil)
end

function Msg.Init(t)
	for k, v in pairs(t) do
		local s = ''
		local count = 1
		if type(v) == 'table' then
			--print(k,'is table')
			for i, j in pairs(v) do
				if type(j) == 'table' then
					--print(k..'['..i..'] is table')
					Msg.Init(t[k])
				else
					local len = #v
					if count > 1 then
						s = s .. ',' .. j
					else
						s = s .. j
					end
					if count == len then
						--print('merge '..k)
						t[k] = s
					end
				end
				count = count + 1
			end
		end
	end
end

return Msg
