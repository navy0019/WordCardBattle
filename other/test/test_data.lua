local battle={
	characterData={
		heroData = {
			{
				originData = {
					team_index = 1,
					shield = 1,
					atk = 1,
					hp = 1,
					act = 1,
					def = 1,
				},
				key = "hero1",
				data = {
					teamPos = 1,
					team_index = 1,
					shield = 1,
					atk = 1,
					def = 1,
					hp = 1,
					act = 1,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
					},
				},
				race = "'hero'",
			},
			{
				originData = {
					team_index = 2,
					shield = 2,
					atk = 2,
					hp = 2,
					act = 2,
					def = 2,
				},

				key = "hero2",
				data = {
					teamPos = 2,
					team_index = 2,
					shield = 2,
					atk = 2,
					def = 2,
					hp = 2,
					act = 2,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
					},
				},
				race = "'hero'",
			},

		},
		monsterData = {
			{

				originData = {
					team_index = 1,
					shield = 1,
					atk = 1,
					act = 1,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
					},
					def = 1,
					hp = 1,
				},
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
					},
					hp = 1,
					def = 1,
					act = 1,
				},

			},
			{

				originData = {
					team_index = 2,
					shield = 2,
					atk = 2,
					act = 2,
					state = {
						always = {
						},
						before = {
						},
						after = {
						},
					},
					def = 2,
					hp = 2,
				},
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
					},
					hp = 2,
					def = 2,
					act = 2,
				},

			},

		},
	}

}
return battle