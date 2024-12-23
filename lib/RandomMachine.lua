local TableFunc = require("lib.TableFunc")

local function Set_seed(machine, seed)
	machine.seed = seed
	math.randomseed(machine.seed)
end
local function New_seed(machine)
	local seed = math.random(999999) --9999
	Set_seed(machine, seed)
	return seed
end
local function Random(machine, a, b)
	--print('seed', machine.seed)
	local num = b ~= nil and math.random(a, b) or math.random(a)
	machine:Set_seed(machine.seed)
	--New_seed(machine)
	return num
end


local RandomMachine = {}

RandomMachine.default = { Set_seed = Set_seed, New_seed = New_seed, Random = Random }
RandomMachine.metatable = {}
function RandomMachine.new()
	o = { seed = math.random(999999) }
	math.randomseed(o.seed)

	setmetatable(o, RandomMachine.metatable)
	return o
end

RandomMachine.metatable.__index = function(table, key) return RandomMachine.default[key] end
return RandomMachine
