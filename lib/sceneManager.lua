local List = require('lib.linkedList')
local SceneMgr={}
function AddScene( sceneMgr,tableType,scene)
	local name = scene.name
	if tableType==sceneMgr.NormalScene then
		tableType[name]=scene
	elseif getmetatable(tableType)==List.metatable  then
		tableType:Append(scene)
	end
end

function Switch( sceneMgr,tableType,sceneName,event)
	if sceneMgr.CurrentScene ~= nil then
		if event then
			event:Emit('Exit')
		end
		sceneMgr.CurrentScene.Exit()
	end
	local name = sceneName
	if getmetatable(tableType)==List.metatable  then
		name = type(sceneName)=='string' and sceneMgr.Adventure.head or sceneName
		--print('list '..type(name),name)
		sceneMgr.CurrentScene = name
	elseif tableType==sceneMgr.NormalScene then
		if type(sceneName) == 'table'then
			name= sceneName.name
		end
		sceneMgr.CurrentScene = tableType[name]

	end
	if sceneMgr.CurrentScene ~= nil then
		--print(sceneMgr.name..'Enter!!!')
		if event then
			event:Emit('Enter')
		end
		sceneMgr.CurrentScene.Enter()
	end

end

function Contain( searchTable,scene )
	for k,v in pairs(searchTable) do
		if v == scene then
			return true
		end
	end
	return false
end

SceneMgr.default={Contain=Contain ,Switch=Switch ,AddScene=AddScene}
SceneMgr.metatable={}
function SceneMgr.new()
	local o = {CurrentScene=nil,NormalScene={},Adventure=List.new({head=nil,tail=nil,length=0})}
	setmetatable(o,SceneMgr.metatable)
	return o
end
SceneMgr.metatable.__index=function (table,key) return SceneMgr.default[key] end

return SceneMgr