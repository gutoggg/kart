--//Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.packages.knit)
local packages = ReplicatedStorage.packages

--//Constants
local SRC_FOLDER = ServerScriptService:WaitForChild("src")
local SERVICES_FOLDER = SRC_FOLDER:WaitForChild("services")

--//Classes


--//Knit Setup
Knit.AddServices(SERVICES_FOLDER)

Knit.Start():andThen(function()
    warn("Server started")
end):catch(warn)

--//Game Server
