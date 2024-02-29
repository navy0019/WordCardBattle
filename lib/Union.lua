local function search(self,i)
	if self.disjoint_set[i]==i then 
		return i 
	else
		self.disjoint_set[i] = search(self ,self.disjoint_set[i])
		return self.disjoint_set[i]
	end
end
local function union(self,a,b)
	self.disjoint_set[search(self,a)]=search(self,b)
end
local Union={}
Union.default={search=search,union=union}
Union.metatable={}
function Union.new(t)
	local o={disjoint_set={}}
	for k,v in pairs(t) do
		o.disjoint_set[k]=k
	end
	setmetatable(o , Union.metatable)
	return o
end

Union.metatable.__index=function (table,key) return Union.default[key] end
return Union