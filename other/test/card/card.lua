local cards = {
    testCard = {
        cost          = 3,
        type          = 'range',
        drop_to       = 'grave',
        use_condition = { 'select 2 enemy' },
        data          = { atk = 'holder.data.atk', def = 3 },
        condition     = 'target.data.team_index >= 1', --
        effect        = { 'add_buff( bless) to holder', 'add_buff( power_up (round:card.data.atk)) to holder' }
        --'add_buff( power_up (round:card.data.atk)) to holder'
        --'atk(card.data.atk) to target'
        --'assign_value(holder.data.atk+1 ,atk) to holder', 'atk(card.data.atk) to target'
        --'atk(card.data.atk) to random(1 ,enemy)'
        --'atk(card.data.atk) to target', 'add_buff( poison (round:1)) to target'
        --'condition (true:atk(card.data.atk * 2) to target ,false:atk(card.data.atk ) to target)'
        --'atk(card.data.def + random(1~card.data.atk)) to target'
    },
    --[[ grow_up_and_atk = {
        cost          = 1,
        type          = 'melee',
        drop_to       = 'grave',
        use_condition = { 'select 1 enemy' },
        data          = { atk = 'holder.data.atk' },
        effect        = { 'assign_value(holder.data.atk+1 ,atk) to holder', 'atk(card.data.atk) to target' },
    },]]
}
return cards
