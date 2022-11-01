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
               end
          end

     end
end
return StateAssets