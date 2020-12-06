--==================================================================================
--                               Local   
--==================================================================================
local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
local currentTask = {}
local PlayerData              = {}
local GUI                     = {}
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local OnJob                   = false
local TargetCoords            = nil
local Blips                   = {}
local CurrentlyTowedVehicle   = nil

GUI.Time                      = 0

local allowedTowModels = { 
  ['flatbed'] = {x = 0.0, y = -0.85, z = 1.25}, -- default GTA V flatbed
  ['civtow'] = {x = 0.0, y = 0.0, z = 0.58}, -- addon flatbed2 (provided with the script)
  ['civtow2'] = {x = 0.0, y = -1.2, z = 1.30}, -- addon flatbed3 (also provided with the script)
}

local allowTowingBoats = true -- Set to true if you want to be able to tow boats.
local allowTowingPlanes = true -- Set to true if you want to be able to tow planes.
local allowTowingHelicopters = true -- Set to true if you want to be able to tow helicopters.
local allowTowingTrains = true -- Set to true if you want to be able to tow trains.
local allowTowingTrailers = true -- Disables trailers. NOTE: THIS ALSO DISABLES THE AIRTUG, TOWTRUCK, SADLER, AND ANY OTHER VEHICLE THAT IS IN THE UTILITY CLASS.
--==================================================================================
--                              ESX   
--==================================================================================
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

--==================================================================================
--                              STOCK   
--==================================================================================
function OpenGetStocksMenu()

  ESX.TriggerServerCallback('mechanicjob:getStockItems', function(items)

    print(json.encode(items))

    local elements = {}

    for i=1, #items, 1 do
      table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = _U('mechanic_stock'),
        align    = 'right',
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('invalid_quantity'))
            else
              menu2.close()
              menu.close()
              OpenGetStocksMenu()

              TriggerServerEvent('mechanicjob:getStockItem', itemName, count)
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end)

end

function OpenPutStocksMenu()

 ESX.TriggerServerCallback('mechanicjob:getPlayerInventory', function(inventory)

    local elements = {}

    for i=1, #inventory.items, 1 do

      local item = inventory.items[i]

      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end

    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = _U('inventory'),
        align    = 'right',
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('invalid_quantity'))
            else
              menu2.close()
              menu.close()
              OpenPutStocksMenu()

              TriggerServerEvent('mechanicjob:putStockItems', itemName, count)
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end)

end
--==================================================================================
--                              ITEMS FUNCTION
--==================================================================================
RegisterNetEvent('mechanicjob:bodykit')
AddEventHandler('mechanicjob:bodykit', function()
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)

  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then

    local vehicle = nil

    if IsPedInAnyVehicle(playerPed, false) then
      vehicle = GetVehiclePedIsIn(playerPed, false)
    else
      vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if DoesEntityExist(vehicle) then
      TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_HAMMERING", 0, true)
      Citizen.CreateThread(function()
        Citizen.Wait(10000)
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        ClearPedTasksImmediately(playerPed)
        ESX.ShowNotification(_U('body_repaired'))
      end)
    end
  end
end)

RegisterNetEvent('mechanicjob:repairkit')
AddEventHandler('mechanicjob:repairkit', function()
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)

  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then

    local vehicle = nil

    if IsPedInAnyVehicle(playerPed, false) then
      vehicle = GetVehiclePedIsIn(playerPed, false)
    else
      vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end

    if DoesEntityExist(vehicle) then
      TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
      Citizen.CreateThread(function()
        Citizen.Wait(10000)        
        SetVehicleEngineHealth(vehicle,-1000)              
        SetVehicleUndriveable(vehicle, false)
        ClearPedTasksImmediately(playerPed)
        ESX.ShowNotification(_U('veh_repaired'))
      end)
    end
  end
end)

RegisterNetEvent('mechanicjob:lockpick')
AddEventHandler('mechanicjob:lockpick', function()
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)
  local vehicle = ESX.Game.GetVehicleInDirection()

  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
    TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
    Citizen.Wait(20000)
    ClearPedTasksImmediately(playerPed)
    local plate = GetVehicleNumberPlateText(vehicle)									
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)							
    -- TriggerServerEvent('garage:addKeys', plate)                   --ADD YOUR KEY SYSTEM
    -- TriggerEvent('notification', 'You unlocked the vehicle.',1)	
  end
end)

function setEntityHeadingFromEntity ( vehicle, playerPed )
    local heading = GetEntityHeading(vehicle)
    SetEntityHeading( playerPed, heading )
end

function deleteCar( entity )
    Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized( entity ) )
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

AddEventHandler('mechanicjob:hasEnteredMarker', function(zone)

  if zone == 'MecanoActions' then
    CurrentAction     = 'mecano_actions_menu'
    CurrentActionMsg  = _U('open_actions')
    CurrentActionData = {}
  end

  if zone == 'Garage' then
    CurrentAction     = 'mecano_harvest_menu'
    CurrentActionMsg  = _U('harvest_menu')
    CurrentActionData = {}
  end

  if zone == 'Craft' then
    CurrentAction     = 'mecano_craft_menu'
    CurrentActionMsg  = _U('craft_menu')
    CurrentActionData = {}
  end

  if zone == 'VehicleDeleter' then

    local playerPed = GetPlayerPed(-1)

    if IsPedInAnyVehicle(playerPed,  false) then

      local vehicle = GetVehiclePedIsIn(playerPed,  false)

      CurrentAction     = 'delete_vehicle'
      CurrentActionMsg  = _U('veh_stored')
      CurrentActionData = {vehicle = vehicle}
    end
  end

end)

AddEventHandler('mechanicjob:hasExitedMarker', function(zone)

  if zone == 'Craft' then
    TriggerServerEvent('mechanicjob:stopCraft')
    TriggerServerEvent('mechanicjob:stopCraft2')    
  end

  if zone == 'Garage' then
    TriggerServerEvent('mechanicjob:stopHarvest')
    TriggerServerEvent('mechanicjob:stopHarvest2')    
  end

  CurrentAction = nil
  ESX.UI.Menu.CloseAll()
end)

AddEventHandler('mechanicjob:hasEnteredEntityZone', function(entity)

  local playerPed = GetPlayerPed(-1)

  if PlayerData.job ~= nil and PlayerData.job.name == 'mecano' and not IsPedInAnyVehicle(playerPed, false) then
    CurrentAction     = 'remove_entity'
    CurrentActionMsg  = _U('press_remove_obj')
    CurrentActionData = {entity = entity}
  end

end)

AddEventHandler('mechanicjob:hasExitedEntityZone', function(entity)

  if CurrentAction == 'remove_entity' then
    CurrentAction = nil
  end

end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
  local specialContact = {
    name       = _U('mechanic'),
    number     = 'mecano',
    base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAA4BJREFUWIXtll9oU3cUx7/nJA02aSSlFouWMnXVB0ejU3wcRteHjv1puoc9rA978cUi2IqgRYWIZkMwrahUGfgkFMEZUdg6C+u21z1o3fbgqigVi7NzUtNcmsac40Npltz7S3rvUHzxQODec87vfD+/e0/O/QFv7Q0beV3QeXqmgV74/7H7fZJvuLwv8q/Xeux1gUrNBpN/nmtavdaqDqBK8VT2RDyV2VHmF1lvLERSBtCVynzYmcp+A9WqT9kcVKX4gHUehF0CEVY+1jYTTIwvt7YSIQnCTvsSUYz6gX5uDt7MP7KOKuQAgxmqQ+neUA+I1B1AiXi5X6ZAvKrabirmVYFwAMRT2RMg7F9SyKspvk73hfrtbkMPyIhA5FVqi0iBiEZMMQdAui/8E4GPv0oAJkpc6Q3+6goAAGpWBxNQmTLFmgL3jSJNgQdGv4pMts2EKm7ICJB/aG0xNdz74VEk13UYCx1/twPR8JjDT8wttyLZtkoAxSb8ZDCz0gdfKxWkFURf2v9qTYH7SK7rQIDn0P3nA0ehixvfwZwE0X9vBE/mW8piohhl1WH18UQBhYnre8N/L8b8xQvlx4ACbB4NnzaeRYDnKm0EALCMLXy84hwuTCXL/ExoB1E7qcK/8NCLIq5HcTT0i6u8TYbXUM1cAyyveVq8Xls7XhYrvY/4n3gC8C+dsmAzL1YUiyfWxvHzsy/w/dNd+KjhW2yvv/RfXr7x9QDcmo1he2RBiCCI1Q8jVj9szPNixVfgz+UiIGyDSrcoRu2J16d3I6e1VYvNSQjXpnucAcEPUOkGYZs/l4uUhowt/3kqu1UIv9n90fAY9jT3YBlbRvFTD4fw++wHjhiTRL/bG75t0jI2ITcHb5om4Xgmhv57xpGOg3d/NIqryOR7z+r+MC6qBJB/ZB2t9Om1D5lFm843G/3E3HI7Yh1xDRAfzLQr5EClBf/HBHK462TG2J0OABXeyWDPZ8VqxmBWYscpyghwtTd4EKpDTjCZdCNmzFM9k+4LHXIFACJN94Z6FiFEpKDQw9HndWsEuhnADVMhAUaYJBp9XrcGQKJ4qFE9k+6r2+MG3k5N8VQ22TVglbX2ZwOzX2VvNKr91zmY6S7N6zqZicVT2WNLyVSehESaBhxnOALfMeYX+K/S2yv7wmMAlvwyuR7FxQUyf0fgc/jztfkJr7XeGgC8BJJgWNV8ImT+AAAAAElFTkSuQmCC'
  }
  TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

--==================================================================================
--                              BLIP   
--==================================================================================
Citizen.CreateThread(function()
  local blip = AddBlipForCoord(Config.Zones.MecanoActions.Pos.x, Config.Zones.MecanoActions.Pos.y, Config.Zones.MecanoActions.Pos.z)
  SetBlipSprite (blip, 72)
  SetBlipDisplay(blip, 4)
  SetBlipScale  (blip, 0.7)
  SetBlipColour (blip, 4)
  SetBlipAsShortRange(blip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(_U('mechanic'))
  EndTextCommandSetBlipName(blip)
end)
--==================================================================================
--                              MARKERS   
--==================================================================================
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if PlayerData.job ~= nil and PlayerData.job.name == 'mecano' then

      local coords = GetEntityCoords(GetPlayerPed(-1))

      for k,v in pairs(Config.Zones) do
        if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
          DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
        end
      end
    end
  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  while true do
    Wait(0)
    if PlayerData.job ~= nil and PlayerData.job.name == 'mecano' then
      local coords      = GetEntityCoords(GetPlayerPed(-1))
      local isInMarker  = false
      local currentZone = nil
      for k,v in pairs(Config.Zones) do
        if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
          isInMarker  = true
          currentZone = k
        end
      end
      if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
        HasAlreadyEnteredMarker = true
        LastZone                = currentZone
        TriggerEvent('mechanicjob:hasEnteredMarker', currentZone)
      end
      if not isInMarker and HasAlreadyEnteredMarker then
        HasAlreadyEnteredMarker = false
        TriggerEvent('mechanicjob:hasExitedMarker', LastZone)
      end
    end
  end
end)

-- Enter / Exit entity zone events
Citizen.CreateThread(function()
	local trackedEntities = {
    'prop_roadcone02a',
    'prop_toolchest_01',
    'prop_barrier_work06a',
	}

	while true do
		Citizen.Wait(500)

		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do
			local object = GetClosestObjectOfType(coords, 3.0, GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then
				local objCoords = GetEntityCoords(object)
				local distance  = GetDistanceBetweenCoords(coords, objCoords, true)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then
			if LastEntity ~= closestEntity then
				TriggerEvent('mechanicjob:hasEnteredEntityZone', closestEntity)
				LastEntity = closestEntity
			end
		else
			if LastEntity then
				TriggerEvent('mechanicjob:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)
--==================================================================================
--                              KEY CONTROLS   
--==================================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if CurrentAction ~= nil then

          SetTextComponentFormat('STRING')
          AddTextComponentString(CurrentActionMsg)
          DisplayHelpTextFromStringLabel(0, 0, 1, -1)

          if IsControlJustReleased(0, 38) and PlayerData.job ~= nil and PlayerData.job.name == 'mecano' then

            if CurrentAction == 'mecano_actions_menu' then
                OpenMecanoActionsMenu()
            end

            if CurrentAction == 'mecano_harvest_menu' then
                OpenMecanoHarvestMenu()
            end

            if CurrentAction == 'mecano_craft_menu' then
                OpenMecanoCraftMenu()
            end

            if CurrentAction == 'delete_vehicle' then

              if Config.EnableSocietyOwnedVehicles then

                local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
                TriggerServerEvent('esx_society:putVehicleInGarage', 'mecano', vehicleProps)

              else
                -------------------------------
              end
              ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
            end
            if CurrentAction == 'remove_entity' then
              DeleteEntity(CurrentActionData.entity)
            end
            CurrentAction = nil
          end
        end
    end
end)
--==================================================================================
--                              MENU   
--==================================================================================
function OpenMecanoActionsMenu()

  local elements = {
    {label = _U('vehicle_list'), value = 'vehicle_list'},
    {label = _U('deposit_stock'), value = 'put_stock'},
    {label = _U('withdraw_stock'), value = 'get_stock'}
  }
  if Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' then
    table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
  end

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'mecano_actions',
    {
      title    = _U('mechanic'),
      align    = 'right',
      elements = elements
    },
    function(data, menu)
      if data.current.value == 'vehicle_list' then

        if Config.EnableSocietyOwnedVehicles then

            local elements = {}

            ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)

              for i=1, #vehicles, 1 do
                table.insert(elements, {label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']', value = vehicles[i]})
              end

              ESX.UI.Menu.Open(
                'default', GetCurrentResourceName(), 'vehicle_spawner',
                {
                  title    = _U('service_vehicle'),
                  align    = 'right',
                  elements = elements,
                },
                function(data, menu)

                  menu.close()

                  local vehicleProps = data.current.value

                  ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
                    ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
                    local playerPed = GetPlayerPed(-1)

                    local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    TriggerServerEvent('garage:addKeys', plate)
                    TriggerEvent('notification', 'You received keys to the vehicle.',1)

                    TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
                  end)

                  TriggerServerEvent('esx_society:removeVehicleFromGarage', 'mecano', vehicleProps)

                end,
                function(data, menu)
                  menu.close()
                end
              )

            end, 'mecano')

          else

            local elements = {
              {label = _U('flat_bed'), value = 'flatbed'},
              {label = _U('comp_veh'), value = 'rass'},
              {label = ('Pickup'), value = 'bison'},
              {label = ('Small Trailer'), value = 'trailersmall'},
			        {label = 'Company Caddy', value = 'vwcaddy'},
              
            }
            if Config.EnablePlayerManagement and PlayerData.job ~= nil and
              (PlayerData.job.grade_name == 'boss' or PlayerData.job.grade_name == 'chef' or PlayerData.job.grade_name == 'recrue') then
              table.insert(elements, {label = 'SlamVan', value = 'slamvan3'})
              table.insert(elements, {label = 'Pickup', value = 'bison'})
              table.insert(elements, {label = 'Small Trailer', value = 'trailersmall'})
              table.insert(elements, {label = 'Hauler Lorry', value = 'hauler'})
              table.insert(elements, {label = 'Transport Trailer', value = 'tr2'})
            end

            ESX.UI.Menu.CloseAll()

            ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'spawn_vehicle',
              {
                title    = _U('service_vehicle'),
                align    = 'right',
                elements = elements
              },
              function(data, menu)
                for i=1, #elements, 1 do
                  if Config.MaxInService == -1 then
                    ESX.Game.SpawnVehicle(data.current.value, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
                      local playerPed = GetPlayerPed(-1)

                      local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
                      local plate = GetVehicleNumberPlateText(vehicle)
                      -- TriggerServerEvent('garage:addKeys', plate)          --ADD YOUR KEY SYSTEM
	                  	-- TriggerEvent('notification', 'You received keys to the vehicle.',1)
                      TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                    end)
                    break
                  else
                    break
                  end
                end
                menu.close()
              end,
              function(data, menu)
                menu.close()
                OpenMecanoActionsMenu()
              end)
          end
      end

      if data.current.value == 'put_stock' then
        OpenPutStocksMenu()
      end

      if data.current.value == 'get_stock' then
        OpenGetStocksMenu()
      end

      if data.current.value == 'boss_actions' then
        TriggerEvent('esx_society:openBossMenu', 'mecano', function(data, menu)
          menu.close()
        end)
      end

    end,
    function(data, menu)
      menu.close()
      CurrentAction     = 'mecano_actions_menu'
      CurrentActionMsg  = _U('open_actions')
      CurrentActionData = {}
    end
  )
end
--==================================================================================
--                              HARVEST   
--==================================================================================
function OpenMecanoHarvestMenu()

  if Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name ~= 'recrue' then
    local elements = {
      {label = _U('repair_tools'), value = 'repairtool'},
      {label = _U('body_work_tools'), value = 'bodytool'}
    }

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'mecano_harvest',
      {
        title    = _U('harvest'),
        align    = 'right',
        elements = elements
      },
      function(data, menu)
  
        if data.current.value == 'repairtool' then
          menu.close()
          TriggerServerEvent('mechanicjob:startHarvest')
        end

        if data.current.value == 'bodytool' then
          menu.close()
          TriggerServerEvent('mechanicjob:startHarvest2')
        end

      end,
      function(data, menu)
        menu.close()
        CurrentAction     = 'mecano_harvest_menu'
        CurrentActionMsg  = _U('harvest_menu')
        CurrentActionData = {}
      end
    )
  else
    ESX.ShowNotification('Not experienced enough')
  end
end
--==================================================================================
--                              CRAFT   
--==================================================================================
function OpenMecanoCraftMenu()
  if Config.EnablePlayerManagement and ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name ~= 'experimente' then

    local elements = {      
      {label = _U('repair_kit'), value = 'repairkit'},
      {label = _U('body_kit'), value = 'bodykit'}
    }

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'mecano_craft',
      {
        title    = _U('craft'),
        align    = 'right',
        elements = elements
      },
      function(data, menu)
        if data.current.value == 'repairkit' then
          menu.close()
          TriggerServerEvent('mechanicjob:startCraft')
        end

        if data.current.value == 'bodykit' then
          menu.close()
          TriggerServerEvent('mechanicjob:startCraft2')
        end

      end,
      function(data, menu)
        menu.close()
        CurrentAction     = 'mecano_craft_menu'
        CurrentActionMsg  = _U('craft_menu')
        CurrentActionData = {}
      end
    )
  else
    ESX.ShowNotification('Not Experienced Enough')
  end
end
--==================================================================================
--                                TOW   
--==================================================================================
function isTargetVehicleATrailer(modelHash)
  if GetVehicleClassFromName(modelHash) == 11 then
      return true
  else
      return false
  end
end

local xoff = 0.0
local yoff = 0.0
local zoff = 0.0

function isVehicleATowTruck(vehicle)
  local isValid = false
  for model,posOffset in pairs(allowedTowModels) do
      if IsVehicleModel(vehicle, model) then
          xoff = posOffset.x
          yoff = posOffset.y
          zoff = posOffset.z
          isValid = true
          break
      end
  end
  return isValid
end

RegisterNetEvent('mechanicjob:tow')
AddEventHandler('mechanicjob:tow', function()

local playerped = PlayerPedId()
local vehicle = GetVehiclePedIsIn(playerped, true)

local isVehicleTow = isVehicleATowTruck(vehicle)

if isVehicleTow then

  local coordA = GetEntityCoords(playerped, 1)
  local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
  local targetVehicle = getVehicleInDirection(coordA, coordB)
      

  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(0)
      isVehicleTow = isVehicleATowTruck(vehicle)
      local roll = GetEntityRoll(GetVehiclePedIsIn(PlayerPedId(), true))
      if IsEntityUpsidedown(GetVehiclePedIsIn(PlayerPedId(), true)) and isVehicleTow or roll > 70.0 or roll < -70.0 then
        DetachEntity(currentlyTowedVehicle, false, false)
        currentlyTowedVehicle = nil
        ESX.ShowNotification("Looks like the cables holding on the vehicle have broke!")
      end
              
    end
  end)

  if currentlyTowedVehicle == nil then
    if targetVehicle ~= 0 then
              local targetVehicleLocation = GetEntityCoords(targetVehicle, true)
              local towTruckVehicleLocation = GetEntityCoords(vehicle, true)
              local distanceBetweenVehicles = GetDistanceBetweenCoords(targetVehicleLocation, towTruckVehicleLocation, false)              
              if distanceBetweenVehicles > 12.0 then
                  ESX.ShowNotification("Your cables can't reach this far, move you truck closer to the vehicle.")
              else
                  local targetModelHash = GetEntityModel(targetVehicle)                  
                  if not ((not allowTowingBoats and IsThisModelABoat(targetModelHash)) or (not allowTowingHelicopters and IsThisModelAHeli(targetModelHash)) or (not allowTowingPlanes and IsThisModelAPlane(targetModelHash)) or (not allowTowingTrains and IsThisModelATrain(targetModelHash)) or (not allowTowingTrailers and isTargetVehicleATrailer(targetModelHash))) then 
                      if not IsPedInAnyVehicle(playerped, true) then
                          if vehicle ~= targetVehicle and IsVehicleStopped(vehicle) then
                              AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0 + xoff, -1.5 + yoff, -0.15 + zoff, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                              currentlyTowedVehicle = targetVehicle
                              ESX.ShowNotification("Vehicle has been loaded onto the flatbed.")
                          else
                              ESX.ShowNotification("There is currently no vehicle on the flatbed.")
                          end
                      else
                          ESX.ShowNotification("You need to be outside of your vehicle to load or unload vehicles.")
                      end
                  else
                      ESX.ShowNotification("Your towtruck is not equipped to tow this vehicle.")
                  end
              end
          else
              ESX.ShowNotification("No towable vehicle detected.")
    end
  elseif IsVehicleStopped(vehicle) then
          DetachEntity(currentlyTowedVehicle, false, false)
          local vehiclesCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -12.0, 0.0)
    SetEntityCoords(currentlyTowedVehicle, vehiclesCoords["x"], vehiclesCoords["y"], vehiclesCoords["z"], 1, 0, 0, 1)
    SetVehicleOnGroundProperly(currentlyTowedVehicle)
    currentlyTowedVehicle = nil
    ESX.ShowNotification("Vehicle has been unloaded from the flatbed.")
  end
else
      ESX.ShowNotification("Your vehicle is not registered as an official ~o~Tow Service Truck~s~.")
  end
end)

function getVehicleInDirection(coordFrom, coordTo)
local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
return vehicle
end
--==================================================================================
--                              COMMANDS   
--==================================================================================
---------------------------FEW COMMANDS ARE SERVER SIDE-----------------------------

RegisterCommand("tow", function()
   if ESX.PlayerData.job~= nil and PlayerData.job.name == 'mecano' then
      TriggerEvent("mechanicjob:tow")
  end
end,false)

RegisterCommand("impound", function()  
  if ESX.PlayerData.job~= nil and PlayerData.job.name == 'mecano' then    
		exports['progressBars']:startUI(1000, "Impounding Vehicle")
		Citizen.Wait(1000)
		TriggerEvent('esx:deleteVehicle', source)
 end
end,false)

RegisterCommand('repair',function()
  if ESX.PlayerData.job~= nil and PlayerData.job.name == 'mecano' then
  local playerPed = GetPlayerPed(-1)
  local coords    = GetEntityCoords(playerPed)

  if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
    local vehicle = nil
    if IsPedInAnyVehicle(playerPed, false) then
      vehicle = GetVehiclePedIsIn(playerPed, false)
    else
      vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if DoesEntityExist(vehicle) then
      TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
      Citizen.CreateThread(function()
        exports['progressBars']:startUI(15000, "Repairing Vehicle")
        Citizen.Wait(15000)
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle,  true,  true)
        SetVehicleEngineCanDegrade(vehicle, true)
        ClearPedTasksImmediately(playerPed)
        TriggerServerEvent('mechanicjob:removerepairkit')
        exports["mythic_notify"]:SendAlert('inform','Removed a Repairkit')
        exports['mythic_notify']:SendAlert('success', _U('vehicle_repaired'))        
      end)
    else
      exports["mythic_notify"]:SendAlert('inform','You dont have repairkit')
    end
  end
end
end)

RegisterCommand('clean',function()
  local playerPed = GetPlayerPed(-1)
        local coords    = GetEntityCoords(playerPed)

        if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then

          local vehicle = nil

          if IsPedInAnyVehicle(playerPed, false) then
            vehicle = GetVehiclePedIsIn(playerPed, false)
          else
            vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
          end

          if DoesEntityExist(vehicle) then
            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_MAID_CLEAN", 0, true)
            Citizen.CreateThread(function()
              exports['progressBars']:startUI(10000, "Cleaning Vehicle")
              Citizen.Wait(10000)
              SetVehicleDirtLevel(vehicle, 0)
              ClearPedTasksImmediately(playerPed)
              exports['mythic_notify']:SendAlert('success', _U('vehicle_repaired'))              
           end)
        end
    end
end)

RegisterCommand('cone', function(source, args, rawCommand)
	local plyData = ESX.GetPlayerData()

	if plyData.job ~= nil and plyData.job.name == "mecano" or plyData.job.name == "police" then
		if not barrier then
			local playerPed = PlayerPedId()
			local coords    = GetEntityCoords(playerPed)
			local forward   = GetEntityForwardVector(playerPed)
			local x, y, z   = table.unpack(coords + forward * 1.0)
		
			ESX.Game.SpawnObject('prop_roadcone02a', {x = x, y = y, z = z}, function(obj)
				SetEntityHeading(obj, GetEntityHeading(playerPed))
				PlaceObjectOnGroundProperly(obj)
			end)
		end
	end
end)
RegisterCommand('tools', function(source, args, rawCommand)
	local plyData = ESX.GetPlayerData()

	if plyData.job ~= nil and plyData.job.name == "mecano" then
		if not barrier then
			local playerPed = PlayerPedId()
			local coords    = GetEntityCoords(playerPed)
			local forward   = GetEntityForwardVector(playerPed)
			local x, y, z   = table.unpack(coords + forward * 1.0)
		
			ESX.Game.SpawnObject('prop_toolchest_01', {x = x, y = y, z = z}, function(obj)
				SetEntityHeading(obj, GetEntityHeading(playerPed))
				PlaceObjectOnGroundProperly(obj)
			end)
		end
	end
end)

---------------------------
-- Made by Cadburry#6969 --
---------------------------
