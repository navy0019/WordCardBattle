local StringDecode = require('lib.StringDecode')
local StringRead   = require('lib.StringRead')
local TableFunc    = require('lib.TableFunc')

local StateAssets  = {}

function StateAssets.Init(tab)
     for k, state in pairs(tab) do
          for key, value in pairs(state) do
               --[[if key =='data'  then
                    StringDecode.TransToTable(state, key ,value)
                    state[key]=StringDecode.TransToDic(state[key])
                    state[key].name = k
               else]]
               --[[if key =='data' then
                    state[key].name = k
               end]]
               if key == 'update_timing' then
                    StringDecode.TransToTable(state, key, value)
               end
          end
          if state.add_effect then
               for index, command in ipairs(state.add_effect) do
                    assert(not command:find('add_buff'), '為避免無限迴圈，state effect 不能使用add_effect 作為指令') --'state\'s add_effect can\'t use add_buff command'
               end
          end
     end
end

local function get_parameter(key, key_dic, battle)
     if key:find('%(') then
          local left = key:find('%(')
          local right = StringDecode.Find_symbol_scope(left, key, '(', ')')
          --print('get_parameter', left, right)

          local parameter = key:sub(left + 1, right - 1)
          key = StringDecode.Trim_head_tail(key:sub(1, left - 1))
          --print('buff key',key)
          --parameter = StringDecode.Trim_head_tail(parameter):sub(2,#parameter-1)


          parameter = { StringDecode.Split_by(parameter, ',') }
          parameter = StringDecode.TransToDic(parameter)
          --print('parameter')
          --TableFunc.Dump(parameter)
          StringDecode.TransDataType(parameter)
          for key, value in pairs(parameter) do
               if key ~= 'name' and key ~= 'caster' and key ~= 'holder' and type(value) == 'string' then
                    parameter[key] = StringRead.StrToValue(value, key_dic, battle)
               end
          end
          return key, parameter
     else
          return key
     end
end
function StateAssets.instance(key, holder, caster, key_dic, battle)
     --print('StateAssets instance', key)
     local state_key, parameter = get_parameter(key, key_dic, battle)
     local state = TableFunc.DeepCopy(_G.Resource.state[state_key].data)
     if parameter then
          local new_data = TableFunc.DeepCopy(parameter)
          for i, v in pairs(state) do
               new_data[i] = new_data[i] or v
          end
          state = new_data
     end
     state.name = state_key
     state.holder = holder
     state.caster = caster

     return state
end

return StateAssets
