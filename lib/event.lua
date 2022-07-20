local Event={
	blackSmith={
		info='鐵匠,目前無功能',
		Effect=function()end
	},
	campfire={
		info='營火,隊伍回復5生命',
		Effect=function(charData)
			for k,char in pairs(charData) do
				_G.Event:Emit('GetHit',char,5,false,true,battle)
			end
		end
	},
	potionTable={},
}
return Event