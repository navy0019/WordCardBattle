local TableFunc=require('lib.TableFunc')
local combine_act_map={
	melee=function(battle,machine,...)

		local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

		local atk_value = TableFunc.Pop(stack)

		local tab={
			atk_value,	
			'target','get data ','get team_index',
			'> 2','boolean_replace true[2] false[1]',
			'divided','minus'
		}
		for i=#tab ,1 ,-1 do
			table.insert(effect, machine.index+1 , tab[i])
		end
	end,
	range=function(battle,machine,...)

		local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

		local atk_value = TableFunc.Pop(stack)

		local tab={
			atk_value,	
			'target','get data ','get team_index',
			'< 2','boolean_replace true[2] false[1]',
			'divided','minus'
		}
		for i=#tab ,1 ,-1 do
			table.insert(effect, machine.index+1 , tab[i])
		end
	end,
	built_in_atk=function(battle,machine,...)
		local arg={...}

		local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect

		local atk_type=TableFunc.Shift(arg)
		local atk_value = TableFunc.Shift(arg)

		local tab

		if atk_type=='magic' then
			tab={
				'target','get data.hp' ,
				atk_value , 'minus' ,
				'set target.data.hp'
			}
		else
			tab={
				'target','get data','get shield',
				atk_value ,'copy','length','> 1','boolean false[fit_target]',atk_type ,
				'copy','set target.data.shield',
				'< 0' ,'boolean_pick true[target, get data.shield, target, get data.hp,sum ,set target.data.hp] '
			}
		end
		for i=#tab ,1 ,-1 do
			table.insert(effect, machine.index+1 , tab[i])
		end
	end,
}

return combine_act_map