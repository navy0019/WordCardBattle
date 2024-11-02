local TableFunc = require("lib.TableFunc")
local StringRead = require('lib.StringRead')
local StringDecode=require('lib.StringDecode')

local BattlePrint={}
local function MakeState(char)
	local tab = {}
	for k,v in pairs(char.state) do
		for stateTab, s in pairs(v) do
			local word = s.name..' '..s.round..'   '
			TableFunc.Push(tab,word )
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
function StrToTab( s ,num)
	local t={}
	local num=num or 1
	local w=''
	local width=0
	local currentIndex = 1 
	while currentIndex <= #s do 
		local char = string.byte(s,currentIndex) 
		TableFunc.Push(t ,s:sub(currentIndex , currentIndex+GetCharSize(char)-1 ))
		currentIndex = currentIndex + GetCharSize(char) 		
	end
	local final_tab={}
	if num > 1 then
		local times =  #t / num
		
		for i=1,times do
			for j=1,num do
				local temp =TableFunc.Shift(t)
				width=width+ math.min(2, GetCharSize(string.byte(temp,1))) 
				w=w..temp
			end
			TableFunc.Push(final_tab,{})
			local len = #final_tab
			final_tab[len].word=w
			final_tab[len].width=width
			w=''
			width=0		
		end
	end

	if #t>0 then 
		TableFunc.Push(final_tab,{})
		for i=1,#t do
			local temp =TableFunc.Shift(t)
			width=width+ math.min(2, GetCharSize(string.byte(temp,1))) 
			w=w..temp
		end
		local len = #final_tab
		final_tab[len].word=w
		final_tab[len].width=width  
	end

	--TableFunc.Push(final_tab,w)

	return final_tab
end
function BattlePrint.PrintMap(map,player_pos)
	local len = #map
	--print('player_pos',player_pos[1],player_pos[2])
	local t={}
	for i=1,len*3+len+1 do
		t[i]={}
	end
	for i=1,len*3+len+1 do
		for j=1,len*3+len+1 do
			t[i][j]='██'
		end
	end
	for i=1,len do
		for j=1,len do
			if map[i][j].type ~='wall' then
				local ci = i*3+i-1
				local cj = j*3+j-1
				--t[ci][cj]='  '
				if map[i][j].event=='enter' then
					--print('have enter',i,j)
					t[ci][cj]=' ⍈'--웃
				elseif map[i][j].event=='exit' then
					--print('have exit',i,j)
					t[ci][cj]=' ⍈'
				elseif map[i][j].event=='key' then
					--print('have key')
					t[ci][cj]='▥▥'

				elseif map[i][j].battle then
					t[ci][cj]=' ☢'
				elseif map[i][j].event~='empty' then
					t[ci][cj]=' !'

				else
					--print(map[i][j].event)
					t[ci][cj]='  '
				end

				if i == player_pos[1] and j == player_pos[2] then
					t[ci][cj]='웃'
				end
				t[ci+1][cj]='  '
				t[ci-1][cj]='  '
				t[ci][cj+1]='  '
				t[ci][cj-1]='  '
				t[ci+1][cj+1]='  '
				t[ci-1][cj-1]='  '
				t[ci+1][cj-1]='  '
				t[ci-1][cj+1]='  '
				--print('connect',#map[i][j].connect)
				for k,v in pairs(map[i][j].connect) do
					local self_x ,self_y = map[i][j].pos[1] ,map[i][j].pos[2]
					local t_x, t_y =v.pos[1] ,v.pos[2]
					local x ,y = self_x - t_x  ,self_y - t_y
					if x ~= 0 then
						local num = x > 0 and -2 or 2
						t[ci+num][cj]='  '
					end
					if y ~= 0 then
						local num = y > 0 and -2 or 2
						t[ci][cj+num]='  '
					end
				end
			end
		end
	end

	local s=''
	for i=1, #t do
		for j=1, #t do
			s=s..t[i][j]
		end
		s=s..'\n'
	end
	print(s)

	--[[local ns=''
	for i=1,len do
		for j=1,len do
			if map[i][j].room_info then
				local type=map[i][j].room_info.event:gsub('_room','')
				ns=ns..type..'\t'
			else
				ns=ns..'\t'
			end
		end
		ns=ns..'\n'
	end
	print(ns)]]
	

end
function BattlePrint.PrintCharacter(battle)
	print()
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
			stateStr[i]=stateStr[i]..empty..table.concat(monState,' ')

			num = strWidth-string.len(thinkStr[i])
			empty=FillEmpty(num)
			if mon.AI.machine.decide then
				--print('HAVE DECIDE')
				local complete = StringDecode.Trim_Command(mon.AI.machine.decide)
				--TableFunc.Dump(complete)
				thinkStr[i]=thinkStr[i]..empty..'決定對 '..complete[#complete]..' 使用 '..complete[1]..'\n\n'
			end
		else
			stateStr[i]=stateStr[i]..'\n'
		end
	end
	for i=1,len do
		print(nameStr[i])
		print(dataStr[i])
		print(stateStr[i])
		print(thinkStr[i])
	end
end

function BattlePrint.PrintCard( battle )
	local hand = battle.battleData.hand
	local strWidth = 54
	local roundSate = battle.battleData.round%2==0 and '敵方回合' or '玩家回合'
	local roundStr = '回合'..battle.battleData.round..'  '..roundSate
	local tab = ''
	local num = strWidth-string.len(roundStr)
	tab=FillEmpty(math.floor(num/1.5))
	print('\n'..tab..roundStr)
	
	local battleData = '行動點數: '..battle.battleData.actPoint..'  牌堆: '..#battle.battleData.deck..'  棄牌堆: '..#battle.battleData.drop..'  消失牌堆: '..#battle.battleData.disappear
	num = math.abs(strWidth-string.len(battleData)) *3
	tab=FillEmpty(math.floor(num/1.5))
	print(tab..battleData)

	local hand = '  '
	local choose = battle.input_machine.choose
	local currentCard = choose[1]

	for k,card in pairs(battle.battleData.hand) do
		hand=hand..'c'..k..' '
		if card == currentCard then
			hand=hand..card.name..'(cost:'..card.cost..')(已選擇)'
		else
			hand=hand..card.name..'(cost:'..card.cost..')'
		end
		if k < #battle.battleData.hand then
			hand=hand..'   '
		end
	end

	print('\t輸入 c1 ~ c'..#battle.battleData.hand..' 選擇卡片 , 2 取消選取 , 3 結束回合\n')
	print(hand)
	
	--定位數字作為info的錨點
	local hand_num_pos={}
	local temp_index=1
	for v in string.gmatch(hand, '%d+') do
    	TableFunc.Push(hand_num_pos, v)
	end

	for k,v in pairs(hand_num_pos) do
		local p = hand:find(v, temp_index)
		hand_num_pos[k]=p
		temp_index=p+1
	end

	for i=#hand_num_pos,1,-1 do
		if i%2 == 0 then
			table.remove(hand_num_pos,i)
		end
	end

	--Make Info
	local info ={}
	for k,card in pairs(battle.battleData.hand) do
		info[k] = StringRead.StrPrintf(card.info ,card ,battle)
		
		--print('battle print',info[k])
		local temp = ''
		for index=2,#info[k],2 do 
			temp = temp..info[k][index]
		end
		info[k]=StrToTab(temp,5)--temp
	end

	local len = 1
	for k,v in pairs(info) do
		len = math.max(len,#v)
	end


	for i=1,len  do
		local w =''
		local width=0
		for k,v in pairs(info) do
			local num =  hand_num_pos[k]-k-width
			--print('num',hand_num_pos[k]-k ,width ,num)
			local empty = FillEmpty(math.max(num,0))
			if info[k][i] then
				w=w..empty..info[k][i].word
				width =width+info[k][i].width+num
			end
		end
		print(w)
	end
end
return BattlePrint