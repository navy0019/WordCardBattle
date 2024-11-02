local normal_event = {
    other_party =
    {
        result_1 = {
            reward = { money = 200 }
        },
        result_2 = {
            expose_map = { key = 'shop' }
        },
    },
    tresure_trap =
    {
        result_1 = {
            battle = {
                monster = { 'm_small_1', 'm_XL_1' },
                reward = { money = 10, rare_card = { 1 } }
            }
        },
        result_3 = {
            require = { trait = 'dectect' },
            battle = {
                monster = { 'm_XL_1', 'm_XL_1' },
                reward = { money = 10, rare_card = { 1 } }
            }
        },
    }
}
return normal_event
