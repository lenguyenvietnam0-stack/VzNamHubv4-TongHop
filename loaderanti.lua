-- ========================================================
-- LOADER ANTI (BẢN FIX LỖI MOBILE - VÒNG LẶP SINH TỒN)
-- ========================================================
if _G.VzNam_AntiLoaded then return end
_G.VzNam_AntiLoaded = true

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ⚠️ BẮT BUỘC: DÁN LINK RAW CỦA FILE LOADER 1 (HOẶC CLIENT) VÀO ĐÂY
local NEXT_LOADER_URL = "https://raw.githubusercontent.com/lenguyenvietnam0-stack/VzNamHubv4-TongHop/refs/heads/main/vznamhub.lua"

-- HÀM TẢI SCRIPT
local function LoadNext()
    print("[LoaderAnti] Đang tải file tiếp theo...")
    local success, err = pcall(function()
        local code = game:HttpGet(NEXT_LOADER_URL)
        -- Dùng loadstring hoặc load để tương thích mọi Executor Mobile
        local func = loadstring or load
        func(code)()
    end)

    if not success then
        warn("[LoaderAnti] LỖI TẢI SCRIPT: " .. tostring(err))
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Lỗi Loader",
            Text = "Không thể tải Loader 1, check Console (F9)!",
            Duration = 10
        })
    else
        print("[LoaderAnti] Tải file tiếp theo THÀNH CÔNG!")
    end
end

-- 1. CHỐNG AFK (Giả lập click chuột)
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 2. TỰ ĐỘNG REJOIN KHI BỊ VĂNG MẠNG / SERVER SẬP
pcall(function()
    game:BindToClose(function()
        task.wait(2)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

-- 3. VÒNG LẶP SINH TỒN (Watchdog - Chạy ngầm 24/7)
task.spawn(function()
    task.wait(1)
    LoadNext() -- Chạy Loader 1 lần đầu tiên khi mới vào game
    
    while task.wait(1) do
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        
        -- Nếu không có nhân vật HOẶC máu <= 0 (đã chết)
        if not Character or not Humanoid or Humanoid.Health <= 0 then
            print("[LoaderAnti] Phát hiện nhân vật đã chết, đang đợi hồi sinh...")
            
            -- Đợi đến khi nhân vật mới được spawn
            local newCharacter = LocalPlayer.CharacterAdded:Wait()
            newCharacter:WaitForChild("HumanoidRootPart")
            
            -- Đợi 3 giây cho game ổn định (để tránh bị lag do load quá sớm)
            task.wait(3)
            
            print("[LoaderAnti] Đã hồi sinh, tự động tải lại Loader 1...")
            LoadNext()
        end
    end
end)
