local mathExtend={}
function mathExtend.clamp(num, min, max)
	if num < min then
		num = min
	elseif num > max then
		num = max    
	end
	
	return num
end
function mathExtend.round(num)
	return math.floor(num+0.5)
end
function mathExtend.sum(tab ,key)
	local num =0
	if key then
		for k,v in pairs(tab) do
			num= num+tab[key]
		end
	else
		for k,v in pairs(tab) do
			num= num+v
		end
	end
	return num
end
return mathExtend