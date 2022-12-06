local TableFunc=require('lib.TableFunc')
local combine_act={
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
	magic=function(battle,machine,...)
		local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
		local atk_value = TableFunc.Pop(stack)

		local tab={
			atk_value,'minus'
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

		--[[if atk_type=='magic' then
			tab={
				'target','get data.hp' ,
				atk_value , 'minus' ,
				'set target.data.hp'
			}
		else]]
			tab={
				'target','get data','get shield','< 0' ,
				'boolean_pick true[ 0 , set target.data.shield]',
				'target' ,'get data.shield',
				atk_value ,'copy','length','> 1','boolean false[ fit_target_length ]',atk_type ,
				'copy','set target.data.shield',
				'< 0' ,'boolean_pick true[target, get data.shield, target, get data.hp,sum ,set target.data.hp] '
			}
		--end
		for i=#tab ,1 ,-1 do
			table.insert(effect, machine.index+1 , tab[i])
		end
	end,
	random_atk=function(battle,machine,...)
		local arg={...}
		local toUse ,stack ,effect= machine.toUse ,machine.stack ,machine.effect
		local loop_num = TableFunc.Shift(arg)
		if not tonumber(loop_num) then
			local ran_arg = TableFunc.Shift(arg)
			loop_num=loop_num..' '..ran_arg
			loop_num = universal_func.excute_arg(battle ,{loop_num},toUse)
		else
			loop_num=tonumber(loop_num)
		end

		local atk_type = TableFunc.Shift(arg)

		local value = TableFunc.Shift(arg)
		if not tonumber(value) then
			if not value:find('%.')then
				local ran_value = TableFunc.Shift(arg)
				value=value..' '..ran_value
				value = universal_func.excute_arg(battle ,{value},toUse)
			else
				value = universal_func.excute_arg(battle ,{value},toUse)
			end
		else
			value=tonumber(value)
		end
		local tab={
			'loop '..loop_num..' [target,random 1 target [get data.hp, > 0],copy ,length , >0 ,boolean true[set_target,built_in_atk '..atk_type..' '..value..'],set_target ]'
		}
		for i=#tab ,1 ,-1 do
			table.insert(effect, machine.index+1 , tab[i])
		end
	end
}

return combine_act