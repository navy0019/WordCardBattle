local TableFunc		= require('lib.TableFunc')
local StringDecode  = require('lib.StringDecode')

local CC_t={
	atk=function(battle,machine,...)
		local t = 	{
			protect = true,
			shield  = true,
			key ='set_hp_value',
			value='-1',
			value_state={
				{'holder', 'use_atk_card'} ,
				{'target', 'be_atk' } ,
			},
		}
		return t
	end,
	state_atk=function(battle,machine,...)
		--print('state_atk t')
		local t = 	{
			key ='set_hp_value',
			value='-1',
		}
		return t
	end,
	heal=function(battle,machine,...)
		local t = 	{
			key ='set_hp_value',
			value_state={
				{'holder', 'use_heal_card'} ,
				{'target', 'be_heal' } ,
			}
		}
		return t
	end,
	ignore_shield_attack=function(battle,machine,...)
		local t = 	{
			protect = true,
			shield  = false,
			key ='set_hp_value',
			value='-1',
			value_state={
				{'holder', 'use_atk_card'} ,
				{'target', 'be_atk' } ,
			}
		}
		return t
	end,
	def=function(battle,machine,...)
		local t = 	{
			key = 'set_value',
			sub_key={'shield','0~999'},
			value_state={
				{'holder', 'use_def_card'} ,
				{'target', 'be_def' } ,
			}
		}
		return t
	end,
	add_buff=function(batle ,machine ,...)
		local Resource = require('resource.Resource')
		local arg =...
		local target ,key = table.unpack(arg)
		local name ,data ,data_string ,res
		
		if key:find('%(') then
			name = key:sub(1 ,key:find('%(')-1 )
			res = Resource.state[name]
			data_string =key:sub(key:find('%(')+1 ,key:find('%)')-1 )
			data = {StringDecode.Split_by(data_string ,',')}
			data = StringDecode.TransToDic(data)
			--print('data')
			--TableFunc.Dump(data)
		else
			name = key
			res = Resource.state[name]
			data = TableFunc.DeepCopy(res.data)
			--print('data')
			--TableFunc.Dump(data)
		end
		--print('name' , name)
		
		local t ={
			key = 'add_buff',		
			value_state={},
			sub_key=name,
			dic= data,
			--protect = res.protect
			
		}
		if res.type:find('debuff') then	
			--print('insert debuff')
			TableFunc.Push(t.value_state ,{'holder', 'use_debuff_card'})
			TableFunc.Push(t.value_state ,{'target', 'receive_debuff'})
		else
			TableFunc.Push(t.value_state ,{'holder', 'use_buff_card'})
			TableFunc.Push(t.value_state ,{'target', 'receive_buff'})
		end
		return t
	end,
	set_value=function(battle,machine,...)
		local target ,value =...
		--print('set_value' ,target ,value )
		
		local t={
			key = 'set_value',
			sub_key	=0
		}
		return t
	end,
	assign_value=function(battle,machine,...)
		--local target ,value =...
		local arg= ...
		--print('assign value')
		--TableFunc.Dump(arg)
		local sub_key = TableFunc.Pop(arg)
		
		local t={
			key = 'assign_value',
			sub_key	=sub_key
		}
		--TableFunc.Dump(t)
		return t
	end,
}

return CC_t