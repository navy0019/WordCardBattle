local TableFunc = require("lib.TableFunc")
local StringRead = require('lib.stringRead')

local BattlePrint={}
local function MakeState(char)
	local tab = {}
	for k,v in pairs(char.data.state) do
		for stateTab, s in pairs(v) do
			local word = s.name..' '..s.round..'   '
			table.insert(tab,word )
		end
	end

	return tab
end
local function FillEmpty(num)
	local s=''
	for i=1,num do
		s=s..' '
	end
	return s 
end
function GetCharSize(char)
	if not char then
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end
end

function GetUtf8Len(str)
	local len = 0 
	local currentIndex = 1 
	while currentIndex <= #str do 
		local char = string.byte(str,currentIndex) 
		currentIndex = currentIndex + GetCharSize(char) 
		len = len + 1 
	end 
	return len 
end
function StrToTab( s )
	local t={}
	local currentIndex = 1 
	while currentIndex <= #s do 
		local char = string.byte(s,currentIndex) 
		table.insert(t,s:sub(currentIndex , currentIndex+GetCharSize(char)-1 ))
		currentIndex = currentIndex + GetCharSize(char) 		
	end 
	return t
end
function BattlePrint.PrintCharacter(battle)
	local monsterData = battle.characterData.monsterData
	local heroData = battle.characterData.heroData
	--TableFunc.Dump(heroData)
	local nameStr = {}
	local dataStr = {}
	local stateStr = {}
	local thinkStr = {}	

	local len =  #heroData >= #monsterData and #heroData or #monsterData
	local strWidth = 54
	local empty = ''

	for i=1,len do
		nameStr[i]=''
		dataStr[i]=''
		stateStr[i]=''
		thinkStr[i]=''

		local hero = heroData[i]

		if hero then	
			nameStr[i]=nameStr[i]..hero.key
			dataStr[i]=dataStr[i]..'hp:'..hero.data.hp..' atk:'..hero.data.atk..' shield:'..hero.data.shield
			local heroState = MakeState(hero)
			stateStr[i]=stateStr[i]..table.concat(heroState,' ')
		end

		local mon = monsterData[i]
		if mon then
			local num = strWidth-string.len(nameStr[i])
			empty=FillEmpty(num)--print(num)
			nameStr[i]=nameStr[i]..empty..mon.key

			num = strWidth-string.len(dataStr[i])
			empty=FillEmpty(num)--print(num)	
			dataStr[i]=dataStr[i]..empty..'hp:'..mon.data.hp..' atk:'..mon.data.atk..' shield:'..mon.data.shield

			num = strWidth-string.len(stateStr[i])
			empty=FillEmpty(num)--print(num)	
			local monState = MakeState(mon)
			stateStr[i]=stateStr[i]..empty..table.concat(monState,' ')..'\n'
		else
			stateStr[i]=stateStr[i]..'\n'
		end
	end
	for i=1,len do
		print(nameStr[i])
		print(dataStr[i])
		print(stateStr[i])
	end
end
function BattlePrint.PrintCard( battle )
	local hand = battle.battleData.hand
	local strWidth = 54
	local roundSate = battle.battleData.round%2==0 and '敵方回合' or '玩家回合'
	local roundStr = '回合'..battle.battleData.round..'  '..roundSate
	local tab = ''
	local num = strWidth-string.len(roundStr)
	tab=FillEmpty(math.floor(num/2))
	print('\n'..tab..roundStr)
	
	local battleData = '行動點數: '..battle.battleData.actPoint..'  牌堆: '..#battle.battleData.deck..'  棄牌堆: '..#battle.battleData.drop..'  消失牌堆: '..#battle.battleData.disappear
	num = math.abs(strWidth-string.len(battleData)) *3
	tab=FillEmpty(math.floor(num/2))
	print(tab..battleData)

	local hand = '  '
	local choose = battle.machine.choose
	local currentCard = choose[1]

	for k,card in pairs(battle.battleData.hand) do
		hand=hand..k..' '
		if card == currentCard then
			hand=hand..card.name..'(cost:'..card.data.cost..')(已選擇)'
		else
			hand=hand..card.name..'(cost:'..card.data.cost..')'
		end
		if k < #battle.battleData.hand then
			hand=hand..'\t'
		end
	end
	print(hand)

	--Make Info
	for k,card in pairs(battle.battleData.hand) do
		local info_tab = StringRead.StrPrintf(card.info,card)
		--print('info_tab ',card.info,#info_tab)
		local temp = ''
		for i=2,#info_tab,2 do
			temp=temp..info_tab[i]
		end
		print(k..'  '..temp,card.master.key)
	end

end
return BattlePrint