local battle={
	characterData={
		heroData = {
			{
				key = "hero1",
				data = {
					team_index = 1,
					shield = 1,
					atk = 1,
					def = 1,
					hp = 1,
					act = 1,
					state = {
						always = {
						},
						before = {{name='spell'}
						},
						after = {
						},
						is_target={		
						}
					},
				},
				race = "'hero'",
			},
			{

				key = "hero2",
				data = {
					team_index = 2,
					shield = 2,
					atk = 2,
					def = 2,
					hp = 2,
					act = 2,
					state = {
						always = {
						},
						before = {{name='spell'}
						},
						after = {
						},
						is_target={		
						}
					},
				},
				race = "'hero'",
			},

		},
		monsterData = {
			{
				think_weights={'70% atk random 1 hero [find_state spell] ','atk hero 1'},
				key = "m_mid_1",
				race = "enemy",
				data = {
					team_index = 1,
					shield = 1,
					atk = 1,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
						is_target={		
						}
					},
					hp = 1,
					def = 1,
					act = 1,
				},
				skill={},

			},
			{
				think_weights={'100% atk random 1 hero '},
				key = "m_mid_2",
				race = "enemy",
				data = {
					team_index = 2,
					shield = 2,
					atk = 2,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
						is_target={		
						}
					},
					hp = 2,
					def = 2,
					act = 2,
				},
				skill={},
			},

		},
	}

}
return battle