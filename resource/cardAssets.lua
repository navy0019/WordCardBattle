local Card = require("lib.card")
local StringDecode=require('lib.StringDecode')
local TableFunc=require('lib.TableFunc')

local CardAssets = {}
function CardAssets.Init(card_table)
	--print('Init card')
    for k,card in pairs(card_table) do
        for key,value in pairs(card) do
            if key =='use_condition' then            	
            	StringDecode.TransToTable(card, key ,value)
                for i,str in pairs(card[key]) do
                	local select_type ,number ,race = StringDecode.Split_by(str,'%s')
                	number = tonumber(number) and tonumber(number) or number
                	card.use_condition[i]={select_type ,number ,race }
                end
           	elseif key =='data'  then
            	StringDecode.TransToTable(card, key ,value)

            	card[key]=StringDecode.TransToDic(card[key])
            	--[[for i,t in pairs(card.data) do
            		card.data[i]={{from='oringin',value=t }}
            	end ]]         
            elseif key=='effect' or key =='type' then
            	StringDecode.TransToTable(card, key ,value)
            end
        end
    end
end
function CardAssets.instance( key,character)
	--print('key',key)
	local o = TableFunc.DeepCopy(_G.Resource.card[key])
	--[[if test	then
		o = TableFunc.DeepCopy(_G.Resource.test_card[key])
	else
	 	o = TableFunc.DeepCopy(_G.Resource.card[key])
	end]]
	--print(key,o)
	o.key = key
	o.level =1
	o.holder =character
	o.state={}
	--print('o key',_G.Resource.translate[o.key],o.key)
	assert(_G.Resource.translate[o.key] , 'can\'t find '..key..' in translate file ,need check translate.cd ')
	o.name = _G.Resource.translate[o.key]['name']
    o.info = _G.Resource.translate[o.key]['info']

	--[[o.getAsset=function(o,index)
				assert(_G.Resource.card[o.key][index],'don\'t have key '..index) 
				return _G.Resource.card[o.key][index]
			   end]]
	--o.sprite =nil
	--o.handPos =1
	--o.isLock =false

	--o.updateWord=updateWord
	--o:updateWord(Cards[key].info)
	
	local card = Card.new(o)
	--print('instance card!')
	--TableFunc.Dump(card)
	return card
end
return CardAssets