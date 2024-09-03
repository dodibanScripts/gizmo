
local usingGizmo = false
local editingStop = false

local function toggleNuiFrame(bool)
    usingGizmo = bool
    SetNuiFocus(bool, bool)
end

local function DrawText3D(x, y, z, text)
    local r, g, b, a = 255, 255, 255, 255
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    local str = CreateVarString(10, "LITERAL_STRING", text, Citizen.ResultAsLong())


    if onScreen then
        SetTextScale(0.25, 0.25)
        SetTextFontForCurrentCommand(6)
        SetTextColor(r, g, b, a)
        SetTextCentre(1)
        DisplayText(str, _x, _y + 0.09)
    end
end

-- local function useGizmo(handle)
--     SendNUIMessage({
--         action = 'setGizmoEntity',
--         data = {
--             handle = handle,
--             position = GetEntityCoords(handle),
--             rotation = GetEntityRotation(handle)
--         }
--     })

--     toggleNuiFrame(true)
--     MC.StartFocus(GetCurrentResourceName())
--     while usingGizmo do
--         local coords = GetEntityCoords(handle)
--         DrawText3D(coords.x, coords.y + 1.0, coords.z - 0.5, "Current Mode: Translate\n[W] - Translate Mode\n[R] - Rotate Mode\n[LALT] - Place On Ground\n[Esc] - Done Editing - Stop Editing\n[Backspace] ")
--         SendNUIMessage({
--             action = 'setCameraPosition',
--             data = {
--                 position = GetFinalRenderedCamCoord(),
--                 rotation = GetFinalRenderedCamRot(0)
--             }
--         })
--         Wait(0)
--     end
--     local data = {
--         handle = handle,
--         position = GetEntityCoords(handle),
--         rotation = GetEntityRotation(handle)
--     }
--     SetTimeout(1000, function()
--         editingStop = false
--     end)
--     return not editingStop and data or nil
-- end

local function useGizmo(handle)
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = handle,
            position = GetEntityCoords(handle),
            rotation = GetEntityRotation(handle)
        }
    })

    toggleNuiFrame(true)
 
    -- Configurar o grupo de prompts e criar os prompts
    local gizmoPromptGroup = GetRandomIntInRange(0, 0xffffff)
    local prompts = {}

    local function createPrompt(text, control, action)
        local prompt = Citizen.InvokeNative(0x04F97DE45A519419)
        PromptSetControlAction(prompt, control)
        PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', text))
        PromptSetEnabled(prompt, false)
        PromptSetVisible(prompt, false)
        PromptSetHoldMode(prompt, false)
        PromptSetGroup(prompt, gizmoPromptGroup)
        PromptRegisterEnd(prompt)
        table.insert(prompts, {prompt = prompt, control = control, action = action})
    end

    -- Criação dos prompts para controlar o gizmo
    createPrompt('Adjust object', 0x8FD015D8, 'adjust_mode') -- W
    createPrompt('Turn mode', 0x26E9DC00, 'rotate_mode') -- R
    createPrompt('Place on ground', 0xCEFD9220, 'place_on_ground') -- LALT
    createPrompt('Confirm', 0x8CC9CD42, 'stop_editing') -- Esc
    createPrompt('To go back', 0x308588E6, 'cancel') -- Backspace

    while usingGizmo do
        local coords = GetEntityCoords(handle)
        
        -- Ativando o grupo de prompts
        PromptSetActiveGroupThisFrame(gizmoPromptGroup, CreateVarString(10, 'LITERAL_STRING', "Ajustar Objeto"))
        
        for _, promptInfo in ipairs(prompts) do
            PromptSetEnabled(promptInfo.prompt, true)
            PromptSetVisible(promptInfo.prompt, true)

            if IsControlJustPressed(0, promptInfo.control) then
                if promptInfo.action == 'adjust_mode' then
                    -- Implementar lógica de ajuste aqui
                elseif promptInfo.action == 'rotate_mode' then
                    -- Implementar lógica de rotação aqui
                elseif promptInfo.action == 'place_on_ground' then
                    -- Implementar lógica de colocar no chão aqui
                elseif promptInfo.action == 'stop_editing' then
                    -- Parar a edição
                    usingGizmo = false
                    break
                elseif promptInfo.action == 'cancel' then
                    -- Cancelar a edição
                    usingGizmo = false
                    editingStop = true
                    break
                end
            end
        end

        SendNUIMessage({
            action = 'setCameraPosition',
            data = {
                position = GetFinalRenderedCamCoord(),
                rotation = GetFinalRenderedCamRot(0)
            }
        })
        Wait(0)
    end

    local data = {
        handle = handle,
        position = GetEntityCoords(handle),
        rotation = GetEntityRotation(handle)
    }

    SetTimeout(1000, function()
        editingStop = false
    end)

    return not editingStop and data or nil
end


RegisterNUICallback('moveEntity', function(data, cb)
    local entity = data.handle
    local position = data.position
    local rotation = data.rotation

    SetEntityCoords(entity, position.x, position.y, position.z, false, false, false, false)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 0, false)
    cb('ok')
end)

RegisterNUICallback('placeOnGround', function(data, cb)
    PlaceObjectOnGroundProperly(data.handle, false)
    cb('ok')
end)

RegisterNUICallback('finishEdit', function(data, cb)
    toggleNuiFrame(false)
   
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    cb('ok')
end)

RegisterNUICallback('swapMode', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('stopEditing', function(data, cb)
    TriggerEvent('deleteBox')
    ClearPedTasks(PlayerPedId())
    toggleNuiFrame(false)

    editingStop = true
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    cb('ok')
end)


exports("useGizmo", useGizmo)
