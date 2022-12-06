local TableFunc=require('lib.TableFunc')
local StringDecode = require('lib.StringDecode')


local function update_remove_position(target ,parameter ,key)
	for i,state in pairs(target.state) do
		if state.key == parameter.key then
			if state.position > parameter.position then
				--print(key)
				--TableFunc.Dump(parameter)
				state.position = state.position - (#parameter[key]+2)
			elseif state.position < parameter.position then
				state.position = state.position - 1
			end
		end
	end
end
local function update_add_position(target ,parameter ,key)
	for i,state in pairs(target.state) do
		if state.key == parameter.key then
			if state.position < parameter.position then
				state.position = state.position +1
			end
		end
	end
end
local card_state={

	change_data={
		add=function(target ,parameter)
			local parameter =TableFunc.DeepCopy(parameter)
			for k,v in pairs(parameter) do
				if k~='times' and k~='position' and k~='key' then
					assert(target.data[k] ,'card don\'t have data '..k)
					local num = tonumber(v) and '+'..v or v
					local t ={ times = parameter.times}	
					target.data[k]='('..target.data[k]..num..')'
					t[k]=num 
					t.position = #target.data[k]
					t.key = 'change_data'
					update_add_position(target ,t ,k)
					TableFunc.Push(target.state ,t)
				end
			end

		end,
		update=function(self)
			if tonumber(self.times) then
				self.times=self.times-1
			end 
		end,
		remove=function(target ,parameter)
			for k,v in pairs(parameter) do
				if k~='times' and k~='position' and k~='key' then					
					local len = #parameter[k]
					local start = parameter.position -len 
					local new_str =StringDecode.Gsub_by_index(target.data[k] ,'',start ,parameter.position)
					--print('new_str',target.data[k],start ,parameter.position)
					-- 移除左括號
					target.data[k] =new_str:sub(2 ,#new_str)

					--移除一個state後須更新其他state的位置
					update_remove_position(target ,parameter ,k)
					local index =TableFunc.Find(target.state , parameter)
					--print('remove',index)
					table.remove(target.state ,index)
				end
			end
		end
	}
}

return card_state