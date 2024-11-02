local cards = {
    testCard = {
        cost          = 3,
        type          = 'range',
        drop_to       = 'grave',
        use_condition = { 'select 1 enemy' },
        data          = { atk = 1, def = 3 },
        condition     = 'target.data.team_index >= 2',
        effect        = { 'condition (true:atk(card.data.atk * 2) to target ,false:atk(card.data.atk ) to target)' } --{ 'atk(card.data.atk) to target', 'add_buff (poison(round:2)) to target' },
    }
}
return cards
