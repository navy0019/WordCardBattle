local Preview ={}

Preview.Card_Preview = function(card)
	local preview
	--TableFunc.Dump(card.info)
	for k,v in pairs(card.info) do
		for key in s:gmatch("{(.-)}") do
			print(key)
		end
	end
	return preview

end

return Preview