local StringRead = require('lib.StringRead')

local Msg={}
function Msg.msg(key,...)
	local Resource = require('resource.Resource')
	local translate = Resource.translate
	local s  = translate[key]
	--print('mag arg ',...)
	if s:find('%%%a+%%') or s:find('%#%a+%#') then --s:find('%p') ([%#%a+%#]+)
		--print('msg ',s,' find %p')
		local ns = StringRead.StrPrintf(s,...)
		--print('ns ',ns)
		return ns
	else
		--print('not find %p ')
		return s
	end

end
function Msg.Init( t )
	for k,v in pairs(t) do
		local s =''
		local count = 1
		if type(v)=='table' then
			--print(k,'is table')
			for i, j in pairs(v) do				
				if type(j)=='table' then
					--print(k..'['..i..'] is table')
					Msg.Init(t[k])
				else
					local len =#v
					if count > 1 then
						s=s..','..j
					else
						s=s..j
					end					
					if count == len then
						--print('merge '..k)
						t[k]=s
					end
				end
				count=count+1
			end
		end
	end
end
return Msg