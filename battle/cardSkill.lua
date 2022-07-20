local StatusHandle = require('battle.status')
local TableFunc = require('lib.TableFunc')

local cardSkill={
	meleeAttack=function(pos,value,...)
		local hit = pos < 3 and value or math.floor(value/2)
		for k,v in pairs({...}) do
			hit=hit+v
		end

		return hit
	end,
	rangeAttack=function(pos,value,...)
		local hit = pos > 2 and value or math.floor(value/2)
		for k,v in pairs({...}) do
			hit=hit+v
		end
		return hit
	end,
	magicAttack=function(pos,value,...)
		local hit = value
		for k,v in pairs({...}) do
			hit=hit+v
		end
		return hit
	end,

	dropAndDeal=function ( battle,extraInput,value,... )

	end,

	
}
return cardSkill