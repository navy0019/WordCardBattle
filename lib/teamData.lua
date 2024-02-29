local SaveMgr=require('lib.saveManager')
local TableFunc = require("lib.TableFunc")

local TeamData={AllHeros={},DefaultTeam={},CurrentDeafault=1}

function TeamData.FromSaveFile()	
	TeamData.DefaultTeam=SaveMgr.CurrentSave.DefaultTeam

	TeamData.CurrentDeafault=SaveMgr.CurrentSave.CurrentDeafault
	TeamData.CurrentTeam=SaveMgr.CurrentSave.CurrentTeam


end
function TeamData.ToSaveFile()
	SaveMgr.CurrentSave.DefaultTeam=TeamData.DefaultTeam

	SaveMgr.CurrentSave.CurrentDeafault=TeamData.CurrentDeafault
	SaveMgr.CurrentSave.CurrentTeam=TeamData.CurrentTeam

end
function TeamData.UpdateTeamSelected()
	for k,v in pairs(TeamData.AllHeros) do
		v.selected=false
	end

	for k,v in pairs(TeamData.CurrentTeam) do
		local num =TableFunc.Find(TeamData.AllHeros , v ,'name') --TeamData.Find(v)
		if num then
			TeamData.AllHeros[num].selected=true
		end
	end
	
end
function TeamData.ResetTeam()
	for k,v in pairs(TeamData.CurrentTeam) do
		TeamData.CurrentTeam[k]=nil
	end
	local num = TeamData.CurrentDeafault
	for k,v in pairs(TeamData.DefaultTeam[num]) do
		TableFunc.Push(TeamData.CurrentTeam, v)
	end
	TeamData.UpdateTeamSelected()
end
function TeamData.SaveTeam()
	local num = TeamData.CurrentDeafault
	for k,v in pairs(TeamData.DefaultTeam[num]) do
		TeamData.DefaultTeam[num][k]=nil
	end
	--SaveMgr.CurrentSave.DefaultTeam[num]={}
	for k,v in pairs(TeamData.CurrentTeam) do
		TableFunc.Push(TeamData.DefaultTeam[num], v)
	end
	TeamData.UpdateTeamSelected()
	TeamData.ToSaveFile()
	return true
end
function TeamData.CheckEmpty()
	for i=1,4 do
		local hero = TeamData.CurrentTeam[i]
		if hero == nil then
			--print('find empty '..i)
			return i
		end
	end
	return false
end
function TeamData.SetEmpty(obj)
	for i=1,4 do
		local name = TeamData.CurrentTeam[i]
		--print(name)
		if name==obj.name then
			--print('SetEmpty find '..i)
			TeamData.CurrentTeam[i]=nil
		end
	end
end

function TeamData.Switch(obj)
	if obj.selected==true then
		--print('switch to')
		TeamData.SetEmpty(obj)
		obj.selected=false
	elseif obj.selected==false then
		local p = TeamData.CheckEmpty()
		--print('switch ',p)
		if p ~=false then
			TeamData.CurrentTeam[p]=obj.name
			obj.selected = true
		end
	end
end
function TeamData.SwitchDefault(num)
	--print(num)
	TeamData.CurrentDeafault=num
	TeamData.CurrentTeam=TableFunc.DeepCopy(TeamData.DefaultTeam[num])
	print('SwitchDefault '..#TeamData.CurrentTeam)
	for k,v in pairs(TeamData.AllHeros) do
		local p = TableFunc.Find(TeamData.CurrentTeam ,v.name )
		if p then 
			--print('find')
			v.selected=true
		else
			--print('not find')
			v.selected=false
		end
	end
end
function TeamData.init()
	for i=1,16 do
		TableFunc.Push(TeamData.AllHeros,{name="hero"..i,selected=false,lock=true})
		if i<=6 then
			TeamData.AllHeros[i].lock = false
		end
	end

	TeamData.FromSaveFile()
	TeamData.UpdateTeamSelected()

	
end

return TeamData