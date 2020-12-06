---------------------------
-- Made by Cadburry#6969 --
---------------------------
--==================================================================================
--                                ESX   
--==================================================================================
ESX                = nil

PlayersHarvesting  = {}
PlayersHarvesting2 = {}
PlayersCrafting    = {}
PlayersCrafting2   = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'mecano', _U('mechanic_customer'), true, true)
TriggerEvent('esx_society:registerSociety', 'mecano', 'Mecano', 'society_mecano', 'society_mecano', 'society_mecano', {type = 'public'})
--==================================================================================
--                              Harvest   
--==================================================================================

local function Harvest(source)

  SetTimeout(4000, function()

    if PlayersHarvesting[source] == true then

      local xPlayer  = ESX.GetPlayerFromId(source)
      local FixToolQuantity  = xPlayer.getInventoryItem('fixtool').count
      if FixToolQuantity >= 5 then
        TriggerClientEvent('esx:showNotification', source, _U('you_do_not_room'))
      else
                xPlayer.addInventoryItem('fixtool', 1)

        Harvest(source)
      end
    end
  end)
end

RegisterServerEvent('mechanicjob:startHarvest')
AddEventHandler('mechanicjob:startHarvest', function()
  local _source = source
  PlayersHarvesting[_source] = true
  TriggerClientEvent('esx:showNotification', _source, _U('recovery_repair_tools'))
  Harvest(_source)
end)

RegisterServerEvent('mechanicjob:stopHarvest')
AddEventHandler('mechanicjob:stopHarvest', function()
  local _source = source
  PlayersHarvesting[_source] = false
end)

local function Harvest2(source)

  SetTimeout(4000, function()

    if PlayersHarvesting2[source] == true then

      local xPlayer  = ESX.GetPlayerFromId(source)
      local BodyToolQuantity  = xPlayer.getInventoryItem('bodytool').count
            if BodyToolQuantity >= 5 then
        TriggerClientEvent('esx:showNotification', source, _U('you_do_not_room'))
      else
                xPlayer.addInventoryItem('bodytool', 1)

        Harvest2(source)
      end
    end
  end)
end

RegisterServerEvent('mechanicjob:startHarvest2')
AddEventHandler('mechanicjob:startHarvest2', function()
  local _source = source
  PlayersHarvesting2[_source] = true
  TriggerClientEvent('esx:showNotification', _source, _U('recovery_body_tools'))
  Harvest2(_source)
end)

RegisterServerEvent('mechanicjob:stopHarvest2')
AddEventHandler('mechanicjob:stopHarvest2', function()
  local _source = source
  PlayersHarvesting2[_source] = false
end)
--==================================================================================
--                              CRAFT   
--==================================================================================
local function Craft(source)

  SetTimeout(4000, function()

    if PlayersCrafting[source] == true then

      local xPlayer  = ESX.GetPlayerFromId(source)
      local FixToolQuantity  = xPlayer.getInventoryItem('repairtool').count
      if FixToolQuantity <= 0 then
        TriggerClientEvent('esx:showNotification', source,'Not Enough Repair Tools')
      else
                xPlayer.removeInventoryItem('repairtool', 1)
                xPlayer.addInventoryItem('repairkit', 1)

        Craft(source)
      end
    end
  end)
end

RegisterServerEvent('mechanicjob:startCraft')
AddEventHandler('mechanicjob:startCraft', function()
  local _source = source
  PlayersCrafting[_source] = true
  TriggerClientEvent('esx:showNotification', _source, 'Crafting Repair Kit')
  Craft(_source)
end)

RegisterServerEvent('mechanicjob:stopCraft')
AddEventHandler('mechanicjob:stopCraft', function()
  local _source = source
  PlayersCrafting[_source] = false
end)

local function Craft2(source)
  SetTimeout(4000, function()
    if PlayersCrafting2[source] == true then
      local xPlayer  = ESX.GetPlayerFromId(source)
      local BodyToolQuantity  = xPlayer.getInventoryItem('bodytool').count
            if BodyToolQuantity <= 0 then
        TriggerClientEvent('esx:showNotification', source, 'Not Enough Body Tools')
      else
          xPlayer.removeInventoryItem('bodytool', 1)
          xPlayer.addInventoryItem('bodykit', 1)
        Craft3(source)
      end
    end
  end)
end

RegisterServerEvent('mechanicjob:startCraft2')
AddEventHandler('mechanicjob:startCraft2', function()
  local _source = source
  PlayersCrafting2[_source] = true
  TriggerClientEvent('esx:showNotification', _source, 'Crafting Body Kit')
  Craft3(_source)
end)

RegisterServerEvent('mechanicjob:stopCraft2')
AddEventHandler('mechanicjob:stopCraft2', function()
  local _source = source
  PlayersCrafting2[_source] = false
end)
--==================================================================================
--                              USABLE ITEM   
--==================================================================================
ESX.RegisterUsableItem('lockpick', function(source)
  local _source = source
  local xPlayer  = ESX.GetPlayerFromId(source)
  xPlayer.removeInventoryItem('lockpick', 1)
  TriggerClientEvent('mechanicjob:lockpick', _source)
  TriggerClientEvent('esx:showNotification', _source, 'You unlocked the vehicle')
end)

ESX.RegisterUsableItem('repairkit', function(source)
  local _source = source
  local xPlayer  = ESX.GetPlayerFromId(source)
  xPlayer.removeInventoryItem('repairkit', 1)
  TriggerClientEvent('mechanicjob:repairkit', _source)
  TriggerClientEvent('esx:showNotification', _source, 'Used Repair Kit')
end)

ESX.RegisterUsableItem('bodykit', function(source)
  local _source = source
  local xPlayer  = ESX.GetPlayerFromId(source)
  xPlayer.removeInventoryItem('bodykit', 1)
  TriggerClientEvent('mechanicjob:bodykit', _source)
  TriggerClientEvent('esx:showNotification', _source, 'Used Body Kit')
end)

RegisterServerEvent('mechanicjob:removerepairkit')
AddEventHandler('mechanicjob:removerepairkit',function()
  local _source = source
  local xPlayer  = ESX.GetPlayerFromId(source)
  xPlayer.removeInventoryItem('repairkit', 1)
end)

--==================================================================================
--                              STOCK   
--==================================================================================
RegisterServerEvent('mechanicjob:getStockItem')
AddEventHandler('mechanicjob:getStockItem', function(itemName, count)
  local xPlayer = ESX.GetPlayerFromId(source)
  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mecano', function(inventory)
    local item = inventory.getItem(itemName)
    if item.count >= count then
      inventory.removeItem(itemName, count)
      xPlayer.addInventoryItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_quantity'))
    end
    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_removed') .. count .. ' ' .. item.label)
  end)
end)

ESX.RegisterServerCallback('mechanicjob:getStockItems', function(source, cb)
  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mecano', function(inventory)
    cb(inventory.items)
  end)
end)

RegisterServerEvent('mechanicjob:putStockItems')
AddEventHandler('mechanicjob:putStockItems', function(itemName, count)
  local xPlayer = ESX.GetPlayerFromId(source)
  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mecano', function(inventory)
    local item = inventory.getItem(itemName)
    if item.count >= 0 then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, 'Invalid Quantity')
    end
    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_added') .. count .. ' ' .. item.label)
  end)
end)

ESX.RegisterServerCallback('mechanicjob:getPlayerInventory', function(source, cb)
  local xPlayer    = ESX.GetPlayerFromId(source)
  local items      = xPlayer.inventory
  cb({
    items      = items
  })
end)
--==================================================================================
--                                TOW   
--==================================================================================
RegisterServerEvent("chatMessage")          ---/tow
AddEventHandler('chatMessage', function(source, n, message)
	if message == "/tow" then
		CancelEvent()
		RconPrint("tow")
		TriggerClientEvent("tow", source)
	end
end)
--==================================================================================
--                                COMMANDS   
--==================================================================================
RegisterCommand('bill', function(source, args, raw)     --/bill [amount]
  local src = source
  local myPed = GetPlayerPed(src)
  local myPos = GetEntityCoords(myPed)
local players = ESX.GetPlayers()
  for k, v in ipairs(players) do
      if v ~= src then
          local xTarget = GetPlayerPed(v)
          local xPlayer = ESX.GetPlayerFromId(v)
          local tPos = GetEntityCoords(xTarget)
          local dist = #(vector3(tPos.x, tPos.y, tPos.z) - myPos)
          local xSource = ESX.GetPlayerFromId(source)
      
          if dist < 1 and xSource.job.name == 'mecano' then
              if tonumber(args[1]) ~= nil then
                  TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'inform', text = 'You have fined ID - [' .. v .. '] for $' .. tonumber(args[1]) .. '.' })
                  TriggerClientEvent('mythic_notify:client:SendAlert', v, { type = 'inform', text = 'You have been sent a Fine for $' .. tonumber(args[1]) .. '.'})
        xPlayer.removeMoney(tonumber(args[1]))
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mecano', function(account)
          account.addMoney(tonumber(args[1]))
        end)
              end
          end
      end
  end
end)
--==================================================================================
--                               BOSS COMMANDS   
--==================================================================================
RegisterCommand('setmechanic',function(source,args)  --/setmechanic [id] [grade]
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == 'mecano' and xPlayer.job.grade_name == 'boss' then
	if tonumber(args[1]) and 'mecano' and tonumber(args[2]) then
		local xPlayer = ESX.GetPlayerFromId(args[1])        
		if xPlayer then
			if ESX.DoesJobExist('mecano', args[2]) then
				xPlayer.setJob('mecano', args[2])
			else
				TriggerClientEvent('esx:showNotification', source, 'That grade doesnot exist')
			end
		else
      TriggerClientEvent('esx:showNotification', source, 'Player not online.')
		end
	end
else
	TriggerClientEvent('esx:showNotification', source, 'You are not Authorised to give Job')
end
end)

RegisterCommand('removemechanic',function(source,args)   --/removemechanic [id]
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == 'mecano' and xPlayer.job.grade_name == 'boss' then
	if tonumber(args[1]) and 'unemployed' and '0' then
		local xPlayer = ESX.GetPlayerFromId(args[1])        
		if xPlayer then
			if ESX.DoesJobExist('unemployed', '0') then
				xPlayer.setJob('unemployed', '0')
			else        
        TriggerClientEvent('esx:showNotification', source, 'That grade doesnot exist')
			end
		else      
      TriggerClientEvent('esx:showNotification', source, 'Player not online.')
		end
	end
else
	TriggerClientEvent('esx:showNotification', source, 'You are not Authorised to give Job')
end
end)
--==================================================================================
--                                END   
--==================================================================================
---------------------------
-- Made by Cadburry#6969 --
---------------------------
