local Character = require("lib.character")
local TableFunc=require('lib.TableFunc')

--local StringConvert = require("lib.stringConvert")

local CharacterAssets = {}
function CharacterAssets.Init(t)
	local data_map={'hp','act','atk','def','shield'}
    for k,v in pairs(t) do
        v.data={shield=0}
        for key,value in pairs(v) do
			if TableFunc.Find(data_map,key) then
                v.data[key]=value
                v[key]=nil
            end
        end
        if type(v.skill)~='table' then
        	local skill =v.skill
        	v.skill={skill}
        end
    end
end
function CharacterAssets.instance( key,index)

	local o = TableFunc.Copy(_G.Resource.character[key])
	o.key=key
	o.data.team_index=index
	--[[o.getAsset=function(o,index)
				assert(Resource.character[o.key][index],'don\'t have key '..index) 
				return Resource.character[o.key][index] 
			   end]]
	
	local character = Character.new(o)
	return character
end
return CharacterAssets