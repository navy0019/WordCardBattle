local TableFunc = require("lib.TableFunc")
local Msg = require('resource.Msg')
local Show={}
local function MakeStatus(char)
	local tab = {}
	for k,v in pairs(char.state) do
		for statusTab, s in pairs(v) do
			local word = s.name..s.round
			TableFunc.Push(tab,word )
		end
	end

	return tab
end
local function makeTab(num)
	local s=''
	for i=1,num do
		s=s..' '
	end
	return s 
end
function Show.PrintEvent(event)
	local map = {
		blackSmith =Msg.msg('blackSmith'),
		campfire =Msg.msg('campfire'),
		potionTable =Msg.msg('potionTable')
	}
	w='\n'	
	local keynum = 1
	local door = #event.door >0 and event.door[1] or false
	if door then		
		w=w..keynum..':返回 '
		keynum=keynum + 1
	end
	for k,v in pairs(event.event) do		
		w=w..keynum..' :'..map[v]
		keynum=keynum + 1
	end
	w=w..keynum..':前往下一間 '
	print(w)
end
function Show.PrintTeamData(TeamData)
	w='\n'
	w =w..'CurrentTeam: '
	for k,v in pairs(TeamData.CurrentTeam) do
		w=w..v..', '
	end
	w=w..'\n'
	for i=1,3 do
		w=w..'Default '..i..' : '
		for k,v in pairs(TeamData.DefaultTeam[i]) do
			w=w..v..' , '
		end
		w=w..'  '
	end
	w=w..'\n\n'
	for i=1,6 do
		local hero = TeamData.AllHeros[i]
		w=w..hero.name
		if hero.selected then
			w=w..'(已選擇), '
		else
			w=w..' , '
		end
	end
	print(w)
end
function Show.PrintSaveData(SaveData)
	--print('選擇存擋!')
	local w = ''
	for k,v in pairs(SaveData) do
		if v~='Empty' then
			w=w..'存擋 '..k..' 英雄: '
			for i,name in pairs(v.CurrentTeam) do
				w=w..name..' ,'
			end
			w=w..' 刪除此存擋按'..k+2 ..'\n'
		else
			w=w..'空白 '..k..'\n'
		end
	end
	print(w)
end

function Show.PrintDialog(scene,battle,MapData)
	print()
	for k,v in pairs(scene.dialog.queue) do
		print(v)
	end
end
function Show.PrintItem(Item )
	local list = ''
	for k,v in pairs(Item.List) do
		list=list..v.name..' '..v.value
	end
	print(list)
end

return Show