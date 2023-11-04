--//Roblox Services
local RunService = game:GetService("RunService")

local SteppedConnection = {}
SteppedConnection.__index = SteppedConnection
SteppedConnection._objects = {}

local count = 0

function SteppedConnection.new(func, connectionType : string)
    local self = setmetatable({}, SteppedConnection)
    if not connectionType then
        connectionType = "Heartbeat"
    end
    count += 1
    self.Id = count
    self.func = func
    self.connection = RunService[connectionType]:Connect(function(dt)
        if not self.paused then
            self.func(dt)
        end
    end)
    self.paused = false
    SteppedConnection._objects[self.Id] = self
    return self
end

function SteppedConnection:GetConnectionById(connectionId : string)
    return SteppedConnection._objects[connectionId]
end

function SteppedConnection:Pause()
    print("connection ".. self.Id .." being Paused")
    self.paused = true
end

function SteppedConnection:Resume()
    print("connection ".. self.Id .." being resumed")
    self.paused = false
end

function SteppedConnection:Cancel()
    self.connection:Disconnect()
    self:Destroy()
end

function SteppedConnection:Destroy()
    self.func = nil
    self.connection = nil
    self.paused = nil
    SteppedConnection._objects[self.Id] = nil
    self.Id = nil
end

return SteppedConnection
