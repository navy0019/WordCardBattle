local json = require('lib.json')
local TableFunc = require('lib.TableFunc')
local StringDecode = require('lib.StringDecode')

local Resource = { card = {}, character = {}, translate = {}, state = {}, card_state = {}, map_config = {}, normal_event = {}, rare_event = {} }
Resource.color = { white = { 1, 1, 1, 1 }, black = { 0, 0, 0, 1 } }

Cmd = _G.Cmd and _G.Cmd or (CurrentOs == 'Mac' and 'ls ' or 'dir ')
Slash = _G.Slash and _G.Slash or (CurrentOs == 'Mac' and '/' or '\\')

local card_path = _G.Path .. 'card'
local card_popen = io.popen(_G.Cmd .. card_path)

local character_path = _G.Path .. 'character'
local character_popen = io.popen(_G.Cmd .. character_path)

local translate_path = _G.Path .. 'translate'
local translate_popen = io.popen(_G.Cmd .. translate_path)

local state_path = _G.Path .. 'state'
local state_popen = io.popen(_G.Cmd .. state_path)

local normal_event_path = _G.Path .. 'normal_event'
local normal_event_popen = io.popen(_G.Cmd .. normal_event_path)

local rare_event_path = _G.Path .. 'rare_event'
local rare_event_popen = io.popen(_G.Cmd .. rare_event_path)

local map_config_path = _G.Path .. 'setting'
local map_config_popen = io.popen(_G.Cmd .. map_config_path)


function Resource.GetAssets(popen, path, tab)
    local t = tab or {}
    if popen then
        local s = popen:read("*a")
        --print('s',s)
        local str_tab = StringDecode.Split_comma_enter(s)
        for k, v in pairs(str_tab) do
            local dot = v:find('%.')
            local file_extension = v:sub(dot + 1, #v)
            local is_cd = file_extension == 'cd' and true or false --#v-(#format-1)
            --print('cd? ',file_extension ,is_cd)
            local p = v:find('%s[^%s]*$')
            local file_name = p and v:sub(p + 1, #v) or v
            local file_path = path .. _G.Slash .. file_name
            if is_cd then
                --local p = v:find('%s[^%s]*$')
                --local file_name = p and v:sub(p+1,#v) or v
                --print('cd',p ,file_name)
                --local file_path =path.._G.Slash..file_name
                --print('file_path',file_path)
                local data = StringDecode.Decode(file_path)
                --TableFunc.Dump(data)
                TableFunc.Merge(t, data)
            elseif file_extension == 'json' then
                --print(v:sub( dot+1 , #v))
                --print('json',file_path)
                local file = io.open(file_path, 'r')
                if file then
                    local content = file:read('*all')
                    local data = json.decode(content)
                    file:close()
                    --TableFunc.Dump(data)
                    TableFunc.Merge(t, data)
                end
            elseif file_extension == 'lua' then
                --print(file_path)
                local title_head, title_tail = file_path:find('WordCardBattle')
                local require_p              = file_path:sub(title_tail + 1, file_path:find('%.') - 1)
                local p                      = require_p:find('%a')
                require_p                    = require_p:sub(p, #require_p)
                require_p                    = require_p:gsub(_G.Slash, '.')
                --print('require_p', require_p)
                local data                   = require(require_p)
                --TableFunc.Dump(data)
                TableFunc.Merge(t, data)
            end
        end
        popen:close()
    else
        print("failed to read " .. path)
    end
    StringDecode.TransDataType(t)
    --TableFunc.Dump(t)
    if not tab then return t end
end

function Resource.Init()
    Resource.GetAssets(card_popen, card_path, Resource.card)
    --CardAssets.Init(Resource.card)

    Resource.GetAssets(character_popen, character_path, Resource.character)
    --CharacterAssets.Init(Resource.character)

    Resource.GetAssets(translate_popen, translate_path, Resource.translate)
    --Msg.Init(Resource.translate)

    Resource.GetAssets(state_popen, state_path, Resource.state)
    -- StateAssets.Init(Resource.state)

    Resource.GetAssets(normal_event_popen, normal_event_path, Resource.normal_event)
    --StateAssets.Init(Resource.normal_event)

    Resource.GetAssets(rare_event_popen, rare_event_path, Resource.rare_event)
    --StateAssets.Init(Resource.rare_event)
end

function Resource.Init_Test()
    local test_card_path = _G.Path .. _G.Slash .. 'other' .. _G.Slash .. 'test' .. _G.Slash .. 'card'
    local test_card_popen = io.popen(_G.Cmd .. test_card_path)
    Resource.GetAssets(test_card_popen, test_card_path, Resource.card)
    --CardAssets.Init(Resource.card)

    local translate_path = _G.Path .. _G.Slash .. 'other' .. _G.Slash .. 'test' .. _G.Slash .. 'translate'
    local translate_popen = io.popen(_G.Cmd .. translate_path)
    Resource.GetAssets(translate_popen, translate_path, Resource.translate)
    --Msg.Init(Resource.translate)

    local state_path = _G.Path .. _G.Slash .. 'other' .. _G.Slash .. 'test' .. _G.Slash .. 'state'
    local state_popen = io.popen(_G.Cmd .. state_path)
    Resource.GetAssets(state_popen, state_path, Resource.state)
    --StateAssets.Init(Resource.state)
end

return Resource
