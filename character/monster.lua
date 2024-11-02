local monster = {
    m_small_1 = {
        skill = {
            "attack",
        },
        race = "monster",
        AI_act = {
            "attack to hero(state: spell)",
        },
        data = {
            atk = 2,
            race = "monster",
            def = 1,
            hp = 1,
            shield = 0,
        },
        dropItem = "money 100",
    },
    m_XL_1 = {
        AI_act = {
            "attack to hero (1)",
            "attack to hero(2)",
        },
        skill = {
            "attack",
        },
        dropItem = "money 100",
        data = {
            atk = 4,
            race = "monster",
            def = 3,
            hp = 1,
            shield = 0,
        },
    },
    m_mid_1 = {
        skill = {
            "attack",
        },
        race = "monster",
        AI_act = {
            "attack to hero(state: spell)",
            "attack to hero (2)",
            "attack to enemy(1)",
        },
        data = {
            atk = 3,
            race = "monster",
            def = 5,
            hp = 1,
            shield = 0,
        },
        dropItem = "money 100",
    },
    m_mid_2 = {
        skill = {
            "attack",
        },
        race = "monster",
        AI_act = {
            "attack to hero (1)",
        },
        data = {
            atk = 5,
            race = "monster",
            def = 2,
            hp = 1,
            shield = 0,
        },
        dropItem = "money 100",
    },

}
return monster
