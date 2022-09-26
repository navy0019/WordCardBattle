local TableFunc = require("lib.TableFunc")
local SaveFileMgr=require('lib.saveManager')

local keys={
	up_money=500,
	up_chest=5
}
local Item={List={},Backpack={}}
function Item.Sort( self )
	table.sort(self.Backpack , function(a, b) return a.key < b.key end)
end
function Item.AddList(obj)
	local p = TableFunc.Find(Item.List, obj.key, 'key')
	if p then
		Item.List[p].value = Item.List[p].value+obj.value
	else
		table.TableFunc.Push(Item.List,obj)
	end
end
function Item.UpdateFromSaveFile( )
	Item.List = SaveFileMgr.CurrentSave.ItemList
	Item.Backpack = SaveFileMgr.CurrentSave.Backpack
end
function Item.AddBackpack( obj )
	local value = obj.value
	local index = 1 
	while value > 0 do
		for i=index ,#Item.Backpack do
			if Item.Backpack[i].key == obj.key then
				local cost = keys[obj.key] - Item.Backpack[i].value
				Item.Backpack[i].value=math.min(Item.Backpack[i].value+value , keys[obj.key])
				value=value-cost
			end
		end
		if value > 0 then
			table.TableFunc.Push(Item.Backpack,{key=obj.key,name=obj.name,value=math.min(value , keys[obj.key])})
			value = value - Item.Backpack[#Item.Backpack].value
		end
		index=index+1	
	end
end
function Item.Add(obj)
	Item.AddList( obj )
	Item.AddBackpack( obj )
end
return Item