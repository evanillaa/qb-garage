local QBCore = exports['qb-core']:GetCoreObject()
local OutsideVehicles = {}

-- Events

RegisterServerEvent('qb-garages:server:UpdateOutsideVehicles', function(Vehicles)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local CitizenId = Ply.PlayerData.citizenid
    OutsideVehicles[CitizenId] = Vehicles
end)

RegisterServerEvent('qb-garage:server:PayDepotPrice', function(vehicle, garage)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cashBalance = Player.PlayerData.money["cash"]
    local bankBalance = Player.PlayerData.money["bank"]
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {vehicle.plate}, function(result)
        if result[1] then
            if cashBalance >= result[1].depotprice then
                Player.Functions.RemoveMoney("cash", result[1].depotprice, "paid-depot")
                TriggerClientEvent("qb-garages:client:takeOutDepot", src, vehicle, garage)
            elseif bankBalance >= result[1].depotprice then
                Player.Functions.RemoveMoney("bank", result[1].depotprice, "paid-depot")
                TriggerClientEvent("qb-garages:client:takeOutDepot", src, vehicle, garage)
            else
                TriggerClientEvent('QBCore:Notify', src, 'Not enough money', 'error')
            end
        end
    end)
end)

RegisterServerEvent('qb-garage:server:updateVehicleState', function(state, plate, garage)
    exports.oxmysql:execute('UPDATE player_vehicles SET state = ?, garage = ?, depotprice = ? WHERE plate = ?',{state, garage, 0, plate})
end)

RegisterServerEvent('qb-vehicletuning:server:SaveVehiclecoords', function(vehiclepos, plate)
    exports.oxmysql:execute('UPDATE player_vehicles SET coordsx = ?, coordsy = ?, coordsz = ? WHERE plate = ?',{json.encode(vehiclepos.x), json.encode(vehiclepos.y), json.encode(vehiclepos.z), plate})
end)

RegisterServerEvent('qb-vehicletuning:server:SaveVehicleheading', function(vehicleheading, plate)
    exports.oxmysql:execute('UPDATE player_vehicles SET heading = ? WHERE plate = ?',{json.encode(vehicleheading), plate})
end)

RegisterServerEvent('qb-garages:server:GetPubliceVehiclecoords')
AddEventHandler('qb-garages:server:GetPubliceVehiclecoords', function(vehicle)
    print("I have arrived")
    local source = source
    vehicle = vehicle
    local plate = vehicle.plate
    print(plate)
    local result = exports.oxmysql:executeSync('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    local carinfo = result[1]
    if carinfo then
        local PublicSpawnPointsx = json.decode(carinfo.coordsx)
        local PublicSpawnPointsy = json.decode(carinfo.coordsy)
        local PublicSpawnPointsz = json.decode(carinfo.coordsz)
        local PublicSpawnPointHeading = json.decode(carinfo.heading)
        print(PublicSpawnPointsx)
        print(PublicSpawnPointsy)
        print(PublicSpawnPointsz)
        print(PublicSpawnPointHeading)
        print(vehicle)
            TriggerClientEvent('qb-garages:client:takeOutPublicGarage123', source , vehicle, PublicSpawnPointsx, PublicSpawnPointsy, PublicSpawnPointsz, PublicSpawnPointHeading)
    end
end)

RegisterServerEvent('qb-garage:server:updateVehicleStatus', function(fuel, engine, body, plate, garage)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)

    if engine > 1000 then
        engine = engine / 1000
    end

    if body > 1000 then
        body = body / 1000
    end

    exports.oxmysql:execute('UPDATE player_vehicles SET fuel = ?, engine = ?, body = ? WHERE plate = ? AND citizenid = ? AND garage = ?',{fuel, engine, body, plate, pData.PlayerData.citizenid, garage})
end)

-- Callbacks

QBCore.Functions.CreateCallback("qb-garage:server:checkVehicleOwner", function(source, cb, plate)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ? AND citizenid = ?',{plate, pData.PlayerData.citizenid}, function(result)
        if result[1] then
            cb(true)
        else
            cb(false)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetOutsideVehicles", function(source, cb)
    local Ply = QBCore.Functions.GetPlayer(source)
    local CitizenId = Ply.PlayerData.citizenid
    if OutsideVehicles[CitizenId] and next(OutsideVehicles[CitizenId]) then
        cb(OutsideVehicles[CitizenId])
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetUserVehicles", function(source, cb, garage)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE citizenid = ? AND garage = ?', {pData.PlayerData.citizenid, garage}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetPDVehicles", function(source, cb, garage)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE job = "police" AND garage = ?', {garage}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetVehicleProperties", function(source, cb, plate)
    local src = source
    local properties = {}
    local result = exports.oxmysql:executeSync('SELECT mods FROM player_vehicles WHERE plate = ?', {plate})
    if result[1] then
        properties = json.decode(result[1].mods)
    end
    cb(properties)
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetDepotVehicles", function(source, cb)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE citizenid = ? AND state = ?',{pData.PlayerData.citizenid, 0}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-garage:server:GetHouseVehicles", function(source, cb, house)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE garage = ?', {house}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

QBCore.Functions.CreateCallback("qb-garage:server:checkVehicleHouseOwner", function(source, cb, plate, house)
    local src = source
    local pData = QBCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = ?', {plate}, function(result)
        if result[1] then
            local hasHouseKey = exports['qb-houses']:hasKey(result[1].license, result[1].citizenid, house)
            if hasHouseKey then
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)
end)