local TableFunc=require('lib.TableFunc')
local StringSplit=require('lib.stringSplit')

local CardAssets =require('resource.cardAssets')
local CharacterAssets =require('resource.characterAssets')
local Msg = require('resource.Msg')

local Resource={card={},character={},translate={}}
Resource.color={white={1,1,1,1},black={0,0,0,1}}

local cmd = _G.CurrentOs  == 'Mac' and 'ls ' or 'dir '

local card_path = _G.path..'card'
local card_popen = io.popen(cmd..card_path)

local character_path = _G.path..'character'
local character_popen = io.popen(cmd..character_path)

local translate_path = _G.path..'translate'
local translate_popen = io.popen(cmd..translate_path)


function Resource.GetAssets( popen ,path ,tab)
    if popen then
        local s=popen:read("*a")
        --print('s',s)
        local t=StringSplit.split_comma_enter(s)
        for k,v in pairs(t) do         
            local is_file = v:sub(#v-3,#v) == '.txt' and true or false
            if is_file then 
                local slash = _G.CurrentOs  == 'Mac' and '/' or '\\' 
                
                local p = v:find('%s[^%s]*$')
                --print('v',v)
                --print('p',p)
                local file_name = p and v:sub(p+1,#v) or v  
                --print('filename',file_name)    
                local data = StringSplit.Decode(path..slash..file_name)
                --TableFunc.Dump(data)
                TableFunc.Merge(tab ,data)
            else
                --print('is folder')
            end
        end
        popen:close()
    else
        print("failed to read "..path)
    end
end

function Resource.Init()
    
    Resource.GetAssets( card_popen ,card_path ,Resource.card)
    CardAssets.Init(Resource.card)

    Resource.GetAssets( character_popen ,character_path ,Resource.character)
    CharacterAssets.Init(Resource.character)   

    Resource.GetAssets( translate_popen ,translate_path ,Resource.translate)
    Msg.Init(Resource.translate)
end
return Resource