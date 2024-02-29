local json = require('lib.json')

local SaveMgr={CurrentSave=nil,SaveData={}}
--local filepaths = package.path--love.filesystem.getSource( )
function SaveMgr.LoadFileList()
	--print('check save')
	SaveMgr.SaveData={}
	for i=1,2 do
		local check=io.open(_G.path..'save/savedata_'..i..'.json', "r")
		if check then
			local data = SaveMgr.Load('savedata_'..i)
			TableFunc.Push(SaveMgr.SaveData , data)
		else
			TableFunc.Push(SaveMgr.SaveData , 'Empty')
		end
	end
	--print(#SaveMgr.SaveData)
end
function SaveMgr.Encode(data)

	local str=''
	local len =0 
	for k,v in pairs(data) do
		len=len+1
	end

	local index=0
	for key,value in pairs(data) do
		index=index+1
		local dataType = type(value)
		if index<len then
			str=str..'"'..key..'"'..":"..json.encode(value)..','..'\n'
		else
			str=str..'"'..key..'"'..":"..json.encode(value)
		end
	end
	return str
end
function SaveMgr.WriteToFile(str,fileName)
	local file = io.open(_G.path..'save/'..fileName..'.json','w+')
	file:write('{\n')
	file:write(str)
	file:write('\n}')
	file:close()
end
function SaveMgr.Save(func ,...)
	local data
	if type(func)=='function' then 
		func(...)
		data = SaveMgr.CurrentSave
	elseif type(func)=='table' then
		data=func
	else
		data = SaveMgr.CurrentSave
	end
	
	local str =SaveMgr.Encode(data)
	if str then
		SaveMgr.WriteToFile(str,data.FileName)
	else
		assert(nil,'can\'t save data')
	end

end
function SaveMgr.Decode(filename)
	local file = io.open(_G.path..'save'.._G.slash..filename..'.json','r')
	local content = file:read('*all')
	local data = json.decode(content)
	file:close()
	return data
end
function SaveMgr.Load(filename)
	local data=SaveMgr.Decode(filename)
	--print('讀取完成')
	return data
end

function SaveData(saveNum)
	local o ={
		FileName='savedata_'..saveNum,
		CurrentTeam={"hero1" ,"hero2" ,"hero3", "hero4"},
		DefaultTeam={ {"hero1" ,"hero2" ,"hero3" ,"hero4"} ,{}, {} },

		CurrentTeamData={},
		CurrentDeafault=1,
		CurrentScene='City'
	}
	return o

end
function SaveMgr.NewSaveFile(saveNum)
	local data = SaveData(saveNum)
	return data
end
function SaveMgr.DeleteSaveFile(saveNum)
	--local path = love.filesystem.getRealDirectory("/save/savedata_"..saveNum..".json")
	SaveMgr.SaveData[saveNum] = 'Empty'
	os.remove(_G.path..'save/savedata_'..saveNum..'.json')
end

return SaveMgr