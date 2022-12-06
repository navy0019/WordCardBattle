local battle={
	characterData={
		monsterData = {
			{
				skill = {
					"testCard",
				},
				data = {
					act = 2,
					def = 2,
					shield = 2,
					hp = 2,
					team_index = 1,
					atk = 2,
				},
				race = "enemy",
				state={
					round_start={}, 
					round_end={}, 
					every_card={},
					is_target={}},
				key = "m_small_1",
				dropItem = "money 100",
				think_weights = {
					"70% atk hero [find_state spell]",
					"30% buff enemy",
				},
			},
			{
				skill = {
					"testCard",
				},
				data = {
					act = 3,
					def = 3,
					shield = 3,
					hp = 3,
					team_index = 2,
					atk = 3,
				},
				race = "enemy",
				state={round_start={}, round_end={}, every_card={},is_target={}},
				key = "m_mid_1",
				dropItem = "money 100",
				think_weights = {
					"70% atk hero [find_state spell]",
					"30% atk hero 1",
				},
			},
			{
				skill = {
					"testCard",
				},
				data = {
					act = 4,
					def = 4,
					shield = 4,
					hp = 4,
					team_index = 3,
					atk = 4,
				},
				race = "enemy",
				state={round_start={}, round_end={}, every_card={},is_target={}},
				key = "m_XL_1",
				dropItem = "money 100",
				think_weights = {
					"70% atk hero [find_state spell]",
					"30% buff enemy",
				},
			},
		},
		heroData = {
			{
				skill = {
					"attack",
					"attack2",
				},
				data = {
					atk = 2,
					def = 2,
					shield = 2,
					hp = 2,
					team_index = 1,
					act = 2,
				},
				race = "'hero'",
				key = "hero1",
				state={	
					round_start={}, 
					round_end={}, 
					every_card={},
					is_target={}},
				advancedSkill = "attack",
			},
			{
				skill = {
					"attack",
					"attack2",
				},
				data = {
					atk = 3,
					def = 3,
					shield = 3,
					hp = 3,
					team_index = 2,
					act = 3,
				},
				race = "'hero'",
				key = "hero2",
				state={round_start={}, round_end={}, every_card={},is_target={}},
				advancedSkill = {
					"attack",
					"attack",
				},
			},
			{
				skill = {
					"attack",
					"attack",
				},
				data = {
					atk = 4,
					def = 4,
					shield = 4,
					hp = 4,
					team_index = 3,
					act = 4,
				},
				race = "'hero'",
				key = "hero3",
				state={round_start={}, round_end={}, every_card={},is_target={}},
				advancedSkill = {
					"attack",
					"attack",
				},
			},
			{
				skill = {
					"attack",
					"attack",
				},
				data = {
					atk = 5,
					def = 5,
					shield = 5,
					hp = 5,
					team_index = 4,
					act = 5,
				},
				race = "'hero'",
				key = "hero4",
				state={round_start={}, round_end={}, every_card={},is_target={}},
				advancedSkill = {
					"attack",
					"attack",
				},
			},
		},
		grave = {
		},
	}
}
return battle