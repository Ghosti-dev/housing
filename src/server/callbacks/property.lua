RegisterMiddlewareCallback("bnl-housing:server:property:exit", function(source, propertyId)
    local property = GetPropertyById(propertyId)
    return property and property:exit(source)
end)

RegisterMiddlewareCallback("bnl-housing:server:property:getLocation", function(_, propertyId)
    local property = GetPropertyById(propertyId)
    return property and property.location
end)

RegisterMiddlewareCallback("bnl-housing:server:property:getKeys",
    CheckPermission[PERMISSION.RENTER],
    function(_, propertyId)
        local property = GetPropertyById(propertyId)
        if not property then return end

        return table.map(property.keys, function(key)
            return {
                id = key.id,
                property_id = key.property_id,
                permission = key.permission,
                player = Bridge.GetPlayerNameFromIdentifier(key.player),
                serverId = Bridge.GetServerIdFromIdentifier(key.player),
            }
        end)
    end
)

RegisterMiddlewareCallback("bnl-housing:server:getOutsidePlayers",
    CheckPermission[PERMISSION.MEMBER],
    function(_, propertyId)
        local property = GetPropertyById(propertyId)
        if not property then return end

        local players = property:getOutsidePlayers()
        return table.map(
            players,
            function(player)
                return {
                    name = Bridge.GetPlayerName(player),
                    id = player
                }
            end
        )
    end
)

RegisterMiddlewareCallback("bnl-housing:server:property:invite",
    CheckPermission[PERMISSION.MEMBER],
    function(source, playerId)
        local property = GetPropertyPlayerIsIn(source)
        if not property then return end

        local accepted = lib.callback.await("bnl-housing:client:handleInvite", playerId, property:getData().address)
        if not accepted then return end

        property:enter(source)
    end
)

RegisterMiddlewareCallback("bnl-housing:server:property:giveKey",
    CheckPermission[PERMISSION.RENTER],
    function(source, playerId)
        local property = GetPropertyPlayerIsIn(source)
        if not property then return end

        property:givePlayerKey(playerId)
    end
)

RegisterMiddlewareCallback("bnl-housing:server:property:removeKey",
    CheckPermission[PERMISSION.RENTER],
    function(source, keyId)
        local property = GetPropertyPlayerIsIn(source)
        return property and property:removePlayerKey(keyId)
    end
)
