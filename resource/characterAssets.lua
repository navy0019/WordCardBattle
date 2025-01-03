local Character = require("lib.character")
local TableFunc = require('lib.TableFunc')
local StringDecode = require('lib.StringDecode')

local CharacterAssets = {}
function CharacterAssets.Init(t)
	for k, v in pairs(t) do
		if type(v.skill) ~= 'table' then
			local skill = v.skill
			v.skill = { skill }
		end
		--[[if v.data then
        	v.data=StringDecode.TransToDic(v.data)
        	v.data.shield=0
        	--TableFunc.Dump(v.data)
        end]]
		if v.AI_act and type(v.AI_act) ~= 'table' then
			v.AI_act = { v.AI_act }
		end
	end
end

function CharacterAssets.instance(key, index)
	local o = TableFunc.DeepCopy(_G.Resource.character[key])
	o.key = key
	o.serial = TableFunc.GetSerial(o)
	--[[o.getAsset=function(o,index)
				assert(Resource.character[o.key][index],'don\'t have key '..index)
				return Resource.character[o.key][index]
			   end]]

	local character = Character.new(o)
	return character
end

return CharacterAssets
