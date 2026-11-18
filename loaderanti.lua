-- CHỐNG LOAD TRÙNG
if _G.VzNam_Loader1 then return end
_G.VzNam_Loader1 = true

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- LINK RAW CỦA LOADER 2 (Điền vào đây)
local LOADER2_URL = "https://gist.githubusercontent.com/.../loader2.lua"

-- 1. CODE ANTI-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 2. CODE AUTO REJOIN (Khi bị đá)
local function Rejoin()
    task.wait(2)
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end
game:BindToClose(function() Rejoin() end)

-- 3. CODE AUTO RELOAD KHI CHẾT (Gọi lại Loader 2)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    pcall(function() loadstring(game:HttpGet(LOADER2_URL))() end)
end)

-- 4. CHẠY LOADER 2 LẦN ĐẦU
task.spawn(function()
    task.wait(1)
    pcall(function() loadstring(game:HttpGet(LOADER2_URL))() end)
end)
