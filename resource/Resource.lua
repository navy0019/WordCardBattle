local TableFunc=require('lib.TableFunc')
local StringDecode=require('lib.StringDecode')

local CardAssets =require('resource.cardAssets')
local CharacterAssets =require('resource.characterAssets')
local StateAssets=require('resource.StateAssets')
local Msg = require('resource.Msg')

local Resource={card={},character={},translate={},state={},card_state={}}
Resource.color={white={1,1,1,1},black={0,0,0,1}}

local cmd = _G.CurrentOs  == 'Mac' and 'ls ' or 'dir '
local slash = _G.CurrentOs  == 'Mac' and '/' or '\\' 

local card_path = _G.path..'card'
local card_popen = io.popen(cmd..card_path)

local character_path = _G.path..'character'
local character_popen = io.popen(cmd..character_path)

local translate_path = _G.path..'translate'
local translate_popen = io.popen(cmd..translate_path)

local state_path = _G.path..'state'
local state_popen = io.popen(cmd..state_path)


function Resource.GetAssets( popen ,path ,tab)
    if popen then
        local s=popen:read("*a")
        --print('s',s)
        local t=StringDecode.split_comma_enter(s)
        for k,v in pairs(t) do
            local format = 'cd'         
            local is_file = v:sub(#v-(#format-1)  , #v) == format and true or false
            if is_file then                 
                
                local p = v:find('%s[^%s]*$')
                local file_name = p and v:sub(p+1,#v) or v  
                --print('filename',file_name)    
                local data = StringDecode.Decode(path..slash..file_name)
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

    Resource.GetAssets( state_popen ,state_path ,Resource.state)
    StateAssets.Init(Resource.state)
end
function Resource.Init_Test()
    local test_card_path = _G.path..slash..'other'..slash..'test'..slash..'card'
    local test_card_popen = io.popen(cmd..test_card_path)
    Resource.GetAssets( test_card_popen ,test_card_path ,Resource.card)
    CardAssets.Init(Resource.card)

    local translate_path = _G.path..slash..'other'..slash..'test'..slash..'translate'
    local translate_popen = io.popen(cmd..translate_path)
    Resource.GetAssets( translate_popen ,translate_path ,Resource.translate)
    Msg.Init(Resource.translate)

    local state_path = _G.path..slash..'other'..slash..'test'..slash..'state'
    local state_popen = io.popen(cmd..state_path)
    Resource.GetAssets( state_popen ,state_path ,Resource.state)
    StateAssets.Init(Resource.state)

end
return Resource