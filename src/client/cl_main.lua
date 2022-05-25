allPropertyLocations = nil; allPropertyPoints = nil; shellObject = nil; isInProperty = false; propertyPlayerIsIn = nil; currentPropertyPermissionLevel = nil; inPropertyPoints = nil; currentPropertyProps = nil;

Citizen.CreateThread(function()
    allPropertyLocations = lib.callback.await('bnl-housing:server:getAllPropertyLocations', 1500)
    RegisterAllPropertyPoints()
end)

RegisterNetEvent("bnl-housing:client:notify", function(data)
    lib.defaultNotify(data)
end)

function Play3DSound(sound, distance)
    SendNUIMessage({
        type = 'playSound',
        soundFile = sound,
        distance = distance
    })
end

function HelpNotification(message, duration)
    SetTextComponentFormat("STRING")
    AddTextComponentString(message)
    DisplayHelpTextFromStringLabel(0,0,1, duration or -1)
end

function RegisterAllPropertyPoints()
    Logger.Log('Registering all property points')

    if allPropertyPoints ~= nil then
        for _,point in pairs(allPropertyPoints) do
            point:remove()
        end
    end

    if allPropertyLocations ~= nil then
        for _,property in pairs(allPropertyLocations) do
            local entranceV3 = vector3(property.entrance.x, property.entrance.y, property.entrance.z)
            Logger.Log('Registering property point for property #' .. property.property_id .. ' at ' .. tostring(entranceV3))

            local point = lib.points.new(entranceV3, 10, {
                property_id = property.property_id,
            })

            local entered = false
            function point:nearby()
                DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 0, 150, 255, 155, false, true, 2, nil, nil, false)

                if self.currentDistance < 1 then
                    if not entered then
                        lib.showTextUI(locale('open_property_menu'))
                        entered = true
                    end

                    if IsControlJustReleased(0, 38) then
                        OpenPropertyEnterMenu(self.property_id)
                    end
                else
                    if entered then
                        lib.hideTextUI()
                        entered = false
                    end
                end
            end
        end
    end
end

function SpawnPropertyDecoration(property)
    local decoration = json.decode(property.decoration)
    local shellCoord = GetEntityCoords(shellObject)

    if currentPropertyProps == nil then
        currentPropertyProps = {}
    end

    for _,prop in pairs(decoration) do
        local propCoord = vector3(prop.x, prop.y, prop.z) + shellCoord

        local propObject = CreateObject(GetHashKey(prop.model), propCoord.x, propCoord.y, propCoord.z, true, true, true)
        SetEntityHeading(propObject, prop.heading)
        FreezeEntityPosition(propObject, true)
        SetEntityAsMissionEntity(propObject, true, true)
        table.insert(currentPropertyProps, propObject)
    end
end

function DespawnPropertyDecoration()
    if currentPropertyProps ~= nil then
        for _,prop in pairs(currentPropertyProps) do
            DeleteEntity(prop)
        end

        currentPropertyProps = nil
    end
end

function SpawnPropertyShell(property, shell)
    Logger.Log(string.format('Spawning shell #%s for property #%s', shell.id, property.id))

    if shellObject ~= nil or shellObject ~= 0 then
        DeleteEntity(shellObject)
    end

    entrance = json.decode(property.entrance)
    local shellSpawnLocation = vector3(entrance.x, entrance.y, entrance.z) - vector3(0,0, 50.0)
    local shellModel = GetHashKey(shell.spawn)
    shellObject = CreateObject(shellModel, shellSpawnLocation, false, false, false)
    FreezeEntityPosition(shellObject, true)
    SetEntityAsMissionEntity(shellObject, true, true)

    return shellObject
end

function HandlePropertyMenus(property)
    if inPropertyPoints ~= nil then
        for _,point in pairs(inPropertyPoints) do
            point:remove()
        end
    end
    inPropertyPoints = {}

    local shellCoord = GetEntityCoords(shellObject)
    local property_id = property.id
    
    local foot_entrance = shellCoord - property.shell.foot_entrance
    local foot_point = lib.points.new(foot_entrance, 5, {
        property_id = property.id,
        type = 'foot',
    })

    local foot_entered = true
    function foot_point:nearby()
        if (not IsPedInAnyVehicle(cache.ped, true)) then
            if self.currentDistance < 1 then
                if not foot_entered then
                    lib.registerContext({
                        id = 'property_manage_keys',
                        title = locale('manage_keys'),
                        menu = 'property_foot',
                        options = {
                            {
                                title = locale('take_keys'),
                                event = 'bnl-housing:client:takeKeysMenu',
                                arrow = true,
                            },
                            {
                                title = locale('give_keys'),
                                event = 'bnl-housing:client:giveKeysMenu',
                                arrow = true,
                            },
                        }
                    })

                    local foot_options = {
                        {
                            title = locale('exit_property'),
                            event = 'bnl-housing:client:exit',
                        },
                    }
                    if (currentPropertyPermissionLevel == "key_owner" or currentPropertyPermissionLevel == "owner") then
                        table.insert(foot_options, {
                            title = locale('invite_to_property'),
                            event = 'bnl-housing:client:invite',
                            arrow = true,
                            args = {
                                property_id = property_id,
                            },
                        })
                        table.insert(foot_options, {
                            title = locale('decorate_property'),
                            event = 'bnl-housing:client:decorate',
                            arrow = true,
                            args = {
                                property_id = property_id,
                            },
                        })
                    end
                    if (currentPropertyPermissionLevel == "owner") then
                        table.insert(foot_options, {
                            title = locale('manage_keys'),
                            menu = 'property_manage_keys',
                            arrow = true,
                        })
                        table.insert(foot_options, {
                            title = locale('sell_property'),
                            event = 'bnl-housing:client:sell',
                            args = {
                                property_id = property_id,
                                type = 'sell',
                            },
                        })
                        -- TODO: MAKE THIS WORK WITH DIFFERENT LOCK STATES, MAYBE EVEN RERMOVE IT
                        table.insert(foot_options, {
                            title = locale('unlock_property'),
                            event = 'bnl-housing:client:propertyOption',
                            args = {
                                property_id = property_id,
                                type = 'unlock',
                            },
                        })
                    end
                    lib.registerContext({
                        id = 'property_foot',
                        title = locale('property_menu'),
                        options = foot_options
                    })
                    lib.showContext('property_foot')
                    foot_entered = true
                end
            else
                if foot_entered then
                    foot_entered = false
                end
            end
        end
    end

    table.insert(inPropertyPoints, foot_point)
end

RegisterNetEvent("bnl-housing:client:enter", function(menuData)
    local data = lib.callback.await('bnl-housing:server:enter', false, menuData.property_id)
    
    if (data.ret == true) then
        lib.hideTextUI()

        DoScreenFadeOut(500)
        Wait(500)

        local property = data.property
        propertyPlayerIsIn = property
        currentPropertyPermissionLevel = data.permissionLevel
        isInProperty = true

        local shell = property.shell
        SpawnPropertyShell(property, shell)
        SpawnPropertyDecoration(property)
        HandlePropertyMenus(property)

        SetEntityCoords(cache.ped, GetEntityCoords(shellObject) - shell.foot_entrance - vector3(0,0,1.0))

        DoScreenFadeIn(500)
    else
        if (data.notification) then
            lib.defaultNotify(data.notification)
        end
    end
end)

RegisterNetEvent("bnl-housing:client:knock", function(data)
    local property_id = data.property_id
    local data = lib.callback.await('bnl-housing:server:knock', false, property_id)

    lib.defaultNotify(data.notification)
end)

RegisterNetEvent("bnl-housing:client:knocking", function()
    HelpNotification(locale('knocking_on_door'), 10000)
    local property = propertyPlayerIsIn
    local shellCoord = GetEntityCoords(shellObject)
    local property_id = property.id
    local foot_entrance = shellCoord - property.shell.foot_entrance
    Play3DSound('knocking', #(foot_entrance - GetEntityCoords(cache.ped)))
end)

RegisterNetEvent("bnl-housing:client:breakin", function(data)
    local property_id = data.property_id
    local data = lib.callback.await('bnl-housing:server:breakin', false, property_id)

    lib.defaultNotify(data.notification)
end)

function OpenPropertyEnterMenu(property_id)
    lib.registerContext({
        id = 'property_enter',
        title = locale('property_menu'),
        options = {
            {
                title = locale('enter_property'),
                event = 'bnl-housing:client:enter',
                args = {
                    property_id = property_id,
                },
            },
            {
                title = locale('knock_on_door'),
                event = 'bnl-housing:client:knock',
                args = {
                    property_id = property_id
                },
            },
            {
                title = locale('break_in'),
                event = 'bnl-housing:client:breakin',
                args = {
                    property_id = property_id,
                    type = 'lockpick',
                },
            },
        }
    })
    lib.showContext('property_enter')
end

RegisterNetEvent("bnl-housing:client:updatePropertyLocations", function(locations)
    allPropertyLocations = locations
    RegisterAllPropertyPoints()
end)

RegisterNetEvent("bnl-housing:client:takeKeys", function(data)
    TriggerServerEvent("bnl-housing:server:takeKeys", data.player_id)
end)

RegisterNetEvent("bnl-housing:client:takeKeysMenu", function()
    local data = lib.callback.await('bnl-housing:server:take_keys_menu', false)
    
    if (data.ret) then
        local options = {}
        for _,player in pairs(data.keys) do
            table.insert(options, {
                title = player.name,
                event = 'bnl-housing:client:takeKeys',
                args = {
                    player_id = player.identifier,
                },
            })
        end

        lib.registerContext({
            id = 'take_keys',
            title = locale('take_keys'),
            menu = 'property_foot',
            options = options,
        })
        lib.showContext('take_keys')
    else
        lib.defaultNotify(data.notification)
    end
end)

RegisterNetEvent("bnl-housing:client:giveKeys", function(data)
    TriggerServerEvent("bnl-housing:server:giveKeys", data.player_id)
end)

RegisterNetEvent("bnl-housing:client:giveKeysMenu", function()
    local players = lib.callback.await('bnl-player:server:getPlayersAtCoord', false, GetEntityCoords(cache.ped), 2.5, false)
    local options = {}

    for _,player in pairs(players) do
        table.insert(options, {
            title = player.name,
            event = 'bnl-housing:client:giveKeys',
            args = {
                player_id = player.id,
            },
        })
    end

    if (#options == 0) then
        lib.defaultNotify({
            title = locale('property'),
            description = locale('keys_noone_close'),
            status = 'error',
        })
    else
        lib.registerContext({
            id = 'give_keys',
            title = locale('give_keys'),
            menu = 'property_foot',
            options = options,
        })
        lib.showContext('give_keys')
    end
end)

RegisterNetEvent("bnl-housing:client:exit", function()
    local ret = lib.callback.await('bnl-housing:server:exit', false)
    if ret then
        lib.hideTextUI()
        isInProperty = false
        local ped = cache.ped
        SetEntityCoords(ped, JsonCoordToVector3(propertyPlayerIsIn.entrance) - vector3(0,0,1.0))
        propertyPlayerIsIn = nil
        currentPropertyPermissionLevel = nil
        
        if shellObject ~= nil or shellObject ~= 0 then
            DeleteEntity(shellObject)
        end
        
        if currentPropertyProps ~= nil then
            for _,prop in pairs(currentPropertyProps) do
                DeleteEntity(prop)
            end
        
            currentPropertyProps = nil
        end
    end
end)

-- TODO: MAKE THIS BETTER WITH SERVERSIDED CODE
RegisterNetEvent("bnl-housing:client:getInvite", function()
    HelpNotification(locale('invited_to_property'), 30000)

    Citizen.CreateThread(function()
        count = 0
        repeat
            Wait(1)
            count = count + 1
            if IsControlJustReleased(0, 47) then
                TriggerServerEvent('bnl-housing:server:acceptInvite')
                break
            end
        until count > 30000 or isInProperty
        HelpNotification(locale('entered_property'), 2500)
    end)
end)

RegisterNetEvent("bnl-housing:client:invitePlayer", function(data)
    TriggerServerEvent("bnl-housing:server:invitePlayer", data.player)
end)

RegisterNetEvent("bnl-housing:client:invite", function()
    local players = lib.callback.await('bnl-player:server:getPlayersAtCoord', false, JsonCoordToVector3(propertyPlayerIsIn.entrance), 2.5)
    local options = {}
    for _,player in pairs(players) do
        table.insert(options, {
            title = player.name,
            event = 'bnl-housing:client:invitePlayer',
            args = {
                player = player.id,
                property_id = propertyPlayerIsIn.id,
            }
        })
    end

    if #options == 0 then
        lib.defaultNotify({
            title = locale('property'),
            description = locale('noone_outside'),
            status = 'error',
        })
    else
        lib.registerContext({
            id = 'invite',
            title = locale('invite_to_property'),
            menu = 'property_foot',
            options = options
        })
        lib.showContext('invite')
    end
end)

RegisterNetEvent("bnl-housing:client:sell", function(data)
    local confirmString = locale('sell_confirm_string')
    local property_id = data.property_id
    local data = lib.inputDialog(locale('sell_property'), {locale('sell_price'), locale('sell_confirm', confirmString)})

    if data then
        if data[2] ~= confirmString then
            lib.defaultNotify({
                title = locale('property'),
                description = locale('sell_confirm_error', confirmString),
                status = 'error',
            })
            return
        end

        local sellAmount = tonumber(data[1])
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if isInProperty then
            -- TriggerEvent("bnl-housing:client:exitProperty")
            local property = propertyPlayerIsIn
            local entrance = JsonCoordToVector3(property.entrance)
            SetEntityCoords(cache.ped, entrance)
        end

        if allPropertyPoints ~= nil then
            for _,point in pairs(allPropertyPoints) do
                point:remove()
            end
        end

        if shellObject ~= nil or shellObject ~= 0 then
            DeleteEntity(shellObject)
        end

        if inPropertyPoints ~= nil then
            for _,point in pairs(inPropertyPoints) do
                point:remove()
            end
        end
    end
end)

-- TEMP
RegisterCommand("housing:getlocation", function(source, args, rawCommand)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local location = vector4(coords.x, coords.y, coords.z, heading)
    lib.setClipboard(json.encode(location))
end)

RegisterCommand("housing:getRelativeCoord", function(source, args, rawCommand)
    local ped = cache.ped
    local pedcoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local shellcoords = GetEntityCoords(shellObject)
    lib.setClipboard(json.encode(vector4(vector3(shellcoords - pedcoords), heading)))
end)
-- END