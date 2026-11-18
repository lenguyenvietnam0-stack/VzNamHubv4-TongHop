-- ========================================================
-- LOADER 1: SURVIVAL SYSTEM (Chống AFK, Rejoin, Auto Reload)
-- ========================================================

-- 1. CHỐNG CHẠY TRÙNG (Tránh nhân đôi)
if _G.VzNam_Loader1 then return end
_G.VzNam_Loader1 = true

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ⚠️ ĐIỀN LINK RAW CỦA LOADER 2 HOẶC CLIENT.LUA VÀO ĐÂY
local NEXT_LOADER_URL = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubv4-TongHop/refs/heads/main/vznamhub.lua"

-- Hàm tải Loader tiếp theo
local function LoadNextStage()
    pcall(function()
        loadstring(game:HttpGet(NEXT_LOADER_URL))()
    end)
end

-- 2. CHỐNG AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    print("[Loader 1] Đã chống AFK!")
end)

-- 3. TỰ ĐỘNG REJOIN KHI BỊ VĂNG MẠNG / SERVER SẬP
local function AutoRejoin()
    task.wait(2)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end
game:BindToClose(function()
    AutoRejoin()
end)

-- 4. TỰ ĐỘNG CHẠY LẠI KHI CHẾT (HỒI SINH)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3) -- Đợi game load xong nhân vật
    print("[Loader 1] Phát hiện hồi sinh, đang tự động tải lại script...")
    LoadNextStage() -- Gọi lại Loader 2 -> Client (Client tự lấy key đã lưu)
end)

-- 5. CHẠY LẦN ĐẦU TIÊN KHI MỚI VÀO GAME
task.spawn(function()
    task.wait(1)
    LoadNextStage()
end)
