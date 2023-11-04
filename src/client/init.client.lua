--//Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Constants
local SRC_FOLDER = ReplicatedStorage:WaitForChild("src")
local CONTROLLER_FOLDER = SRC_FOLDER:WaitForChild("controllers")
local CLASSES_FOLDER = SRC_FOLDER:WaitForChild("classes")
local PACKAGE_FOLDER = SRC_FOLDER:WaitForChild('packages')

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Knit Services Setup
Knit.AddControllers(CONTROLLER_FOLDER)

Knit.Start():andThen(function()
    warn("Client started")
end):catch(warn)