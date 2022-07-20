local TableFunc = require("lib.TableFunc")
local CardSkill = require('battle.cardSkill')
local stringRead =require("lib.stringRead")

local CardLogic={}


local function UseCard( battle,choose )
	local result = stringRead.ReadEffect(choose)--card:Effect(battle,cardTab.target ,extraInput)

	--table.insert(result,1,{toPending={func=battle.DropCard,arg={battle ,battle.battleData.hand ,card} ,actName='dropCard'}})
	--local funcTab = battle.machine.funcTab
	--table.insert(result,{toPending={func=funcTab.ReDraw,arg={} ,actName='redraw'}})

	return result
end
local function Update(self,battle)
	for i=#self.pending,1 ,-1 do
		if self.pending[i].card then
			print('have a card')
			local pending = UseCard(battle,self.pending[i])
			table.remove(self.pending ,i)
			return pending
			
		else
			--{isCopy=false,effect=''}
			--print('> 0')
		end
	end
end
CardLogic.default={Update=Update,UseCard=UseCard}
CardLogic.metatable={}
function CardLogic.new()
	local o = {pending={}}
	setmetatable(o,CardLogic.metatable)
	return o
end
CardLogic.metatable.__index=function (table,key) return CardLogic.default[key] end
return CardLogic