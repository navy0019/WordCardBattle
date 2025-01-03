local TableFunc    = require('lib.TableFunc')
local StringRead   = require('lib.StringRead')
local StringDecode = require('lib.StringDecode')

local Deck_Act     = {
	deal = function(battle, machine, ...)
		local arg = { ... }
		local key_dic = machine.key_dic
		local stack = machine.stack
		local num = arg[1]
		local t = {}
		for i = 1, num do
			TableFunc.Push(t, battle.battleData.deck[i])
		end
		TableFunc.Push(machine.record, { act_name = 'deal', arg = { table.unpack(t) } })
		battle:DealProcess(num)
	end,
	drop = function(battle, machine, ...) end,
	hand_card = function(battle, machine, ...)
		local arg = { ... }
		local key_dic, stack, effect = machine.key_dic, machine.stack, machine.effect
		TableFunc.Push(stack, battle.battleData.hand)
	end,
	add_card_buff = function(battle, machine, ...)
		local arg = { ... }
		local key_dic, stack, effect = machine.key_dic, machine.stack, machine.effect
		local StateHandler = require('battle.StateHandler')
		StateHandler.Analysis_CardBuff(battle, key_dic.card, arg)
	end
}

return Deck_Act
