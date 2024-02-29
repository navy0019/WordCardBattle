local Union=require('lib.Union')

local Kruskal={}
function Kruskal.Solve(rooms,edgeList)
	--由於權重皆為1 省略sort edgeList的步驟
	local disjoint_set=Union.new(rooms)
	local edge_num=0
	local T = {}
	for i = 1, #edgeList do
		local edge = edgeList[i]

		if disjoint_set:search(edge.a)~= disjoint_set:search(edge.b) then
			edge_num=edge_num+1
			disjoint_set:union(edge.a ,edge.b)
			T[#T+1] = edge
		end

	end

	-- Return the MST
	return T
end
return Kruskal