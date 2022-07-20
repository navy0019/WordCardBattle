function Append(self,scene)--insert at tail
	local node = scene
	local current
	if self.head == nil then
		self.head = node
	else
		current = self.head
		while current.next ~=nil do
			current.next.previous=current
			current=current.next
		end
		current.next=node
		current.next.previous=current
		self.tail=node
	end
	self.length=self.length+1
end
function MoveTo(self,nodeName)
	local current = self.head
	while current.name ~=nodeName do
		if current.next == nil then
			assert(nil,'can'.."'"..'t Move to'..nodeName)
		end
		current=current.next

	end
	return current

end
function MoveHead(self,position)
	if position >=1 and position <= self.length then
		local current = self.head
		local previous
		local index = 1
		if self.head == nil then
			assert(self.head == nil,'empty List')
		elseif position == 1 then
			assert(nil,'choose node is head')
		elseif position == self.length then
			previous=current
			current=self.tail
			previous.next=nil
			self.tail.next=nil
			self.tail.previous=nil
			self.head=current
			self.length=1
		else
			while index+1 <= position do
				previous=current
				current=current.next
				self.length=self.length-1
				index=index+1
			end
			current.previous=nil
			previous.next=nil
			self.head=current
		end
	else
		assert(nil,'wrong position')
	end
end
function Contain(self,scene)
	local current = self.head
	if current ~= scene then
		while current.next~=nil do
			current=current.next
			if current == scene then
				return true
			end
		end
	else
		return true
	end
	return false
end
function Clear( self )
	self.head.next=nil
	self.head=nil
	self.tail=nil
	self.length=0
end
local List = {}
List.default={head=nil,tail=nil,length=0,Append=Append,MoveHead=MoveHead,Contain=Contain,Clear=Clear,MoveTo=MoveTo}
List.metatable={}
function List.new(o)
	setmetatable(o,List.metatable)
	return o
end
List.metatable.__index=function (table,key) return List.default[key] end

return List