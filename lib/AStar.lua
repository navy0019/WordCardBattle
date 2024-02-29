local function heuristic_dist(node_a ,node_b)
	return math.abs(node_a.pos[1]- node_b.pos[1])+math.abs(node_a.pos[2]- node_b.pos[2])
end
local function lowest_f_cost ( set, f_cost )

	local lowest, bestNode = math.huge, nil
	for k, node in pairs ( set ) do
		local score = f_cost[ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end
local function remove_node(set , node)
	table.remove(set , TableFunc.Find(set, node))
end
local function make_path(t,came_from ,goal)
	if came_from[goal] then
		TableFunc.Unshift(t , came_from[ goal ])
		return make_path(t ,came_from ,came_from[goal])
	else
		return t
	end
end

local AStar={}
function AStar.Solve(start,goal,map)
	local open ,close={start},{}	
	local came_from={}

	local g_cost , f_cost ={},{}
	g_cost[start]=0
	f_cost [ start ] = g_cost [ start ] + heuristic_dist( start, goal )
	while #open > 0 do
		local current = lowest_f_cost ( open, f_cost )
		if current ==goal then
			return make_path({},came_from ,goal)
		end

		remove_node ( open, current )
		TableFunc.Push(close , current)	

		for k,neighbor in pairs(current.connect) do
			if not TableFunc.Find(close , neighbor) then
				local temp = g_cost[ current ] + heuristic_dist( current, neighbor )
				if not TableFunc.Find(open , neighbor) or temp < g_cost[ neighbor ] then
					came_from[neighbor]=current
					g_cost[ neighbor ] = temp
					f_cost[ neighbor ] = g_cost[ neighbor ] + heuristic_dist ( neighbor, goal )
					if not TableFunc.Find(open , neighbor) then
						TableFunc.Push(open , neighbor)
					end
				end
			end
		end
	end
end

return AStar