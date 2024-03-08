local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local StateAssets = {}

function StateAssets.Init(tab)
     for k,state in pairs(tab) do
          for key,value in pairs(state) do
               --[[if key =='data'  then
                    StringDecode.TransToTable(state, key ,value)
                    state[key]=StringDecode.TransToDic(state[key])
                    state[key].name = k                    
               else]]
               --[[if key =='data' then
                    state[key].name = k
               end]]
               if key =='update_timing' then
                    StringDecode.TransToTable(state, key ,value)
               end
          end
          if state.add_effect then
               local w = state.add_effect
               assert(not w:find('add_buff') ,'state\'s add_effect can\'t use add_buff command') 
          end

     end
end

local function get_parameter(key)

     if key:find('%(') then
          
          local left , right = key:find('%(.-%)')
          local parameter = key:match('%((.-)%)')
          --print('parameter ',parameter , left , right)
          key = StringDecode.Trim_head_tail( key:sub(1, left-1) ) 
          --print('buff key',key)
          --parameter = StringDecode.Trim_head_tail(parameter):sub(2,#parameter-1)
          parameter = {StringDecode.Split_by(parameter ,',')}
          parameter = StringDecode.TransToDic(parameter)
          return key,parameter
     else
          return key
     end
end
function StateAssets.instance(key ,holder ,caster)
     local state_key,parameter = get_parameter(key)
     local state = TableFunc.DeepCopy(_G.Resource.state[state_key].data)
     if parameter then
          local new_data = TableFunc.DeepCopy(parameter)
          for i,v in pairs(state) do
               new_data[i] = new_data[i] or v
          end
          state=new_data
     end
     state.name = state_key
     state.holder=holder
     state.caster=caster

     return state
end
return StateAssets