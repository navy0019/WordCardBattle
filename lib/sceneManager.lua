local List = require('lib.linkedList')
local SceneMgr={}
function AddScene( sceneMgr,tableType,scene)
	local name = scene.name

	tableType[name]=scene

end

function Switch( sceneMgr, sceneName ,event)
	if sceneMgr.CurrentScene ~= nil then
		if event then
			event:Emit('Exit')
		end
		sceneMgr.CurrentScene.Exit()
	end
	local name = sceneName

	sceneMgr.CurrentScene = sceneMgr.NormalScene[name]

	if sceneMgr.CurrentScene ~= nil then

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
	local o = {CurrentScene=nil,NormalScene={}}--,AdventureScene={},Adventure=List.new({head=nil,tail=nil,length=0})}
	setmetatable(o,SceneMgr.metatable)
	return o
end
SceneMgr.metatable.__index=function (table,key) return SceneMgr.default[key] end

return SceneMgr