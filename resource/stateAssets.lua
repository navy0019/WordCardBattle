local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local StateAssets = {}
function StateAssets.Init(tab)
     for k,state in pairs(tab) do
          for key,value in pairs(state) do
               if key =='data'  then
                    StringDecode.TransToTable(state, key ,value)
                    state[key]=StringDecode.TransToDic(state[key])
                    state[key].name = k
               elseif key =='update_timing' then
                    StringDecode.TransToTable(state, key ,value)
               end
          end
          if state.add_effect then
               local w = state.add_effect
               assert(not w:find('add_buff') ,'state\'s add_effect can\'t use add_buff command') 
          end

     end
end
return StateAssets