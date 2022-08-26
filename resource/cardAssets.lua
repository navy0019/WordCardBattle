local Card = require("lib.card")
local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

--local StringConvert = require("lib.stringConvert")

local CardAssets = {}
function CardAssets.Init(card_table)
	local data_map={'hp','act','atk','def','cost',}
    for k,v in pairs(card_table) do
        v.data={}
        for key,value in pairs(v) do
            if key =='use_condition' then
                if type(value)~='table' then                    
                    local select_type ,number ,race = StringDecode.split_by(value,'%s')
                    number = tonumber(number)~=nil and tonumber(number) or number
                    v.use_condition={{select_type ,number ,race}}
                else
                    for i,str in pairs(value) do
                        local select_type ,number ,race = StringDecode.split_by(str,'%s')
                        number = tonumber(number)~=nil and tonumber(number) or number
                        v.use_condition[i]={select_type ,number ,race }
                    end
                end
            elseif TableFunc.Find(data_map,key) then
                v.data[key]=value
                v[key]=nil            
            elseif key=='effect' and type(value)~='table' then
            	local w =value
            	--print('effect',w)
            	v[key]={w}
            end
        end
    end
end
function CardAssets.instance( key,character)
	--print('key',key)
	local o = TableFunc.Copy(_G.Resource.card[key])
	--[[if test	then
		o = TableFunc.Copy(_G.Resource.test_card[key])
	else
	 	o = TableFunc.Copy(_G.Resource.card[key])
	end]]
	--print(key,o)
	o.key = key
	--print('o key',_G.Resource.translate[o.key],o.key)
	o.name = _G.Resource.translate[o.key]['name']
    o.info = _G.Resource.translate[o.key]['info']
	o.getAsset=function(o,index)
				assert(_G.Resource.card[o.key][index],'don\'t have key '..index) 
				return _G.Resource.card[o.key][index]
			   end
	--o.sprite =nil
	--o.handPos =1
	--o.isLock =false
	o.level =1
	o.master =character
	--o.updateWord=updateWord
	--o:updateWord(Cards[key].info)
	
	local card = Card.new(o)
	return card
end
return CardAssets