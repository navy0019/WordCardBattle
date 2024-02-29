local TableFunc=require('lib.TableFunc')
local StringDecode=require('lib.StringDecode')

local CardAssets =require('resource.cardAssets')
local CharacterAssets =require('resource.characterAssets')
local StateAssets=require('resource.stateAssets')
local Msg = require('resource.Msg')

local Resource={card={},character={},translate={},state={},card_state={},map_config={}}
Resource.color={white={1,1,1,1},black={0,0,0,1}}

cmd = _G.cmd and _G.cmd or (CurrentOs  == 'Mac' and 'ls ' or 'dir ')
slash = _G.slash and _G.slash or (CurrentOs  == 'Mac' and '/' or '\\' )

local card_path = _G.path..'card'
local card_popen = io.popen(_G.cmd..card_path)

local character_path = _G.path..'character'
local character_popen = io.popen(_G.cmd..character_path)

local translate_path = _G.path..'translate'
local translate_popen = io.popen(_G.cmd..translate_path)

local state_path = _G.path..'state'
local state_popen = io.popen(_G.cmd..state_path)

local map_config_path = _G.path..'setting'
local map_config_popen = io.popen(_G.cmd..map_config_path)


function Resource.GetAssets( popen ,path ,tab)
    local t = tab or {}
    if popen then
        local s=popen:read("*a")
        --print('s',s)
        local str_tab=StringDecode.Split_comma_enter(s)
        for k,v in pairs(str_tab) do
            local dot = v:find('%.')       
            local is_cd= v:sub( dot+1 , #v) == 'cd' and true or false--#v-(#format-1)
            --print('cd? ',v:sub( dot+1 , #v) ,is_cd)
            if is_cd then                 
                
                local p = v:find('%s[^%s]*$')
                local file_name = p and v:sub(p+1,#v) or v  
                
                local file_path =path.._G.slash..file_name   
                --print('file_path',file_path) 
                local data = StringDecode.Decode(file_path)
                --TableFunc.Dump(data)
                TableFunc.Merge(t ,data)
            else
                --print('is folder')
            end
        end
        popen:close()
    else
        print("failed to read "..path)
    end
    if  not tab then return t end
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
    local test_card_path = _G.path.._G.slash..'other'.._G.slash..'test'.._G.slash..'card'
    local test_card_popen = io.popen(_G.cmd..test_card_path)
    Resource.GetAssets( test_card_popen ,test_card_path ,Resource.card)
    CardAssets.Init(Resource.card)

    local translate_path = _G.path.._G.slash..'other'.._G.slash..'test'.._G.slash..'translate'
    local translate_popen = io.popen(_G.cmd..translate_path)
    Resource.GetAssets( translate_popen ,translate_path ,Resource.translate)
    Msg.Init(Resource.translate)

    local state_path = _G.path.._G.slash..'other'.._G.slash..'test'.._G.slash..'state'
    local state_popen = io.popen(_G.cmd..state_path)
    Resource.GetAssets( state_popen ,state_path ,Resource.state)
    StateAssets.Init(Resource.state)

end
return Resource