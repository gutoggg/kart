--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')
local CLASSES_FOLDER = ReplicatedStorage:WaitForChild("src"):WaitForChild('classes')

--//Placeholders
local MapService

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

export type List<T> = {T}



local TeleportService = Knit.CreateService {
	Name = "TeleportService",
	Client = {
	}
}

function TeleportService:KnitInit()
    self.CurrentMatch = nil
end

function TeleportService:KnitStart()
    MapService = Knit.GetService("MapService")
end

function TeleportService:TeleportPlayerListToLooby(playerList : List<Player>)
    local lobbySpawnList = MapService:GetLobbySpawnsList()
    self:DistributeRandomlyPlayerListThroughSpawnList(playerList, lobbySpawnList)
end

function TeleportService:TeleportPlayerListToMatch(playerList : {Player})
    local currentMapSpawnList = MapService:GetCurrentMapSpawnsList()
    self:DistributeRandomlyPlayerListThroughSpawnList(playerList, currentMapSpawnList)
end

function TeleportService:DistributeRandomlyPlayerListThroughSpawnList(playerList : {Player}, spawnList : {BasePart})
    for _, player in playerList do
        local spawnBasePart = self:GetRandomSpawnFromList(spawnList)
        local playerCharacter = player.Character or player.CharacterAdded:Wait()
        playerCharacter:PivotTo(spawnBasePart.CFrame)
    end
end

function TeleportService:GetRandomSpawnFromList(spanwList : List<BasePart>)
    local choosenSpawn
    if #spanwList > 1 then
        choosenSpawn = spanwList[math.random(1, #spanwList)]
    else
        choosenSpawn = spanwList[1]
    end
    return choosenSpawn
end

return TeleportService
