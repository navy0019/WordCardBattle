local states={
    fragile = {
		update = "calculate_value(*2) to value",
		overlay = true,
		effect_number = "single",
		type = "buff",
		location = "use_atk_card",
		update_timing = {
			"every_card",
		},
		data = {
			round = 1,
		},
	},
	protect = {
		replace_effect = "protect to target",
		data = {
			round = 1,
		},
		replace = true,
		type = "buff",
		update_timing = {
			"round_end",
			"trigger",
		},
		location = "protect",
	},

	poison = {
		update = "state_atk(self.atk) to target",
		overlay = true,
		data = {
			round = 3,
			atk = 1,
		},
		type = "debuff",
		update_timing = {
			"round_end",
		},
		location = "round_end",
	},
	power_up = {
		update = "calculate_value(+1) to value",
		overlay = true,
		effect_number = "multi",
		type = "buff",
		location = "use_atk_card",
		update_timing = {
			"every_card",
		},
		data = {
			round = 1,
		},
	},
	bait = {
		data = {
			round = 1,
		},
		type = "debuff",
		update_timing = {
			"round_start",
		},
		location = "round_start",
	},
	bless = {
		update = "calculate_value(+1) to value.round",
		overlay = true,
		effect_number = "single",
		type = "buff",
		location = "use_buff_card",
		update_timing = {
			"trigger",
		},
		data = {
			round = 1,
		},
	},
	solid = {
		overlay = true,
		data = {
			round = 1,
		},
		add_effect = {
			"assign_value(false,remove_shield) to target",
		},
		type = "buff",
		update_timing = {
			"round_end",
		},
		location = "round_end",
	},
}
return states