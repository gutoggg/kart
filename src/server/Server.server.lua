local GetService = function(serviceName)
    return game:GetService(serviceName)
end

--//Roblox Services
local ReplicatedStorage = GetService("ReplicatedStorage")
local ServerScriptService = GetService("ServerScriptService")

--//Constants
local SRC_FOLDER = ServerScriptService:WaitForChild("src")
local SERVICES_FOLDER = SRC_FOLDER:WaitForChild("services")
local CLASSES_FOLDER = SRC_FOLDER:WaitForChild("classes")
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Knit Services Setup
Knit.AddServices(SERVICES_FOLDER)

Knit.Start():andThen(function()
    warn("Server started")
end):catch(warn)