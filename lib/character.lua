local function ResetState(self)
	--print('ResetState')
	self.state = {
		round_start = {},
		round_end = {},
		every_card = {},
		is_target = {},
		use_atk_card = {},
		be_atk = {},
		use_def_card = {},
		be_def = {},
		use_heal_card = {},
		be_heal = {},
		use_debuff_card = {},
		receive_debuff = {},
		use_buff_card = {},
		receive_buff = {},
		protect = {},
		buff = {},
		dead = {},
		injure = {},
	}
end

local Character = {}

Character.default = { ResetState = ResetState }
Character.metatable = {}
function Character.new(o)
	o.data.shield = 0

	ResetState(o)
	setmetatable(o, Character.metatable)
	return o
end

Character.metatable.__index = function(table, key) return Character.default[key] end

return Character
