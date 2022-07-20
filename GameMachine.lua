local GameMachine={stop=false}

function GameMachine.Init()
	GameMachine.LogicScenesMgr  = require('LogicScenesMgr')
	GameMachine.ViewScenesMgr  = require('ViewScenesMgr')
	GameMachine.Control  = require('Control')

	GameMachine.Control.Init(GameMachine.ViewScenesMgr  ,GameMachine.LogicScenesMgr)
	GameMachine.LogicScenesMgr.Init()
	GameMachine.ViewScenesMgr.Init()
end

function GameMachine.Update( ... )

	GameMachine.LogicScenesMgr.Update()
	GameMachine.ViewScenesMgr.Update()
	GameMachine.Control.KeyPress(GameMachine)

end

return GameMachine