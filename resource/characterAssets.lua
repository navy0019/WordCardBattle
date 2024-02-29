local Character = require("lib.character")
local TableFunc=require('lib.TableFunc')
local StringDecode=require('lib.StringDecode')

local CharacterAssets = {}
function CharacterAssets.Init(t)
    for k,v in pairs(t) do
        
        if type(v.skill)~='table' then
        	local skill =v.skill
        	v.skill={skill}
        end
        if v.data then
        	v.data=StringDecode.TransToDic(v.data)
        	v.data.shield=0
        	--TableFunc.Dump(v.data)
        end
        if v.think_weights and type(v.think_weights)~='table' then
        	v.think_weights={v.think_weights}
        end

    end
end
function CharacterAssets.instance( key,index)

	local o = TableFunc.DeepCopy(_G.Resource.character[key])
	o.key=key
	o.value_request={}
	--[[o.getAsset=function(o,index)
				assert(Resource.character[o.key][index],'don\'t have key '..index) 
				return Resource.character[o.key][index] 
			   end]]
	o.state={
			round_start={}, 
			round_end={}, 
			every_card={},
			is_target={},
			use_atk_card={},
			be_attacked={},
			use_debuff_card={},
			be_debuff={},
			protect={},
			dead={}
		}
	local character = Character.new(o)
	return character
end
return CharacterAssets