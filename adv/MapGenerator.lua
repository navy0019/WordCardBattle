local Room = require('adv.Room')
local Kruskal = require('lib.Kruskal')

local function Sort_Room_By_Dist(map ,rooms ,goal_room)
	local t ={}
	local A_Star=require('lib.Astar')
	for k,room in pairs(rooms) do
		if room~= goal_room then
			local len = #A_Star.Solve( goal_room , room ,map)
			--print('len',len ,t[len] ,type(len))
			if t[len] then
				TableFunc.Push(t[len] ,room)
			else
				t[len] = { room }
			end

		end
	end
	return t

end
local function Pick(t , num)
	local t = TableFunc.ShallowCopy(t)
	local pick={}
	for i=1,num do
		local num=_G.RandomMachine:Random(#t)
		TableFunc.Push(pick, t[num]) 
		table.remove(t ,num)
	end
	return pick
end
local function Get_Neighbor(map,i,j)
	local t ={}
	--print('map',map ,#map ,i,j)
	if i-1 > 0 and map[i-1][j].type=='room' then
		TableFunc.Push(t ,map[i-1][j])
	end
	if i+1 <= #map and map[i+1][j].type=='room' then
		TableFunc.Push(t ,map[i+1][j])
	end
	if j-1 > 0 and map[i][j-1].type=='room'then
		TableFunc.Push(t ,map[i][j-1])
	end
	if j+1 <= #map and map[i][j+1].type=='room'then
		TableFunc.Push(t ,map[i][j+1])
	end

	return t
end
local function Connect_Room(mst ,rooms,neighbor_map)
	for k,edge in pairs(mst) do
		local room1 = rooms[edge.a]
		local room2 = rooms[edge.b]
		room1:Connect(room2)
	end

	--隨機形成環
	for k,room in pairs(rooms) do
		local neighbor= neighbor_map[k]
		for i,n in pairs(neighbor) do
			if not room:Is_connect(n) and RandomMachine:Random(10) >=9 then
				room:Connect(n)
			end
		end
	end
end

local function Make_Edge(rooms ,neighbor_map)
	local edge={}
	for i,current_room in pairs(rooms)   do
		local current_neighbor = neighbor_map[i]
		for k,room in pairs(rooms) do
			if TableFunc.Find(current_neighbor , room) then
				TableFunc.Push(edge,{a=i,b=k,w=1})--起點 終點 權重
			end
		end
	end

	return edge
end
local function Set_Enter_Room(rooms)
	--print('set enter room')
	local enter_index= RandomMachine:Random(#rooms)
	local enter_room =rooms[ enter_index]
	enter_room:Set_Info('enter')

	--table.remove(rooms ,enter_index)
	return enter_room
end
local function Set_Specific_Room(dist ,rooms ,map)


	--[[local key_index = RandomMachine:Random( math.floor(#dist *0.3) ,#dist)
	--print('key_index',key_index) 
	local key_room =  dist[key_index][ RandomMachine:Random(#dist[key_index]) ]
	key_room:Set_Info('gem')
	table.remove(dist[key_index] ,TableFunc.Find(dist[key_index] ,key_room))
	if #dist[key_index] <= 0 then
		table.remove(dist , key_index)
	end
	
	local gem_dist = Sort_Room_By_Dist(map ,rooms ,key_room)
	for k,tab in pairs(gem_dist) do
		for i=#tab,1 do
			local room = tab[i]
			if room.event then
				table.remove(tab, i)
			end
		end
	end
	local gem_index = RandomMachine:Random( math.floor(#gem_dist *0.5) ,#gem_dist)
	--print('gem index',gem_index)
	local gem_room =  gem_dist[gem_index][ RandomMachine:Random(#gem_dist[gem_index]) ]
	gem_room:Set_Info('gem')]]

	--return exit_room  ,key_room,gem_room
end

local function Set_Room(rooms ,adv_data)
	--TableFunc.Dump(map_data)
	local map_data = adv_data.map_data
	local map_setting =	adv_data.map_setting		 
	local battle  , normal_event , rare_event = map_setting['battle'],map_setting['normal_event'] ,map_setting['rare_event']
	local t={
		battle=battle,
		normal_event=normal_event,
		rare_event=rare_event,
	}
	--print(battle_room ,empty_room, money_room , rare_room)
	function make_event()
		local chance_type={}
		if t['battle'] >0 then
			TableFunc.Push(chance_type,'battle')
		end
		if t['normal_event'] >0 then
			TableFunc.Push(chance_type,'normal_event')
		end
		if t['rare_event'] >0 then
			TableFunc.Push(chance_type,'rare_event')
		end

		if #chance_type > 0 then
			local number=_G.RandomMachine:Random(#chance_type)
			if number > 0 then
				local key =chance_type[number]
				--print('key',key ,number)
				t[key]=t[key]-1
				return chance_type[number]
			end
		end
	end
      
	for k,room in pairs(rooms) do
		if room.event =='empty' then
			local event = make_event()
			--print('make_event',event)
			if event and event =='battle' then
				room.battle = true
			elseif event then
				room:Set_Info(event)
			end
		end
	end
	--[[local s=''
	local i =1
	for k,v in pairs(rooms) do
		if v.event~='empty' then
			s=s..v.event..' '
			i=i+1
			if i > 5 then
				s=s..'\n'
				i=1
			end
		end
	end
	print(s)]]
end
local function Init(seed ,size)
	local length =math.floor(math.sqrt(size))
	local remaining = math.floor(size - math.pow(length,2))
	local map ,neighbor_map ,rooms ,border = {} ,{} ,{} ,{}
	--print('length ',length ,size,remaining)
	for i=1,length+2 do
		map[i]={}
		for j=1,length+2 do
			map[i][j]=Room.new(i,j)--{}
		end
	end
	map[1][1].type='wall'
	map[1][length+2].type='wall'
	map[length+2][1].type='wall'
	map[length+2][length+2].type='wall'

	for i=1,length+2 do 
		for j=1,length+2 do
			if not((i==j) or (i==1 and j ==length+2) or(i==length+2 and j==1) ) then
				if i ==1 or i ==length+2 then
					--print(i,j)
					map[i][j].type='wall'
					TableFunc.Push(border , map[i][j])
				elseif j==1 or j== length+2 then
					--print(i,j)
					map[i][j].type='wall'
					TableFunc.Push(border , map[i][j])				
				end

			end
		end

	end
	--print(#border)
	RandomMachine:Set_seed(seed)
	for i=1,remaining do
		--math.randomseed(seed)
		--local number = math.random(#choose)
		local number = RandomMachine:Random(#border)
		border[number].type='room'
		table.remove(border,number)
	end


	for i=1,length+2 do
		for j=1,length+2 do
			if map[i][j].type~='wall' then
				--	map[i][j].numbering=numbering
				TableFunc.Push(rooms ,map[i][j])
				local neighbor = Get_Neighbor(map,i,j)
				TableFunc.Push(neighbor_map,neighbor)
			end
		end
	end
	--print('neighbor ',#neighbor_map)
	return map ,neighbor_map ,rooms
end
local MapGenerator={}
MapGenerator.New_Map=function(adv_data)
	print('map_seed',adv_data.map_setting.map_seed)
	local seed = adv_data.map_setting.map_seed
	local size = adv_data.map_setting.size

	local map ,neighbor_map ,rooms = Init(seed,size)

	local edges=Make_Edge(rooms ,neighbor_map)
	local mst = Kruskal.Solve(rooms,edges)
	Connect_Room(mst,rooms,neighbor_map)

	local enter_room =Set_Enter_Room(rooms)
	adv_data.player_pos[1] = enter_room.pos[1]
	adv_data.player_pos[2] = enter_room.pos[2]
	print('enter pos ',enter_room.pos[1],enter_room.pos[2])

	local dist =Sort_Room_By_Dist(map ,rooms ,enter_room)
	local exit_room , key_room ,gem_room=Set_Specific_Room(dist ,rooms ,map)
	Set_Room(rooms, adv_data)

	local s =''
	--[[for k,v in pairs(map) do
		s=''
		for i,room in pairs(map[k]) do
			if room.type =='wall' then
				s =s..' '..room.type
			else
				s=s..' '..room.event
			end
			
		end
		print(s)
	end]]
	print('map' ,map)
	return map ,rooms
end
return MapGenerator
