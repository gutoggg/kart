--//Roblox Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--//Constants
local PACKAGE_FOLDER = ReplicatedStorage:WaitForChild('src'):WaitForChild('packages')
local CLASSES_FOLDER = ReplicatedStorage:WaitForChild("src"):WaitForChild('classes')

--//Knit
local Knit = require(PACKAGE_FOLDER:WaitForChild("knit"))

--//Modules
local SteppedConnection = require(CLASSES_FOLDER:WaitForChild('SteppedConnection'))

local SchedulerService = Knit.CreateService {
	Name = "SchedulerService",
	Client = {
	}
}

function SchedulerService:KnitInit()
end

function SchedulerService:KnitStart()
    self.TaggedConnections = {}
    self.Connections = {}
end

function SchedulerService:ConnectToHeartbeat(func, tag : string)
    local connectionInstance = SteppedConnection.new(func, "Heartbeat")
    if tag then
        self.TaggedConnections[tag][connectionInstance.Id] = connectionInstance
    end
    self.Connections[connectionInstance.Id] = connectionInstance
    return connectionInstance
end

function SchedulerService:ConnectToStepped(func, tag : string)
    local connectionInstance = SteppedConnection.new(func, "Stepped")
    if tag then
        self.TaggedConnections[tag][connectionInstance.Id] = connectionInstance
    end
    self.Connections[connectionInstance.Id] = connectionInstance
    return connectionInstance
end

function SchedulerService:PauseTagged(tag : string)
    if self.TaggedConnections[tag] ~= nil then
        for i, connection  in self.TaggedConnections[tag] do
            connection:Pause()
        end
    end
end

function SchedulerService:ResumeTagged(tag : string)
    if self.TaggedConnections[tag] ~= nil then
        for i, connection  in self.TaggedConnections[tag] do
            connection:Resume()
        end
    end
end

function SchedulerService:CancelTagged(tag : string)
    if self.TaggedConnections[tag] ~= nil then
        for i, connection  in self.TaggedConnections[tag] do
            local connectionId = connection.Id
            connection:Cancel()
            self.TaggedConnections[tag][connectionId] = nil
            self.Connections[connectionId] = nil
        end
    end
end

function SchedulerService:DisconnectAll()
    for _, connection in self.Scheduler do
        connection:Disconnect()
    end
    self.Connections = {}
end

return SchedulerService
