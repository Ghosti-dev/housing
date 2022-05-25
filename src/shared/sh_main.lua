lib.locale()
resource = GetCurrentResourceName()

function math.round(number, decimals)
    decimals = decimals or 1
    local multiplier = 10 ^ decimals
    return math.floor(number * multiplier + 0.5) / multiplier
end

function GetShellById(shell_id)
    for _,shell in pairs(shells) do
        if shell.id == shell_id then
            return shell
        end
    end
    return nil
end

Logger = {}
Logger.Enabled = true

Logger.Log = function(...)
    if not Logger.Enabled then return end
    local args = {...}
    print(string.format("^7[^4INFO^7] %s^7", FormatLoggingString(args)))
end

Logger.Info = Logger.Log

Logger.Warn = function(...)
    if not Logger.Enabled then return end
    local args = {...}
    print(string.format("^7[^3WARN^7] %s^7", FormatLoggingString(args)))
end

Logger.Error = function(...)
    if not Logger.Enabled then return end
    local args = {...}
    print(string.format("^7[^1ERROR^7] %s^7", FormatLoggingString(args)))
end

Logger.Succes = function(...)
    if not Logger.Enabled then return end
    local args = {...}
    print(string.format("^7[^2SUCCES^7] %s^7", FormatLoggingString(args)))
end

function FormatLoggingString(...)
    local args = {...}
    local msg = ""
    for _,arg in pairs(args) do
        if (type(arg) == 'table') then
            msg = msg .. json.encode(arg, {indent = true})
        else
            msg = msg .. tostring(arg)
        end
    end
    return msg
end

function V4ToV3(vector4)
    return vector3(vector4.x, vector4.y, vector4.z)
end

function JsonCoordToVector3(coord)
    local coord = json.decode(coord)
    return vector3(coord.x, coord.y, coord.z)
end

-- Taken from @Overextended's ox_inventory!
-- I take no credit for this code. (Changed little a bit)
-- https://github.com/overextended/ox_inventory
function data(name)
	local file = ('data/%s.lua'):format(name)
	local datafile = LoadResourceFile(resource, file)
	local func, err = load(datafile, ('@%s/%s'):format(resource, file))

	if err then
		Logger.Error(err)
	end

	return func()
end